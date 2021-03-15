//
//  URLProtocolMock.swift
//  
//
//  Created by Riley Williams on 3/14/21.
//

import Foundation
@testable import PiholeNetworking

class URLProtocolMock: URLProtocol {
	/// Maps URLs to test data
	static var testURLs = [URL?: Data]()

	// Handle all types of request
	override class func canInit(with request: URLRequest) -> Bool {
		return true
	}

	// ignore this method; just send back what we were given
	override class func canonicalRequest(for request: URLRequest) -> URLRequest {
		return request
	}

	override func startLoading() {
		// Load data immediately
		if let url = request.url,
		   let data = URLProtocolMock.testURLs[url] {
			self.client?.urlProtocol(self, didLoad: data)
		}
		// mark that we've finished
		self.client?.urlProtocolDidFinishLoading(self)
	}

	override func stopLoading() { }
}
