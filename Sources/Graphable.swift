//
//  Graphable.swift
//  VaporGraph
//
//  Created by David Monagle on 11/4/17.
//
//

import Vapor
import Fluent
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
public protocol Graphable : class, Model, GraphSynchronizable {
    static var graphIdGenerator : GraphIdGenerator? { get set }

    var graph : Graph? { get set }
    var snapshot : Node? { get set }
    
    func deserialize(node: Node, in context: Context) throws
}

// MARK: Snapshots

/// Extension to add snapshot functions to a graphable
extension Graphable {
    /// Takes a snapshot of the current state using the GraphContext.snapshot context
    public func takeSnapshot() throws {
        try snapshot = self.makeNode(context: GraphContext.snapshot)
    }
    
    /// Returns true if a snapshot is present.
    public var hasSnapshot: Bool {
        get {
            return snapshot != nil
        }
    }
    
    /// Removes the snapshot of this model
    public func removeSnapshot() {
        snapshot = nil
    }
    
    public func diffFromSnapshot() throws -> Node? {
        guard let snapshot = self.snapshot else { return nil }
        let selfNode = try makeNode(context: GraphContext.snapshot)
        let differences = try selfNode.diff(from: snapshot)
        return differences
    }
    
    public func rebase(from model: Graphable, updateSnapshot: Bool = true) throws {
        // If there is no snapshot, assume that everything is changed and therefor do nothing
        if (!hasSnapshot) { return }
        
        let modelData = try model.makeNode(context: GraphContext.snapshot)
        if let changes = try self.diffFromSnapshot(), let mergedData = try modelData.merge(with: changes) {
            try deserialize(node: mergedData, in: GraphContext.snapshot)
            if (updateSnapshot) { snapshot = modelData }
        }
    }
    
    public func revertToSnapshot() throws {
        guard let snap = snapshot else { throw GraphError.noSnapshot }
        try self.deserialize(node: snap, in: GraphContext.snapshot)
    }

    /// Checks the current state of the model data against the snapshot if it exists
    /// - Returns: true if syncing is required or if there is no snapshot present
    public func needsSync() throws -> Bool {
        guard let snapshot = self.snapshot else { return true }
        let currentState = try self.makeNode(context: GraphContext.snapshot)
        return currentState != snapshot
    }
    
    
    /// Syncs this model with it's underlying database (if requried or forced) and takes a snapshot
    public func sync(force: Bool) throws {
        if try (force || needsSync()) {
            do {
                var model = self
                try model.save()
                try model.takeSnapshot()
            }
            catch (let error) {
                throw(GraphError.sync(self, error))
            }
        }
    }
}

