//
//  ModelFactory.swift
//  Graph
//
//  Created by David Monagle on 04/04/2017.
//
//

import VaporGraph
import Fluent
import Vapor
import Foundation

final class Person : Graphable {
    static let graphIdGenerator: GraphIdGenerator? = generateGraphUUID

    let graphStorage: GraphStorage = GraphStorage()
    let storage: Storage = Storage()

    // MARK: Properties
    public var name : String = ""
    public var rating : Int = 0
    public var favoriteColor: String? = nil
    public var updatedAt: Date?
    
    public init(named name: String, withFavoriteColor color: String? = nil, rated: Int = 0) {
        self.name = name
        self.favoriteColor = color
        self.rating = rated
    }
    
    public init(row: Row) throws {
        try graphDeserialize(row: row, in: GraphContext.row)
    }
}

// MARK: Factories

extension Person {
    static var Tommy : Person {
        get {
            return Person(named: "Tommy", withFavoriteColor: "Green", rated: 10)
        }
    }
    static var Kimberly : Person {
        get {
            return Person(named: "Kimberly", withFavoriteColor: "Pink", rated: 5)
        }
    }
}


// MARK: Serialization
extension Person {
    public func graphDeserialize(row: Row, in context: Context?) throws {
        id = try row.get("id")
        name = try row.get("name")
        favoriteColor = try row.get("favoriteColor")
        rating = try row.get("rating")
    }
    
    public func makeRow(in context: Context?) throws -> Row {
        var serialized = try Row(node: [
            "id": id ?? nil,
            "name": name,
            "favoriteColor": favoriteColor ?? Node.null,
            "rating": rating
        ])
        
        // Don't serialize updatedAt if we are serializing for the graph.
        if (context?.isGraph() == true) {
            updatedAt = Date()
            try serialized.set("updatedAt", updatedAt!.description)
        }
        
        return serialized
    }
}

// MARK: Preparations
extension Person {
    public static func revert(_ database: Database) throws {
    }
    
    public static func prepare(_ database: Database) throws {
    }
}

