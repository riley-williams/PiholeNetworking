//
//  PiHoleResolver.swift
//  Singularity
//
//  Created by Riley Williams on 3/13/21.
//  Copyright © 2021 Riley Williams. All rights reserved.
//

import Foundation
import Combine

public protocol PHResolver {
	/// Verifies the password is correct
	/// - Parameter password: web interface password
	func verifyPassword(_ instance: PHInstance) -> AnyPublisher<Bool, PHResolverError>
	
	func getStatus(_ instance: PHInstance) -> AnyPublisher<PHStatus, PHResolverError>
	
	func getHWInfo(_ instance: PHInstance) -> AnyPublisher<PHHardwareInfo, PHResolverError>
		
	func getTopQueries(_ instance: PHInstance, count: Int) -> AnyPublisher<PHTopQueries, PHResolverError>
	
	//func get10MinData(_ instance: PHInstance) -> AnyPublisher<PH10MinData, ResolverError>
	
	func get10MinClientData(for instance: PHInstance) -> AnyPublisher<PH10MinClientData, PHResolverError>
	
	/// Attempt to enable this Pi-hole
	func enable(_ instance: PHInstance) -> AnyPublisher<PHState, PHResolverError>
	
	/// Disables this Pi-hole for the specified duration
	/// - Parameter duration: time in seconds, or nil to disable indefinitely
	func disable(_ instance: PHInstance, _ duration: Int?) -> AnyPublisher<PHState, PHResolverError>
	
}
