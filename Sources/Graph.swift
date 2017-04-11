import Vapor
import Fluent
import Foundation

public class Graph {
    public enum DuplicateResolution {
        case rebase           ///
        case deserialize      /// Deserializes the data from the new record into the existing record. This keeps references the same and overwrites any changes that have been made to the original
        case keepExisting     /// Ignores the incoming record and return a reference to the existing one
        case replaceReference /// Replace the current reference with the new one. This could leave other classes with references to a model that no longer exists int he graph. Not really recommended
    }
    
    private var _store : [String: GraphModelStore] = [:]

    public func store<T>(forType: T.Type) -> GraphModelStore? where T : Entity {
        return _store[forType.entity]
    }
    
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
        let id : String

        if let modelId = model.id?.string {
            id = modelId
        }
        else {
            guard let generator = T.graphIdGenerator else { throw GraphError.noId }
            id = try generator(T.self)
            
            // Add the generated id to the model
            var m = model
            m.id = Node(id)
        }

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

