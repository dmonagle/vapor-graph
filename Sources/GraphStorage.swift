//
//  GraphStorage.swift
//  VaporGraph
//
//  Created by David Monagle on 30/5/17.
//
//

import Node

/// Represents a convenience around graph snapshot data
public struct GraphSnapshot: StructuredDataWrapper {
    public var wrapped: StructuredData
    public let context: Context
    
    public init(_ wrapped: StructuredData, in context: Context? = nil) {
        self.wrapped = wrapped
        self.context = context ?? GraphContext.snapshot
    }
}

public struct GraphStorage {
    public var graph: Graph?
    public var snapshot: GraphSnapshot?
    public var context: Context {
        get {
            return _context ?? (graph?.context ?? emptyContext)
        }
        set {
            _context = newValue
        }
    }
    private var _context : Context?
    
    public init() {}
}
