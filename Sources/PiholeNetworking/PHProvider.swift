//
//  PHProvider.swift
//  
//
//  Created by Riley Williams on 3/14/21.
//

import Foundation
import Combine

public class PHProvider {
	internal let session: PHSession
	internal let decoder: JSONDecoder
	
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
	public func verifyPassword<T: PHInstance>(_ instance: T) async throws -> Bool {
		guard let apiKey = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?recentBlocked&auth=\(apiKey)")
		else { throw PHProviderError.invalidHostname }
		let data = try await session.simpleDataTaskPublisher(for: url)
		let response = String(data: data, encoding: .utf8)
		return response != "[]"
	}
	
	/// Returns the summary for today
	///
	/// Does not require authentication
	/// - Parameters:
	///   - instance: The Pi-hole instance to connect to
	public func getSummary<T: PHInstance>(_ instance: T) async throws -> PHSummary {
		guard let url = URL(string: "http://\(instance.address)/admin/api.php?summaryRaw")
		else { throw PHProviderError.invalidHostname }
		
		return try await resultDecoderPublisher(url: url, type: PHSummary.self)
	}
	
	/// Retrieves various datapoints by scraping the /admin/index.php dashboard.
	/// Be careful calling this too frequently as there is a high overhead for the host to render this page
	///
	///	Does not require authentication
	/// - Warning: Because this method does not use an official API, it may break partially or completely after a Pi-hole release
	/// - Parameter instance: The Pi-hole instance to connect to
	public func getHWInfo<T: PHInstance>(_ instance: T) async throws -> PHHardwareInfo {
		guard let url = URL(string: "http://\(instance.address)/admin/index.php")
		else { throw PHProviderError.invalidHostname }
		
		let data = try await session.simpleDataTaskPublisher(for: url)
		let body = String(data: data, encoding: .utf8)

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
	}
	
	/// Returns the top passed and blocked queries today, along with the counts for each
	///
	/// Requires authentication
	/// - Parameters:
	///   - instance: The Pi-hole instance to connect to
	///   - max: The maximum number of queries to request
	public func getTopQueries<T: PHInstance>(_ instance: T, max count: Int) async throws -> PHTopQueries {
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?topItems=\(count)&auth=\(token)")
		else { throw PHProviderError.invalidHostname }
		return try await resultDecoderPublisher(url: url, type: PHTopQueries.self)
	}
	
	/// Returns the top blocked clients today, along with the counts for each
	///
	/// Requires authentication
	/// - Parameters:
	///   - instance: The Pi-hole instance to connect to
	///   - max: The maximum number of clients to request
	public func getTopBlockedClients<T: PHInstance>(_ instance: T, max count: Int) async throws -> [PHClient: Int] {
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?topClientsBlocked=\(count)&auth=\(token)")
		else { throw PHProviderError.invalidHostname }
		let result = try await resultDecoderPublisher(url: url, type: [String:[String:Int]].self)
		
		guard let sourcesDict = result["top_sources_blocked"]
		else { throw PHProviderError.decodingError(nil) }
		var sources: [PHClient: Int] = [:]
		sourcesDict.forEach { (key, value) in
			guard let client = PHClient(pipedString: key)
			else { return }
			sources[client] = value
		}
		return sources
	}
	
	/// Returns the top clients today, along with the counts for each
	///
	/// Requires authentication
	/// - Parameters:
	///   - instance: The Pi-hole instance to connect to
	///   - max: The maximum number of clients to request
	public func getTopClients<T: PHInstance>(_ instance: T, max count: Int) async throws -> [PHClient: Int] {
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?getQuerySources=\(count)&auth=\(token)")
		else { throw PHProviderError.invalidHostname }
		let result = try await resultDecoderPublisher(url: url, type: [String:[String:Int]].self)
			
		guard let sourcesDict = result["top_sources"]
		else { throw PHProviderError.decodingError(nil) }
		var sources: [PHClient: Int] = [:]
		sourcesDict.forEach { (key, value) in
			guard let client = PHClient(pipedString: key)
			else { return }
			sources[client] = value
		}
		return sources
	}
	
	/// Returns the breakdown of query types today, with the respective percentages adding up to (approximately) 100
	///
	/// Requires authentication
	/// - Parameters:
	///   - instance: The Pi-hole instance to connect to
	public func getQueryTypes<T: PHInstance>(_ instance: T) async throws -> [String: Float] {
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?getQueryTypes&auth=\(token)")
		else { throw PHProviderError.invalidHostname }
		let result = try await resultDecoderPublisher(url: url, type: [String:[String:Float]].self)
		
		guard let types = result["querytypes"]
		else { throw PHProviderError.decodingError(nil) }
		return types
	}
	
	/// Returns the passed/blocked data for today, split into 10 minute intervals
	///
	/// Does not require authentication
	/// - Parameter instance: The Pi-hole instance to connect to
	public func getRequestRatioTimeline<T: PHInstance>(_ instance: T) async throws -> PHRequestRatioTimeline {
		guard let url = URL(string: "http://\(instance.address)/admin/api.php?overTimeData10mins")
		else { throw PHProviderError.invalidHostname }
		return try await resultDecoderPublisher(url: url, type: PHRequestRatioTimeline.self)
	}
	
	/// Returns the request count, by client, for today
	///
	/// Requires authentication for full client data
	/// - Parameter instance: The Pi-hole instance to connect to
	public func getClientTimeline<T: PHInstance>(_ instance: T) async throws -> PHClientTimeline {
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?overTimeDataClients&getClientNames&auth=\(token)")
		else { throw PHProviderError.invalidHostname }
		return try await resultDecoderPublisher(url: url, type: PHClientTimeline.self)
	}
	
	/// Returns the breakdown of forward destinations for today
	///
	/// Requires authentication
	/// - Parameter instance: The Pi-hole instance to connect to
	public func getForwardDestinations<T: PHInstance>(_ instance: T) async throws -> [PHForwardDestination: Float] {
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?getForwardDestinations&auth=\(token)")
		else { throw PHProviderError.invalidHostname }
		
		let response = try await resultDecoderPublisher(url: url, type: [String: [String: Float]].self)
		
		guard let forwardDestinations = response["forward_destinations"]
		else { throw PHProviderError.decodingError(nil) }
		var result: [PHForwardDestination: Float] = [:]
		forwardDestinations
			.compactMap {
				guard let destination = PHForwardDestination(rawValue: $0) else { return nil }
				return (destination, $1)
			}.forEach { result[$0] = $1 }
		return result

	}
	
	/// Enables a Pi-hole
	///
	/// Requires authentication
	/// - Parameter instance: The Pi-hole instance to enable
	/// - Returns: The state as reported by Pi-hole after this operation
	public func enable<T: PHInstance>(_ instance: T) async throws -> PHState {
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?enable&auth=\(token)")
		else { throw PHProviderError.invalidHostname }
		
		let response = try await resultDecoderPublisher(url: url, type: [String:PHState].self)
			
		guard let state = response["status"] else { throw PHProviderError.decodingError(nil) }
		return state
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
	public func disable<T: PHInstance>(_ instance: T, for duration: Int? = nil) async throws -> PHState {
		var arg = "disable"
		if let duration = duration {
			arg += "=\(duration)"
		}
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?\(arg)&auth=\(token)")
		else { throw PHProviderError.invalidHostname }
		
		let response = try await resultDecoderPublisher(url: url, type: [String:PHState].self)
			
		guard let state = response["status"] else { throw PHProviderError.decodingError(nil) }
		return state
	}
	
	/// Provides convenient handling of errors due to networking, decoding, and authentication
	internal func resultDecoderPublisher<T: Decodable>(url: URL, type:T.Type) async throws -> T {
		do {
			let data = try await session.simpleDataTaskPublisher(for: url)
			// Pihole returns "[]" when authentication is required
			if let obj = try? decoder.decode([Int].self, from: data),
			   obj.isEmpty {
				throw PHProviderError.authenticationRequired
			}
			return try decoder.decode(T.self, from: data)
		} catch let error as URLError {
			throw PHProviderError.urlError(error)
		} catch let error as DecodingError {
			throw PHProviderError.decodingError(error)
		} catch let error as PHProviderError {
			throw error
		} catch {
			throw PHProviderError.other(error)
		}
	}
}
