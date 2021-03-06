import Vapor
import FluentProvider
import Foundation

/**
    Implements callbacks for the Graph sync lifecycle
 */
public protocol GraphSyncDelegate {
    func graphWillSync(forced: Bool) throws
    func graphDidSync()
}

open class Graph : GraphSynchronizable {
    /**
     Determines how a model with an id that already exists in the Graph will be treated when an attempt is made to inject it.
     
     # rebase
     Captures the changes that have been made to the existing and merges them with the new model. The result is then applied to the existing reference and returned.
     
     # deserialize
     Deserializes the data from the new record into the existing record. This keeps references the same and overwrites any changes that have been made to the original
     
     # keepExisting
     Ignores the incoming record and return a reference to the existing one
     
     # replaceReference
     Replace the current reference with the new one. This could leave other classes with references to a model that no longer exists in the graph. Not really recommended
     */
    public enum DuplicateResolution {
        case rebase
        case deserialize
        case keepExisting
        case replaceReference
    }
    
    // Defines a priority for syncing each model type. These will be done first, in order and then any other models in the store will be done at random.
    static public var ModelSyncOrder : [String] = []
    
    public var storeNames : [String] {
        get {
            return _store.keys.array
        }
    }
    
    public init() {
    }
    
    private var _store : [String: GraphModelStore] = [:]
    public var context : Context = emptyContext
    public var syncDelegate : GraphSyncDelegate? = nil
    
    public func store<T>(forType: T.Type) -> GraphModelStore? where T : Entity {
        return _store[forType.entity]
    }

    public func store(forType name: String) -> GraphModelStore? {
        return _store[name]
    }
    
    /**
     Injects a model into the graph.
     
     If the id of the model already exists in the graph, the `duplicateResolution` is used to determine how to proceed.
     
     - Parameters:
         - model: A `Graphable` model
         - duplicateResolution: Specifies how to deal with a duplicate id being inserted
         - takeSnapshot: If set to `true`, a snapshot will be taken of the model after it is inserted into the graph. If set to `false`, the model
         is injected without a snapshot. If it's set to `nil` (default) a snapshot will be taken if model.exists is true (ie: it exists in the database).
         The snapshot is supposed to represent the model's last known state in the database so a snapshot is normally desired when inserting the result of a 
         database query.
     
     - Returns:
     A reference to the injected model. This may not be the same as the reference passed in if the id was a duplicate of a model already in the graph.
     */
    public func inject<T>(_ model : T, duplicateResolution: DuplicateResolution = .rebase, takeSnapshot: Bool? = nil) throws -> T where T : Graphable{
        let id : Identifier
        
        let takeSnapshot = takeSnapshot ?? model.exists // If takeSnapshot parameter was nil, this causes it to be set to true if the model exists in the database
        
        if let modelId = model.id {
            id = modelId
        }
        else {
            guard let generator = T.graphIdGenerator else { throw GraphError.noId }
            id = try generator(T.self)
            
            // Add the generated id to the model
            model.id = Identifier(id)
        }
        
        let store = ensureStore(model: model)
        
        // If the model, according to it's id, already exists in the store, we need to return the reference already in the graph
        if let existing : T = store.retrieve(id: id) {
            // If the model to be injected is exactly the same reference as the existing one, no more needs to be done.
            if (existing === model) { return existing }
            
            switch duplicateResolution {
            case .keepExisting:
                return existing
            case .deserialize:
                try existing.graphDeserialize(row: try model.makeRow(in: GraphContext.snapshot), in: GraphContext.snapshot)
                if (takeSnapshot) { try model.takeSnapshot() }
                return existing
            case .rebase:
                try existing.rebase(from: model, updateSnapshot: takeSnapshot)
                return existing
            case .replaceReference:
                // Fall through here as replacing is the same as adding a non-existing
                break
            }
        }
        
        try store.add(model)
        model.graph = self
        if (takeSnapshot) { try model.takeSnapshot() }
        
        return model
    }
    
    /** Injects multiple models into the graph
     - Returns: An array containing the references of the injected models. This may not be identical to the array passed in due to duplicate handling.
     */
    public func inject<T>(_ models : [T], duplicateResolution: DuplicateResolution = .rebase, takeSnapshot: Bool = false) throws -> [T] where T : Graphable {
        var results : [T] = []
        
        try models.forEach { model in
            results.append(try inject(model, duplicateResolution: duplicateResolution, takeSnapshot: takeSnapshot))
        }
        
        return results
    }
    
    /// Removes a model from the graph.
    public func remove<T : Graphable>(_ model : T) {
        _store[T.entity]?.remove(model)
        model.graph = nil
    }
    
    /// Retrieves an object from the Graph
    public func retrieve<T : Graphable>(id: Identifier) -> T? {
        let result : T? = _store[T.entity]?.retrieve(id: id)
        return result
    }
    
    /// Looks for the given id in the Graph. If it's not present it will search the database for it and, if found, add it to the Graph
    public func find<T : Graphable>(id: Identifier, duplicateResolution: DuplicateResolution = .rebase) throws -> T? {
        if let result : T = retrieve(id: id) { return result }
        guard let result = try T.find(id) else { return nil }
        return try self.inject(result, duplicateResolution: duplicateResolution, takeSnapshot: true)
    }
    
    /// Convenience: Queries the database for the model with the filter value and returns the result of injecting them into the graph with the given duplication resolution
    public func findMany<T>(field: String, value: NodeRepresentable, duplicateResolution: DuplicateResolution = .rebase) throws -> [T] where T : Graphable {
        return try inject(T.makeQuery().filter(field, value).all(), duplicateResolution: duplicateResolution, takeSnapshot: true)
    }
    
    public func clear() {
        _store = [:]
    }
    
    // MARK: GraphSynchronizable
    
    /**
     Check all stores to see if any model needs synchronization
     
     - Returns: `true` if any model in any store needs synchronization
     */
    public func needsSync() throws -> Bool {
        var result = false
        try _store.forEach { _, store in
            if (try store.needsSync()) {
                result = true
                return
            }
        }
        return result
    }
    
    /**
     Sync all models across all stores
     
     - Parameters:
        - force: If set to true, will save each model whether or not it returns true to `needsSync`. Use with care when doing this across the entire graph
     */
    public func sync(executor: Executor? = nil, force: Bool = false) throws {
        try syncDelegate?.graphWillSync(forced: force)

        var syncKeys = type(of: self).ModelSyncOrder
        for key in _store.keys { if !syncKeys.contains(key) { syncKeys.append(key) } }
        
        for modelType in syncKeys {
            if let store = _store[modelType] {
                try store.sync(executor: executor, force: force)
            }
        }
        
        syncDelegate?.graphDidSync()
    }
    
    public func forEach(_ body: (Graphable) throws -> Void) rethrows {
        try _store.forEach { _, store in
            try store._models.forEach { _, model in
                try body(model)
            }
        }
    }
    
    /// Returns all the models in the stores that can be cast to T and pass the given filter function
    public func filter<T>(_ filterFunc: (T) -> Bool) -> [T] where T: Graphable {
        var results: [T] = []
        
        forEach { model in
            if let m = model as? T {
                if (filterFunc(m)) {
                    results.append(m)
                }
            }
        }
        
        return results
    }
    
    // MARK: Private
    
    /// Returns the store for the named `entityName` if it exists or creates it if it doesn't
    private func ensureStore(entityName: String) -> GraphModelStore {
        guard let store = _store[entityName] else {
            let newStore = GraphModelStore()
            _store[entityName] = newStore
            return newStore
        }
        
        return store
    }
    
    /// Returns the store for the given `Graphable` type if it exists or creates it if it doesn't
    private func ensureStore<T : Graphable>(forType : T.Type) -> GraphModelStore {
        return ensureStore(entityName: forType.entity)
    }
    
    /// Returns the store for the given model if it exists or creates it if it doesn't
    private func ensureStore(model : Graphable) -> GraphModelStore {
        return ensureStore(entityName: type(of: model).entity)
    }
}

