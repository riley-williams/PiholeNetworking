//
//  PHProvider.swift
//  
//
//  Created by Riley Williams on 3/14/21.
//

import Foundation
import Combine
import RegexBuilder
import OSLog

let logger = Logger(subsystem: "com.riley-williams.pihole-networking", category: "Network")

/// Provides a handle that manages the session for a single Pi-hole
public final actor PHHandle: Sendable {
    internal let instance: any PHInstance
	internal let provider: PHNetworkingProvider
	internal let decoder: JSONDecoder
    internal var session: SessionState

    private let sessionIdRegex = Regex {
        "PHPSESSID="
        Capture {
            OneOrMore {
                CharacterClass(.word)
            }
        }
    }

	/// Initialize the provider
	///
	/// The provider parameter allows you to pass a custom `PHNetworkingProvider`
    /// which can be used to inject mock data or failures in order to unit test more effectively.
	/// # Example
	/// ``` swift
	/// /// Always publishes the provided object, encoded with a JSON Encoder.
	///	struct MockSession<T: StringProtocol & Sendable>: PHNetworkingProvider {
	///	    var result: T
	///	    func simpleDataTaskPublisher(for: URL) -> AnyPublisher<Data, URLError> {
	///	        Just(result)
	///	            .compactMap { $0.data(using: .utf8) }
	///	            .setFailureType(to: URLError.self)
	///	            .eraseToAnyPublisher()
	///	 	}
	/// }
	/// ```
	/// - Parameter provider: Allows injection of a mock provider, defaults to `URLSession.shared` if omitted
    public init(instance: any PHInstance, provider: PHNetworkingProvider = URLSession.shared) {
        self.instance = instance
		self.provider = provider
		self.decoder = JSONDecoder()
		self.decoder.dateDecodingStrategy = .secondsSince1970
        self.session = .unauthenticated
	}
	
	/// Verifies a password by attempting to access an endpoint that requires authentication
	///
	/// Does not require authentication
	/// - Parameters:
	///   - instance: The Pi-hole instance to connect to
	public func authenticate() async throws {
        session = .unauthenticated
        logger.debug("Attempting session authentication")
        guard let url = URL(string: "http://\(instance.address)/admin/login.php")
        else { throw PHHandleError.invalidHostname }
        var request = URLRequest(url: url)
        request.httpBody = "pw=\(instance.password)".data(using: .utf8)
        request.httpMethod = "POST"
        let (_, response) = try await provider.dataTask(for: request)
        if let cookie = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Set-Cookie"),
              let matches = try? sessionIdRegex.firstMatch(in: cookie) {
            self.session = .session(String(matches.output.1))
            logger.debug("Session authentication success")
        }

        logger.debug("Attempting apiKey authentication")
        guard let apiKey = instance.apiKey,
              let url = URL(string: "http://\(instance.address)/admin/api.php?recentBlocked&auth=\(apiKey)")
        else { throw PHHandleError.invalidHostname }
        let data = try await provider.simpleDataTaskPublisher(for: url)
        let apiResponse = String(data: data, encoding: .utf8)
        if apiResponse != "[]" {
            logger.debug("API key authentication success")
            switch session {
            case .session(let sessionId):
                session = .both(session: sessionId, apiKey: apiKey)
            default:
                session = .api(apiKey)
            }
            return
        }

	}
	
	/// Returns the summary for today
	///
	/// Does not require authentication
	public func getSummary() async throws -> PHSummary {
		guard let url = URL(string: "http://\(instance.address)/admin/api.php?summaryRaw")
		else { throw PHHandleError.invalidHostname }
		
		return try await resultDecoderPublisher(url: url, type: PHSummary.self)
	}
	
	/// Retrieves various datapoints by scraping the /admin/index.php dashboard.
	/// Be careful calling this too frequently as there is a high overhead for the host to render this page
	///
	///	Does not require authentication
	/// - Warning: Because this method does not use an official API, it may break partially or completely after a Pi-hole release
	/// - Parameter instance: The Pi-hole instance to connect to
	public func getHWInfo() async throws -> PHHardwareInfo {
		guard let url = URL(string: "http://\(instance.address)/admin/index.php")
		else { throw PHHandleError.invalidHostname }

        var request = URLRequest(url: url)

        switch session {
        case .both(let sessionId, _), .session(let sessionId):
            request.setValue(sessionId, forHTTPHeaderField: "PHPSESSID")
        default:
            break
        }
       
		let (data, _) = try await provider.dataTask(for: request)
        guard let body = String(data: data, encoding: .utf8) else {
            throw PHHandleError.decodingError(nil)
        }

        let coreCountRegex = #/Detected (?<coreCount>\d+) core/#
        let tempRegex = #/Temp:.*?(?<temp>\d+\.?\d*)/#
        let memoryRegex = #/Memory usage:.*?(?<memory>[\d.]+)/#
        let loadRegex = #/Load:(?:&nbsp;)+(?<one>[\d.]+)(?:&nbsp;)+(?<five>[\d.]+)(?:&nbsp;)+(?<fifteen>[\d.]+)/#

        let load = try? loadRegex.firstMatch(in: body)?.output
        let load1Min: Float? = (load?.one).flatMap(Float.init)
		let load5Min: Float? = (load?.five).flatMap(Float.init)
		let load15Min: Float? = (load?.fifteen).flatMap(Float.init)

        let coreCount: Int? = (try? coreCountRegex.firstMatch(in: body)?.output.coreCount).flatMap { Int(String($0)) }
        let cpuTemp: Float? = (try? tempRegex.firstMatch(in: body)?.output.temp).flatMap(Float.init)
		let memoryUsage: Float? = (try? memoryRegex.firstMatch(in: body)?.output.memory).flatMap(Float.init)

        return PHHardwareInfo(coreCount: coreCount,
                              cpuTemp: cpuTemp,
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
	public func getTopQueries(max count: Int) async throws -> PHTopQueries {
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?topItems=\(count)&auth=\(token)")
		else { throw PHHandleError.invalidHostname }
		return try await resultDecoderPublisher(url: url, type: PHTopQueries.self)
	}
	
	/// Returns the top blocked clients today, along with the counts for each
	///
	/// Requires authentication
	/// - Parameters:
	///   - instance: The Pi-hole instance to connect to
	///   - max: The maximum number of clients to request
	public func getTopBlockedClients(max count: Int) async throws -> [PHClient: Int] {
		guard let url = URL(string: "http://\(instance.address)/admin/api.php?topClientsBlocked=\(count)")
		else { throw PHHandleError.invalidHostname }
		let result = try await resultDecoderPublisher(url: url, type: [String:[String:Int]].self)
		
		guard let sourcesDict = result["top_sources_blocked"]
		else { throw PHHandleError.decodingError(nil) }
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
	public func getTopClients(max count: Int) async throws -> [PHClient: Int] {
		guard let url = URL(string: "http://\(instance.address)/admin/api.php?getQuerySources=\(count)")
		else { throw PHHandleError.invalidHostname }
		let result = try await resultDecoderPublisher(url: url, type: [String:[String:Int]].self)
			
		guard let sourcesDict = result["top_sources"]
		else { throw PHHandleError.decodingError(nil) }
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
	public func getQueryTypes() async throws -> [String: Float] {
		guard let url = URL(string: "http://\(instance.address)/admin/api.php?getQueryTypes")
		else { throw PHHandleError.invalidHostname }
		let result = try await resultDecoderPublisher(url: url, type: [String:[String:Float]].self)
		
		guard let types = result["querytypes"]
		else { throw PHHandleError.decodingError(nil) }
		return types
	}
	
	/// Returns the passed/blocked data for today, split into 10 minute intervals
	///
	/// Does not require authentication
	/// - Parameter instance: The Pi-hole instance to connect to
	public func getRequestRatioTimeline() async throws -> PHRequestRatioTimeline {
		guard let url = URL(string: "http://\(instance.address)/admin/api.php?overTimeData10mins")
		else { throw PHHandleError.invalidHostname }
		return try await resultDecoderPublisher(url: url, type: PHRequestRatioTimeline.self)
	}
	
	/// Returns the request count, by client, for today
	///
	/// Requires authentication for full client data
	/// - Parameter instance: The Pi-hole instance to connect to
	public func getClientTimeline() async throws -> PHClientTimeline {
		guard let url = URL(string: "http://\(instance.address)/admin/api.php?overTimeDataClients&getClientNames")
		else { throw PHHandleError.invalidHostname }
		return try await resultDecoderPublisher(url: url, type: PHClientTimeline.self)
	}
	
	/// Returns the breakdown of forward destinations for today
	///
	/// Requires authentication
	/// - Parameter instance: The Pi-hole instance to connect to
	public func getForwardDestinations() async throws -> [PHForwardDestination: Float] {
		guard let url = URL(string: "http://\(instance.address)/admin/api.php?getForwardDestinations")
		else { throw PHHandleError.invalidHostname }
		
		let response = try await resultDecoderPublisher(url: url, type: [String: [String: Float]].self)
		
		guard let forwardDestinations = response["forward_destinations"]
		else { throw PHHandleError.decodingError(nil) }
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
	public func enable() async throws -> PHState {
		guard let url = URL(string: "http://\(instance.address)/admin/api.php?enable")
		else { throw PHHandleError.invalidHostname }
		
		let response = try await resultDecoderPublisher(url: url, type: [String:PHState].self)
			
		guard let state = response["status"] else { throw PHHandleError.decodingError(nil) }
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
	public func disable(for duration: Int? = nil) async throws -> PHState {
		var arg = "disable"
		if let duration = duration {
			arg += "=\(duration)"
		}
		guard let url = URL(string: "http://\(instance.address)/admin/api.php?\(arg)")
		else { throw PHHandleError.invalidHostname }
		
		let response = try await resultDecoderPublisher(url: url, type: [String:PHState].self)
			
		guard let state = response["status"] else { throw PHHandleError.decodingError(nil) }
		return state
	}
	
	/// Provides convenient handling of errors due to networking, decoding, and authentication
	internal func resultDecoderPublisher<T: Decodable>(url: URL, type:T.Type) async throws -> T {
        var request = URLRequest(url: url)
        switch session {
        case let .session(sessionId):
            request.setValue("PHPSESSID=\(sessionId)", forHTTPHeaderField: "Cookie")
        case let .api(apiKey), let .both(session: _, apiKey: apiKey):
            request.url?.append(queryItems: [URLQueryItem(name: "auth", value: apiKey)])
        case .unauthenticated:
            break
        }

		do {
			let (data, _) = try await provider.dataTask(for: request)
			// Pihole returns "[]" when authentication is required
			if let obj = try? decoder.decode([Int].self, from: data),
			   obj.isEmpty {
				throw PHHandleError.authenticationRequired
			}
			return try decoder.decode(T.self, from: data)
		} catch let error as URLError {
			throw PHHandleError.urlError(error)
		} catch let error as DecodingError {
			throw PHHandleError.decodingError(error)
		} catch let error as PHHandleError {
			throw error
		} catch {
			throw PHHandleError.other(error)
		}
	}
}
