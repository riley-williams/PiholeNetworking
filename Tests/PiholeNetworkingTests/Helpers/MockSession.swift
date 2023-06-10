//
//  MockSession.swift
//  
//
//  Created by Riley Williams on 4/7/21.
//

import Foundation
import PiholeNetworking
import Combine

/// Always publishes the provided object, encoded with a JSON Encoder.
struct MockSession<T: StringProtocol & Sendable>: PHNetworkingProvider {
	var result: T
    func dataTask(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard let data = result.data(using: .utf8) else {
            throw PHHandleError.invalidHostname
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Set-Cookie": "PHPSESSID=asdf1234"])!
        return (data, response)
    }
}
