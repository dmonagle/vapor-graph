import Vapor

public enum GraphError : Error {
    case noId
    case wrongType
}

public protocol Graphable : class, Model {
    var graph : Graph? { get set }
}

extension Graphable {
}

/// Stores a single type of Graphable
public class GraphModelStore {
    private var _models : [String: Graphable] = [:]
    
    init() {
        
    }
    
    func add(_ model : Graphable) throws {
        guard let id = model.id?.string else { throw GraphError.noId }
        _models[id] = model
    }
    
    func retrieve<T: Graphable>(id: Node) throws -> T? {
        guard let id = id.string else { throw GraphError.noId }
        return retrieve(id: id)
    }
    
    func retrieve<T: Graphable>(id: String) -> T? {
        guard let graphable = _models[id] else { return nil }
        guard let model = (graphable as? T) else { return nil }
        return model
    }
    
    var count : Int {
        return _models.count
    }
}

public class Graph {
    
    public func store<T : Graphable>(forType: T.Type) -> GraphModelStore? {
        return _store[forType.entity]
    }
    
    private var _store : [String: GraphModelStore] = [:]

    private func ensureStore(entityName: String) -> GraphModelStore {
        guard let store = _store[entityName] else {
            let newStore = GraphModelStore()
            _store[entityName] = newStore
            return newStore
        }
        
        return store
    }
    
    private func ensureStore<T : Graphable>(forType : T.Type) -> GraphModelStore {
        return ensureStore(entityName: forType.entity)
    }

    private func ensureStore(model : Graphable) -> GraphModelStore {
        return ensureStore(entityName: type(of: model).entity)
    }

    public func add(_ model : Graphable) throws {
        let store = ensureStore(model: model)
        try store.add(model)
        model.graph = self
    }
    
    /// Retrieves an object from the store
    func retrieve<T: Graphable>(id nodeId: NodeRepresentable) throws -> T? {
        let node = try nodeId.makeNode()
        guard let id = node.string else { throw GraphError.noId }
        return retrieve(id: id)
    }
    
    /// Retrieves an object from the store
    func retrieve<T : Graphable>(id: String) -> T? {
        let result : T? = _store[T.entity]?.retrieve(id: id)
        return result
    }
    
    /// Looks for the given id in the Graph. If it's not present it will search the database for it and, if found, add it to the Graph
    func find<T : Graphable>(id: NodeRepresentable) throws -> T? {
        if let result : T = try retrieve(id: id) { return result }
        guard let result = try T.find(id) else { return nil }
        try self.add(result)
        return result
    }
    
    public func clear() {
        _store = [:]
    }
}
