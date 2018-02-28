//
//  Graphable.swift
//  VaporGraph
//
//  Created by David Monagle on 11/4/17.
//
//

import Vapor
import FluentProvider
import Foundation

public protocol GraphSynchronizable {
    func needsSync() throws -> Bool
    func sync(executor: Executor?, force: Bool) throws
}

extension GraphSynchronizable {
    /// Default implementation of `sync(force)` which defaults `force` to `false`
    public func sync(executor: Executor?) throws {
        try sync(executor: executor, force: false)
    }
}

/**
    The Graphable protocol needs to be implemented on models that can be stored in the `Graph` object.
 
    Through the Graphable extension,
*/
public protocol Graphable : class, Model, GraphSynchronizable {
    static var graphIdGenerator : GraphIdGenerator? { get }
    
    var graphStorage : GraphStorage { get }
    func graphDeserialize(row: Row, in: Context?) throws
    func makeRow(in: Context?) throws -> Row
}

// MARK: Convenience

extension Graphable {
    public var graph : Graph? {
        get { return graphStorage.graph }
        set { graphStorage.graph = newValue }
    }
 
    public var snapshot : GraphSnapshot? {
        get { return graphStorage.snapshot }
    }
    
    /// Returns a Graph object if it is set, otherwise throws GraphError.noGraph
    public func enforceGraph() throws -> Graph {
        guard let graph = graph else { throw GraphError.noGraph }
        return graph
    }
}

// MARK: Deletable
extension Graphable {
    /// Marks the model for deletion on graph sync
    public func graphDelete() {
        graphStorage.deleted = true
    }

    /// Unmarks the model for deletion on graph sync
    public func graphUndelete() {
        graphStorage.deleted = false
    }
    
    /// Returns true if model is set to be deleted by the graph
    public var isGraphDeleted : Bool {
        return graphStorage.deleted
    }
}

// MARK: Snapshots

/// Extension to add snapshot functions to a graphable
extension Graphable {
    /// Satisfies the makeRow requirement for RowRepresentable by falling back to the graph version
    public func makeRow() throws -> Row {
        return try makeRow(in: GraphContext.row)
    }
    
    public func graphDeserialize(snapshot: GraphSnapshot, in context: Context? = GraphContext.snapshot) throws {
        try graphDeserialize(row: Row(snapshot), in: context)
    }
    
    /// Takes a snapshot of the current state using the GraphContext.snapshot context
    public func takeSnapshot() throws {
        try graphStorage.snapshot = makeSnapshot()
    }
    
    public func makeSnapshot() throws -> GraphSnapshot {
        return try GraphSnapshot(self.makeRow(in: GraphContext.snapshot))
    }
    
    /// Returns true if a snapshot is present.
    public var hasSnapshot: Bool {
        get {
            return graphStorage.snapshot != nil
        }
    }
    
    /// Removes the snapshot of this model
    public func removeSnapshot() {
        graphStorage.snapshot = nil
    }
    
    public func diffFromSnapshot() throws -> Row? {
        guard let snapshot = graphStorage.snapshot else { return nil }
        let current = try makeSnapshot()
        if let differences = try current.diff(from: snapshot) {
            return Row(differences)
        }
        return nil
    }
    
    public func rebase(from model: Graphable, updateSnapshot: Bool = true) throws {
        // If there is no snapshot, assume that everything is changed and therefor do nothing
        if (!hasSnapshot) { return }
        
        let modelData = try model.makeSnapshot()
        if let changes = try self.diffFromSnapshot(), let mergedData = try modelData.merge(with: changes) {
            try graphDeserialize(row: mergedData, in: GraphContext.snapshot)
            if (updateSnapshot) { graphStorage.snapshot = modelData }
        }
    }
    
    public func revertToSnapshot() throws {
        guard let snap = graphStorage.snapshot else { throw GraphError.noSnapshot }
        try self.graphDeserialize(snapshot: snap)
    }

    /// Checks the current state of the model data against the snapshot if it exists
    /// - Returns: true if syncing is required or if there is no snapshot present
    public func needsSync() throws -> Bool {
        if isGraphDeleted { return true }
        guard let snapshot = graphStorage.snapshot else { return true }
        let currentState = try self.makeSnapshot()
        return currentState != snapshot
    }
    
    
    /// Syncs this model with it's underlying database (if required or forced) and takes a snapshot
    public func sync(executor: Executor? = nil, force: Bool = false) throws {
        if try (force || needsSync()) {
            do {
                let model = self
                if model.isGraphDeleted {
                    try model.delete()
                    model.graph?.remove(model) // Remove the model from the graph
                }
                else {
                    let executor = try executor ?? model.makeExecutor()
                    try model.makeQuery(executor).save()
                    try model.takeSnapshot()
                }
            }
            catch (let error) {
                throw(GraphError.sync(self, error))
            }
        }
    }
}

