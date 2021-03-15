//
//  File.swift
//  
//
//  Created by Riley Williams on 3/14/21.
//

import Combine

extension Collection where Element: Cancellable {
	func cancelAll() {
		forEach { $0.cancel() }
	}
}
