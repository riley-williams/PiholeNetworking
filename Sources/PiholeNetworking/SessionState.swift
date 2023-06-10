//
//  File.swift
//  
//
//  Created by Riley Williams on 6/10/23.
//

import Foundation

internal enum SessionState: Sendable {
    case unauthenticated
    case api(String)
    case session(String)
    case both(session: String, apiKey: String)
}
