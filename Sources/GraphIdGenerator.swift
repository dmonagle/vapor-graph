//
//  GraphIdGenerator.swift
//  VaporGraph
//
//  Created by David Monagle on 11/4/17.
//
//

import Vapor
import Foundation

public typealias GraphIdGenerator = (Graphable.Type) throws -> Identifier

/// Generates a UUID to use as the id for a model
public func generateGraphUUID(type: Graphable.Type) throws -> Identifier {
    return Identifier(UUID().uuidString)
}

/// Generates an id for a PostgreSQL model. This relies on the standard creation of a sequence named <entity>_id_seq in the database.
public func generateGraphPostgreSQLID(type: Graphable.Type) throws -> Identifier {
    let query = "SELECT nextval('\(type.entity)_id_seq')"
    let result = try type.database?.driver.raw(query)
    guard let id = result?[0]?["nextval"] else { throw GraphError.noId }
    return Identifier(id)
}
