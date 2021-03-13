//
//  PHState.swift
//  
//
//  Created by Riley Williams on 3/13/21.
//

import Foundation

public enum PHState: String, Codable {
	case enabled = "enabled"
	case disabled = "disabled"
	case mixed = "mixed"
	case unknown = "unknown"
}
