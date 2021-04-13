//
//  PHHardwareInfo.swift
//  
//
//  Created by Riley Williams on 3/14/21.
//

import Foundation

public struct PHHardwareInfo {
	/// The CPU temperature in Celcius
	public var cpuTemp: Float?
	/// CPU load for the past 1 minute
	public var load1Min: Float?
	/// CPU load for the past 5 minutes
	public var load5Min: Float?
	/// CPU load for the past 15 minutes
	public var load15Min: Float?
	/// Current memory usage
	public var memoryUsage: Float?
}
