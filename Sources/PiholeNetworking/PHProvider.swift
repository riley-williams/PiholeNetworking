//
//  PHProvider.swift
//  
//
//  Created by Riley Williams on 3/14/21.
//

import Foundation
import Combine

public class PHProvider {
	private let session: PHSession
	private let decoder: JSONDecoder
	
	/// Initialize the provider
	///
	/// The session parameter allows you to pass a custom `PHSession` which can be used to inject mock data or failures
	/// in order to unit test more effectively.
	/// # Example
	/// ~~~
	/// /// Always publishes the provided object, encoded with a JSON Encoder.
	///	struct MockSession<T: StringProtocol>: PHSession {
	///	    var result: T
	///	    func simpleDataTaskPublisher(for: URL) -> AnyPublisher<Data, URLError> {
	///	        Just(result)
	///	            .compactMap { $0.data(using: .utf8) }
	///	            .setFailureType(to: URLError.self)
	///	            .eraseToAnyPublisher()
	///	 	}
	/// }
	/// ~~~
	/// - Parameter session: Allows injection of a mock session, defaults to `URLSession.shared` if omitted
	public init(session: PHSession = URLSession.shared) {
		self.session = session
		self.decoder = JSONDecoder()
		self.decoder.dateDecodingStrategy = .secondsSince1970
	}
	
	/// Verifies a password by attempting to access an endpoint that requires authentication
	///
	/// Does not require authentication
	/// - Parameters:
	///   - instance: The Pi-hole instance to connect to
	public func verifyPassword<T: PHInstance>(_ instance: T) -> AnyPublisher<Bool, PHProviderError> {
		guard let apiKey = instance.apiKey,
			let url = URL(string: "http://\(instance.address)/admin/api.php?recentBlocked&auth=\(apiKey)")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		return session.simpleDataTaskPublisher(for: url)
			.mapPiholeNetworkingError()
			.map { String(data: $0, encoding: .utf8) }
			.map { $0 != "[]" }
			.eraseToAnyPublisher()
	}
	
	/// Returns the summary for the past 24 hours
	///
	/// Does not require authentication
	/// - Parameters:
	///   - instance: The Pi-hole instance to connect to
	public func getSummary<T: PHInstance>(_ instance: T) -> AnyPublisher<PHSummary, PHProviderError> {
		guard let url = URL(string: "http://\(instance.address)/admin/api.php?summaryRaw")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		
		return resultDecoderPublisher(url: url, type: PHSummary.self)
	}
	
	/// Retrieves various datapoints by scraping the /admin/index.php dashboard.
	/// Be careful calling this too frequently as there is a high overhead for the host to render this page
	///
	///	Does not require authentication
	/// - Warning: Because this method does not use an official API, it may break partially or completely after a Pi-hole release
	/// - Parameter instance: The Pi-hole instance to connect to
	public func getHWInfo<T: PHInstance>(_ instance: T) -> AnyPublisher<PHHardwareInfo, PHProviderError> {
		guard let url = URL(string: "http://\(instance.address)/admin/index.php")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		
		return session.simpleDataTaskPublisher(for: url)
			.map { String(data: $0, encoding: .utf8) }
			.tryMap { body in
				guard let body = body,
					  let tempRegex = try? NSRegularExpression(pattern: #"<span id="rawtemp" hidden>([\d]*[\.]?[\d]*)<\/span>"#, options: .caseInsensitive),
					  let tempLegacyRegex = try? NSRegularExpression(pattern: "Temp:&nbsp;([\\d.]+)&nbsp;&deg;([F|C])", options: .caseInsensitive),
					  let loadRegex = try? NSRegularExpression(pattern: #"Load:(?:&nbsp;)+([\d.]+)(?:&nbsp;)+([\d.]+)(?:&nbsp;)+([\d.]+)"#, options: .caseInsensitive),
					  let memoryRegex = try? NSRegularExpression(pattern: #"Memory usage:(?:&nbsp;)+([\d.]+)&thinsp;%"#, options: .caseInsensitive)
				else { throw PHProviderError.decodingError(nil) }
				
				var cpuTemp: Float? = nil
				var load1Min: Float? = nil
				var load5Min: Float? = nil
				var load15Min: Float? = nil
				var memoryUsage: Float? = nil
				
				if let tempMatch = tempRegex.firstMatch(in: body, options: [], range: NSRange(location: 0, length: body.count)),
				   let tempRange = Range(tempMatch.range(at: 1), in: body) {
					cpuTemp = Float(body[tempRange])
				} else if let tempMatch = tempLegacyRegex.firstMatch(in: body, options: [], range: NSRange(location: 0, length: body.count)),
						  let tempRange = Range(tempMatch.range(at: 1), in: body) {
					cpuTemp = Float(body[tempRange])
				}
				
				if let loadMatches = loadRegex.firstMatch(in: body, options: [], range: NSRange(location: 0, length: body.count)),
				   let loadRange1 = Range(loadMatches.range(at: 1), in: body),
				   let loadRange2 = Range(loadMatches.range(at: 2), in: body),
				   let loadRange3 = Range(loadMatches.range(at: 3), in: body) {
					load1Min = Float(body[loadRange1])
					load5Min = Float(body[loadRange2])
					load15Min = Float(body[loadRange3])
				}
				if let memoryMatch = memoryRegex.firstMatch(in: body, options: [], range: NSRange(location: 0, length: body.count)),
				   let memRange = Range(memoryMatch.range(at: 1), in: body) {
					memoryUsage = Float(body[memRange])
				}
				return PHHardwareInfo(cpuTemp: cpuTemp,
									  load1Min: load1Min,
									  load5Min: load5Min,
									  load15Min: load15Min,
									  memoryUsage: memoryUsage)
			}.mapPiholeNetworkingError()
			.eraseToAnyPublisher()
	}
	
	/// Returns the top passed and blocked queries over the past 24 hours, along with the counts for each
	///
	/// Requires authentication
	/// - Parameters:
	///   - instance: The Pi-hole instance to connect to
	///   - max: The maximum number of queries to request
	public func getTopQueries<T: PHInstance>(_ instance: T, max count: Int) -> AnyPublisher<PHTopQueries, PHProviderError> {
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?topItems=\(count)&auth=\(token)")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		return resultDecoderPublisher(url: url, type: PHTopQueries.self)
	}
	
	/// Returns the top blocked clients over the past 24 hours, along with the counts for each
	///
	/// Requires authentication
	/// - Parameters:
	///   - instance: The Pi-hole instance to connect to
	///   - max: The maximum number of clients to request
	public func getTopBlockedClients<T: PHInstance>(_ instance: T, max count: Int) -> AnyPublisher<[PHClient: Int], PHProviderError> {
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?topClientsBlocked=\(count)&auth=\(token)")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		return resultDecoderPublisher(url: url, type: [String:[String:Int]].self)
			.tryMap { result in
				guard let sourcesDict = result["top_sources_blocked"]
				else { throw PHProviderError.decodingError(nil) }
				var sources: [PHClient: Int] = [:]
				sourcesDict.forEach { (key, value) in
					guard let client = PHClient(pipedString: key)
					else { return }
					sources[client] = value
				}
				return sources
			}.mapPiholeNetworkingError()
			.eraseToAnyPublisher()
	}
	
	/// Returns the top clients over the past 24 hours, along with the counts for each
	///
	/// Requires authentication
	/// - Parameters:
	///   - instance: The Pi-hole instance to connect to
	///   - max: The maximum number of clients to request
	public func getTopClients<T: PHInstance>(_ instance: T, max count: Int) -> AnyPublisher<[PHClient: Int], PHProviderError> {
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?getQuerySources=\(count)&auth=\(token)")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		return resultDecoderPublisher(url: url, type: [String:[String:Int]].self)
			.tryMap { result in
				guard let sourcesDict = result["top_sources"]
				else { throw PHProviderError.decodingError(nil) }
				var sources: [PHClient: Int] = [:]
				sourcesDict.forEach { (key, value) in
					guard let client = PHClient(pipedString: key)
					else { return }
					sources[client] = value
				}
				return sources
			}.mapPiholeNetworkingError()
			.eraseToAnyPublisher()
	}
	
	/// Returns the breakdown of query types over the past 24 hours, with the respective percentages adding up to 100
	///
	/// Requires authentication
	/// - Parameters:
	///   - instance: The Pi-hole instance to connect to
	public func getQueryTypes<T: PHInstance>(_ instance: T) -> AnyPublisher<[String: Float], PHProviderError> {
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?getQueryTypes&auth=\(token)")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		return resultDecoderPublisher(url: url, type: [String:[String:Float]].self)
			.tryMap { result in
				guard let types = result["querytypes"]
				else { throw PHProviderError.decodingError(nil) }
				return types
			}.mapPiholeNetworkingError()
			.eraseToAnyPublisher()
	}
	
	/// Returns the passed/blocked data for the past 24 hours, split into 10 minute intervals
	///
	/// Does not require authentication
	/// - Parameter instance: The Pi-hole instance to connect to
	public func getRequestRatioTimeline<T: PHInstance>(_ instance: T) -> AnyPublisher<PHRequestRatioTimeline, PHProviderError> {
		guard let url = URL(string: "http://\(instance.address)/admin/api.php?overTimeData10mins")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		return resultDecoderPublisher(url: url, type: PHRequestRatioTimeline.self)
	}
	
	/// Returns the request count, by client, for the past 24 hours
	///
	/// Requires authentication for full client data
	/// - Parameter instance: The Pi-hole instance to connect to
	public func getClientTimeline<T: PHInstance>(_ instance: T) -> AnyPublisher<PHClientTimeline, PHProviderError> {
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?overTimeDataClients&getClientNames&auth=\(token)")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		return resultDecoderPublisher(url: url, type: PHClientTimeline.self)
	}
	
	/// Returns the breakdown of forward destinations over the past 24 hours
	///
	/// Requires authentication
	/// - Parameter instance: The Pi-hole instance to connect to
	public func getForwardDestinations<T: PHInstance>(_ instance: T) -> AnyPublisher<[PHForwardDestination: Float], PHProviderError> {
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?getForwardDestinations&auth=\(token)")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		
		return resultDecoderPublisher(url: url, type: [String: [String: Float]].self)
			.tryMap {
				guard let forwardDestinations = $0["forward_destinations"]
				else { throw PHProviderError.decodingError(nil) }
				var result: [PHForwardDestination: Float] = [:]
				forwardDestinations
					.compactMap {
						guard let destination = PHForwardDestination(rawValue: $0) else { return nil }
						return (destination, $1)
					}.forEach { result[$0] = $1 }
				return result
			}.mapPiholeNetworkingError()
			.eraseToAnyPublisher()
	}
	
	/// Enables a Pi-hole
	///
	/// Requires authentication
	/// - Parameter instance: The Pi-hole instance to enable
	/// - Returns: The state as reported by Pi-hole after this operation
	public func enable<T: PHInstance>(_ instance: T) -> AnyPublisher<PHState, PHProviderError> {
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?enable&auth=\(token)")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		
		return resultDecoderPublisher(url: url, type: [String:PHState].self)
			.tryMap {
				guard let state = $0["status"] else { throw PHProviderError.decodingError(nil) }
				return state
			}
			.mapPiholeNetworkingError()
			.eraseToAnyPublisher()
	}
	
	/// Disables a Pi-hole
	///
	/// Requires authentication
	/// - Bug: Every time `disable` is called, a background timer is created that will re-enable Pi-hole after the specified duration.
	/// As of Pi-hole **v5.2.4** these timers are not invalidated after the Pi-hole has been enabled.
	/// This behavior can be reproduced by disabling for 30 seconds, enabling, and then disabling for 1 minute.
	/// The Pi-hole will be re-enabled after 30 seconds, and again at 1 minute.
	/// - Parameter instance: The Pi-hole instance to disable
	/// - Parameter duration: The duration to disable the Pi-hole. Omitting this parameter will disable indefinitely
	/// - Returns: The state as reported by Pi-hole after this operation
	public func disable<T: PHInstance>(_ instance: T, _ duration: Int? = nil) -> AnyPublisher<PHState, PHProviderError> {
		var arg = "disable"
		if let duration = duration {
			arg += "=\(duration)"
		}
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?\(arg)&auth=\(token)")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		
		return resultDecoderPublisher(url: url, type: [String:PHState].self)
			.tryMap {
				guard let state = $0["status"] else { throw PHProviderError.decodingError(nil) }
				return state
			}
			.mapPiholeNetworkingError()
			.eraseToAnyPublisher()
	}
	
	/// Provides convenient handling of errors due to networking, decoding, and authentication
	private func resultDecoderPublisher<T: Decodable>(url: URL, type:T.Type) -> AnyPublisher<T, PHProviderError> {
		session.simpleDataTaskPublisher(for: url)
			.tryMap { [decoder] result in
				// Pihole returns "[]" when authentication is required
				if let obj = try? decoder.decode([Int].self, from: result),
				   obj.isEmpty {
					throw PHProviderError.authenticationRequired
				}
				return try decoder.decode(T.self, from: result)
			}
			.mapPiholeNetworkingError()
			.eraseToAnyPublisher()
	}
}
