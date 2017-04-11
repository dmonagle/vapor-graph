//
//  ModelStore.swift
//  VaporGraph
//
//  Created by David Monagle on 10/4/17.
//
//

import Fluent
import Foundation

/// Stores a single type of Graphable
public class GraphModelStore : GraphSynchronizable {
    private var _models : [String: Graphable] = [:]
    
    public init() {
        
    }
    
    public func add(_ model : Graphable) throws {
        guard let id = model.id?.string else { throw GraphError.noId }
        _models[id] = model
    }
    
    public func retrieve<T: Graphable>(id: Node) throws -> T? {
        guard let id = id.string else { throw GraphError.noId }
        return retrieve(id: id)
    }
    
    public func retrieve<T: Graphable>(id: String) -> T? {
        guard let graphable = _models[id] else { return nil }
        guard let model = (graphable as? T) else { return nil }
        return model
    }
    
    public var count : Int {
        return _models.count
    }
    
    public func needsSync() throws -> Bool {
        var result = false
        try _models.forEach { id, model in
            if (try model.needsSync()) {
                result = true
                return
            }
        }
        return result
    }
    
    public func sync(force: Bool) throws {
        try _models.forEach { id, model in
            try model.sync(force: force)
        }
    }
}

