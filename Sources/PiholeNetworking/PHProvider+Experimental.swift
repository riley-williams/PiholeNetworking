//
//  PHProvider+Experimental.swift
//  PiholeNetworking
//
//  Created by Riley Williams on 4/13/21.
//
//  Experimental and undocumented queries
//

import Foundation
import Combine

extension PHProvider {
	/// Returns the passed/blocked data for the specified time period
	///
	/// Requires authentication
	/// # EXPERIMENTAL/UNDOCUMENTED
	/// - Parameter instance: The Pi-hole instance to connect to
	/// - Parameter from: Start date. This will be rounded down to the nearest multiple of the interval
	/// - Parameter until: End date. The last interval returned will always be less than this date rounded down to the nearest second
	/// - Parameter interval: The size of each reported interval, which will be rounded down to the nearest second
	/// - Returns: Ad and domain query counts in the interval [start date, end date]
	public func getRequestRatioTimeline<T: PHInstance>(_ instance: T, from: Date, until: Date, interval: TimeInterval) -> AnyPublisher<PHRequestRatioTimeline, PHProviderError> {
		let start = Int(from.timeIntervalSince1970)
		let end = Int(until.timeIntervalSince1970)
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api_db.php?getGraphData&auth=\(token)&from=\(start)&until=\(end)&interval=\(Int(interval))")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		return resultDecoderPublisher(url: url, type: PHRequestRatioTimeline.self)
	}
	
	/// Returns list of clients that have accessed this Pi-hole
	///
	/// Requires authentication
	/// # EXPERIMENTAL/UNDOCUMENTED
	/// - Parameters:
	///   - instance: The Pi-hole instance to connect to
	public func getNetwork<T: PHInstance>(_ instance: T) -> AnyPublisher<[PHNetworkClient], PHProviderError> {
		guard let token = instance.apiKey,
			  let url = URL(string: "http://\(instance.address)/admin/api_db.php?network&auth=\(token)")
		else { return Fail(error: .invalidHostname).eraseToAnyPublisher() }
		return resultDecoderPublisher(url: url, type: [String:[PHNetworkClient]].self)
			.tryMap { result in
				guard let clients = result["network"]
				else { throw PHProviderError.decodingError(nil) }
				return clients
			}.mapPiholeNetworkingError()
			.eraseToAnyPublisher()
	}
}
