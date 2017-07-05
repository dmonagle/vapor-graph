//
//  GraphContext.swift
//  VaporGraph
//
//  Created by David Monagle on 11/4/17.
//
//

import Vapor

public enum GraphContext: Context {
    case snapshot // For a snapshot
    case storage  // For storage
}

extension Context {
    /// Tests the context to see if it is a GraphContext. If they optional type parameter is set, it also has to match the GraphContext enum type
    public func isGraph(type contextType: GraphContext? = nil) -> Bool {
        if let graphContext = self as? GraphContext {
            // If no contextType is set, return true
            if (contextType == nil) { return true }
            
            return graphContext == contextType
        }
        return false
    }
}
