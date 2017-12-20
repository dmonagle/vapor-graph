//
//  ModelStore.swift
//  VaporGraph
//
//  Created by David Monagle on 10/4/17.
//
//

import Fluent
import Foundation

extension Identifier : Hashable {
    public var hashValue: Int {
        guard let stringValue = self.string else { return 0 }
        return stringValue.hashValue
    }
}

/// Stores a single type of Graphable
public class GraphModelStore : GraphSynchronizable {
    internal var _models : [Identifier: Graphable] = [:]
    
    public init() {
    }
    
    /// Returns all the models in the store that can be cast to T and pass the given filter function
    public func filter<T>(_ filterFunc: (T) -> Bool) throws -> [T] where T: Graphable {
        var results: [T] = []
        
        _models.forEach { model in
            if let m = model.value as? T {
                if (filterFunc(m)) {
                    results.append(m)
                }
            }
        }
        
        return results
    }

    /// Returns all the models in the store that can be cast to T
    public func all<T>() throws -> [T] where T: Graphable {
        return try filter { _ in true }
    }
    
    public func add(_ model : Graphable) throws {
        guard let id = model.id else { throw GraphError.noId }
        _models[id] = model
    }
    
    public func remove(_ model : Graphable) {
        if let id = model.id {
            _models.removeValue(forKey: id)
        }
    }
    
    public func retrieve<T: Graphable>(id: Identifier) -> T? {
        print("Retrieving id: \(id)")
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
    
    public func sync(executor: Executor?, force: Bool = false) throws {
        try _models.forEach { id, model in
            try model.sync(executor: executor, force: force)
        }
    }
}

