import Vapor
import Fluent
import Foundation

public enum GraphError : Error {
    case noId
    case wrongType
    case noSnapshot
}

public enum GraphContext: Context {
    case snapshot
}

public protocol GraphSynchronizable {
    func needsSync() throws -> Bool
    
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

public protocol Graphable : class, Model, GraphSynchronizable {
    var graph : Graph? { get set }
    var snapshot : Node? { get set }
    
    func deserialize(node: Node, in context: Context) throws
}

extension Graphable {
    func takeSnapshot() throws {
        try snapshot = self.makeNode(context: GraphContext.snapshot)
    }
    
    var hasSnapshot: Bool {
        get {
            return snapshot != nil
        }
    }
    
    func diffFromSnapshot() throws -> Node? {
        guard let snapshot = self.snapshot else { return nil }
        let selfNode = try makeNode(context: GraphContext.snapshot)
        let differences = try selfNode.diff(from: snapshot)
        return differences
    }
    
    func rebase(from model: Graphable, updateSnapshot: Bool = true) throws {
        // If there is no snapshot, assume that everything is changed and therefor do nothing
        if (!hasSnapshot) { return }
        
        let modelData = try model.makeNode(context: GraphContext.snapshot)
        if let changes = try self.diffFromSnapshot(), let mergedData = try modelData.merge(with: changes) {
            try deserialize(node: mergedData, in: GraphContext.snapshot)
            if (updateSnapshot) { snapshot = modelData }
        }
    }
    
    func revertToSnapshot() throws {
        guard let snap = snapshot else { throw GraphError.noSnapshot }
        try self.deserialize(node: snap, in: GraphContext.snapshot)
    }
}

extension Graphable {
    public func needsSync() throws -> Bool {
        guard let snapshot = self.snapshot else { return true }
        let currentState = try self.makeNode(context: GraphContext.snapshot)
        return currentState != snapshot
    }
}

public class Graph {
    public enum DuplicateResolution {
        case rebase           ///
        case deserialize      /// Deserializes the data from the new record into the existing record. This keeps references the same and overwrites any changes that have been made to the original
        case keepExisting     /// Ignores the incoming record and return a reference to the existing one
        case replaceReference /// Replace the current reference with the new one. This could leave other classes with references to a model that no longer exists int he graph. Not really recommended
    }
    
    public func store<T>(forType: T.Type) -> GraphModelStore? where T : Entity {
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

    public func inject<T>(_ model : T, duplicateResolution: DuplicateResolution = .rebase, takeSnapshot: Bool = false) throws -> T where T : Graphable{
        guard let id = model.id?.string else { throw GraphError.noId }

        let store = ensureStore(model: model)
        
        // If the model, according to it's id, already exists in the store, we need to return the reference already in the graph
        if let existing : T = store.retrieve(id: id) {
            switch duplicateResolution {
            case .keepExisting:
                return existing
            case .deserialize:
                try existing.deserialize(node: try model.makeNode(context: GraphContext.snapshot), in: GraphContext.snapshot)
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
    
    /// Retrieves an object from the Graph
    func retrieve<T: Graphable>(id nodeId: NodeRepresentable) throws -> T? {
        let node = try nodeId.makeNode()
        guard let id = node.string else { throw GraphError.noId }
        return retrieve(id: id)
    }
    
    /// Retrieves an object from the Graph
    func retrieve<T : Graphable>(id: String) -> T? {
        let result : T? = _store[T.entity]?.retrieve(id: id)
        return result
    }
    
    /// Looks for the given id in the Graph. If it's not present it will search the database for it and, if found, add it to the Graph
    func find<T : Graphable>(id: NodeRepresentable) throws -> T? {
        if let result : T = try retrieve(id: id) { return result }
        guard let result = try T.find(id) else { return nil }
        return try self.inject(result, takeSnapshot: true)
    }
    
    public func clear() {
        _store = [:]
    }
}

