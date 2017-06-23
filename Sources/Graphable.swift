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
    func sync(force: Bool) throws
}

extension GraphSynchronizable {
    /// Default implementation of `sync(force)` which defaults `force` to `false`
    public func sync() throws {
        try sync(force: false)
    }
}

/**
    The Graphable protocol needs to be implemented on models that can be stored in the `Graph` object.
 
    Through the Graphable extension,
*/
public protocol Graphable : class, Model, GraphSynchronizable, NodeRepresentable {
    static var graphIdGenerator : GraphIdGenerator? { get set }
    
    var graphStorage : GraphStorage { get set }
    func deserialize(node: NodeRepresentable, in: Context?) throws
}

// MARK: Convenience

extension Graphable {
    public var graph : Graph? {
        get { return graphStorage.graph }
        set { graphStorage.graph = newValue }
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
    /// Takes a snapshot of the current state using the GraphContext.snapshot context
    public func takeSnapshot() throws {
        try graphStorage.snapshot = makeSnapshot()
    }
    
    public func makeSnapshot() throws -> GraphSnapshot {
        return try GraphSnapshot(self.makeNode(in: GraphContext.snapshot))
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
    
    public func diffFromSnapshot() throws -> Node? {
        guard let snapshot = graphStorage.snapshot else { return nil }
        let current = try makeSnapshot()
        let differences = try current.diff(from: snapshot)
        return try differences.makeNode(in: emptyContext)
    }
    
    public func rebase(from model: Graphable, updateSnapshot: Bool = true) throws {
        // If there is no snapshot, assume that everything is changed and therefor do nothing
        if (!hasSnapshot) { return }
        
        let modelData = try model.makeSnapshot()
        if let changes = try self.diffFromSnapshot(), let mergedData = try modelData.merge(with: changes) {
            try deserialize(node: mergedData, in: GraphContext.snapshot)
            if (updateSnapshot) { graphStorage.snapshot = modelData }
        }
    }
    
    public func revertToSnapshot() throws {
        guard let snap = graphStorage.snapshot else { throw GraphError.noSnapshot }
        try self.deserialize(node: snap, in: GraphContext.snapshot)
    }

    /// Checks the current state of the model data against the snapshot if it exists
    /// - Returns: true if syncing is required or if there is no snapshot present
    public func needsSync() throws -> Bool {
        guard let snapshot = graphStorage.snapshot else { return true }
        let currentState = try self.makeSnapshot()
        return currentState != snapshot
    }
    
    
    /// Syncs this model with it's underlying database (if requried or forced) and takes a snapshot
    public func sync(force: Bool) throws {
        if try (force || needsSync()) {
            do {
                let model = self
                if model.isGraphDeleted {
                    try model.delete()
                    model.graph?.remove(model) // Remove the model from the graph
                }
                else {
                    try model.save()
                    try model.takeSnapshot()
                }
            }
            catch (let error) {
                throw(GraphError.sync(self, error))
            }
        }
    }
}

