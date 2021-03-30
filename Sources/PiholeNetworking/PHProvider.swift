//
//  PHProvider.swift
//  
//
//  Created by Riley Williams on 3/14/21.
//

import Foundation
import Combine

public class PHProvider: PHResolver {
	var session: URLSession = URLSession.shared
	
	public init() { }
	
	init(session: URLSession) {
		self.session = session
	}
	
	public func verifyPassword(_ instance: PHInstance) -> AnyPublisher<Bool, PHResolverError> {
		guard let url = URL(string: "http://\(instance.address)/admin/api.php?getQueryTypes&auth=\(instance.hashedPassword ?? "")")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		return URLSession.shared.dataTaskPublisher(for: url)
			.mapError { _ in PHResolverError.hostUnreacheable }
			.map { String(data: $0.data, encoding: .utf8) }
			.map { $0 != "[]" }
			.eraseToAnyPublisher()
	}
	
	public func getStatus(_ instance: PHInstance) -> AnyPublisher<PHStatus, PHResolverError> {
		guard let url = URL(string: "http://\(instance.address)/admin/api.php?summaryRaw")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		
		return resultDecoderPublisher(url: url, type: PHStatus.self)
	}
	
	public func getHWInfo(_ instance: PHInstance) -> AnyPublisher<PHHardwareInfo, PHResolverError> {
		guard let url = URL(string: "http://\(instance.address)/admin/index.php")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		
		return URLSession.shared.dataTaskPublisher(for: url)
			.map { String(data: $0.data, encoding: .utf8) }
			.mapError { _ in PHResolverError.hostUnreacheable }
			.tryMap { body in
				guard let body = body,
					  let tempRegex = try? NSRegularExpression(pattern: #"<span id="rawtemp" hidden>([\d]*[\.]?[\d]*)<\/span>"#, options: .caseInsensitive),
					  let tempLegacyRegex = try? NSRegularExpression(pattern: "Temp:&nbsp;([\\d.]+)&nbsp;&deg;([F|C])", options: .caseInsensitive),
					  let loadRegex = try? NSRegularExpression(pattern: #"Load:(?:&nbsp;)+([\d.]+)(?:&nbsp;)+([\d.]+)(?:&nbsp;)+([\d.]+)"#, options: .caseInsensitive),
					  let memoryRegex = try? NSRegularExpression(pattern: #"Memory usage:(?:&nbsp;)+([\d.]+)&thinsp;%"#, options: .caseInsensitive)
				else { throw PHResolverError.decodingError }
				
				var hwInfo = PHHardwareInfo()
				
				if let tempMatch = tempRegex.firstMatch(in: body, options: [], range: NSRange(location: 0, length: body.count)),
				   let tempRange = Range(tempMatch.range(at: 1), in: body) {
					hwInfo.cpuTemp = Float(body[tempRange])
				} else if let tempMatch = tempLegacyRegex.firstMatch(in: body, options: [], range: NSRange(location: 0, length: body.count)),
						  let tempRange = Range(tempMatch.range(at: 1), in: body) {
					hwInfo.cpuTemp = Float(body[tempRange])
				}
				
				if let loadMatches = loadRegex.firstMatch(in: body, options: [], range: NSRange(location: 0, length: body.count)),
				   let loadRange1 = Range(loadMatches.range(at: 1), in: body),
				   let loadRange2 = Range(loadMatches.range(at: 2), in: body),
				   let loadRange3 = Range(loadMatches.range(at: 3), in: body) {
					hwInfo.load1Min = Float(body[loadRange1])
					hwInfo.load5Min = Float(body[loadRange2])
					hwInfo.load15Min = Float(body[loadRange3])
				}
				if let memoryMatch = memoryRegex.firstMatch(in: body, options: [], range: NSRange(location: 0, length: body.count)),
				   let memRange = Range(memoryMatch.range(at: 1), in: body) {
					hwInfo.memoryUsage = Float(body[memRange])
				}
				return hwInfo
			}.mapError { error in
				switch error {
				case let error as PHResolverError:
					return error
				case let error as URLError:
					return .urlError(error: error)
				default:
					return .other(error: error)
				}
			}.eraseToAnyPublisher()
	}
	
	public func getTopQueries(_ instance: PHInstance, count: Int) -> AnyPublisher<PHTopQueries, PHResolverError> {
		guard let token = instance.hashedPassword,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?topItems=25&auth=\(token)")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		return resultDecoderPublisher(url: url, type: PHTopQueries.self)
	}
	
	public func get10MinData(_ instance: PHInstance) -> AnyPublisher<PH10MinData, PHResolverError> {
		guard let url = URL(string: "http://\(instance.address)/admin/api.php?overTimeData10mins")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		return resultDecoderPublisher(url: url, type: PH10MinData.self)
	}

	
	public func get10MinClientData(for instance: PHInstance) -> AnyPublisher<PH10MinClientData, PHResolverError> {
		guard let token = instance.hashedPassword,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?overTimeDataClients&getClientNames&auth=\(token)")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		return resultDecoderPublisher(url: url, type: PH10MinClientData.self)
	}
	
	public func enable(_ instance: PHInstance) -> AnyPublisher<PHState, PHResolverError> {
		guard let token = instance.hashedPassword,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?enable&auth=\(token)")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		
		return resultDecoderPublisher(url: url, type: PHStatusResponse.self)
			.map { $0.state }
			.eraseToAnyPublisher()
	}
	
	public func disable(_ instance: PHInstance, _ duration: Int?) -> AnyPublisher<PHState, PHResolverError> {
		var arg = "disable"
		if let duration = duration {
			arg += "=\(duration)"
		}
		guard let token = instance.hashedPassword,
			  let url = URL(string: "http://\(instance.address)/admin/api.php?\(arg)&auth=\(token)")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		
		return resultDecoderPublisher(url: url, type: PHStatusResponse.self)
			.map { $0.state }
			.eraseToAnyPublisher()
	}
	
	private func resultDecoderPublisher<T: Decodable>(url: URL, type:T.Type) -> AnyPublisher<T, PHResolverError> {
		URLSession.shared.dataTaskPublisher(for: url)
			.map { $0.data }
			.decode(type: T.self, decoder: JSONDecoder())
			.mapError { (error) -> PHResolverError in
				switch error {
				case is DecodingError:
					return .decodingError
				case let error as URLError:
					return .urlError(error: error)
				default:
					return .other(error: error)
				}
			}.eraseToAnyPublisher()
	}
}
