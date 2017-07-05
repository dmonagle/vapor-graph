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
    var graphStorage: GraphStorage = GraphStorage()
    let storage: Storage = Storage()

    static var graphIdGenerator: GraphIdGenerator? = generateGraphUUID

    // MARK: Properties
    public var name : String = ""
    public var rating : Int = 0
    public var favoriteColor: String? = nil
    public var updatedAt: Date?
    
    init(named name: String, withFavoriteColor color: String? = nil, rated: Int = 0) {
        self.name = name
        self.favoriteColor = color
        self.rating = rated
    }
    
    init(node: Node, in context: Context) throws {
        try graphDeserialize(node: node, in: context)
    }

    init(row: Row) throws {
        try graphDeserialize(node: Node(row), in: GraphContext.storage)
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
    func graphDeserialize(node: NodeRepresentable, in context: Context?) throws {
        let node = try node.makeNode(in: context)
        id = try node.get("id")
        name = try node.get("name")
        favoriteColor = try node.get("favoriteColor")
        rating = try node.get("rating")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        var serialized = try Node(node: [
            "id": id ?? nil,
            "name": name,
            "favoriteColor": favoriteColor ?? Node.null,
            "rating": rating
        ])
        
        // Don't serialize updatedAt if we are serializing for the graph.
        if (context?.isGraph() == true) {
            updatedAt = Date()
            serialized["updatedAt"] = Node(updatedAt!.description)
        }
        
        return serialized
    }
    
    func makeRow() throws -> Row {
        return try Row(makeNode(in: graphStorage.context))
    }
    
}

// MARK: Preparations
extension Person {
    public static func revert(_ database: Database) throws {
    }
    
    public static func prepare(_ database: Database) throws {
    }
}

