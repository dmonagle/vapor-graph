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
    static var graphIdGenerator: GraphIdGenerator? = generateGraphUUID

    public var graph: Graph?
    public var snapshot: Node?
    public var id : Node?

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
        try deserialize(node: node, in: context)
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
    func deserialize(node: Node, in context: Context) throws {
        id = try node.extract("id")
        name = try node.extract("name")
        favoriteColor = try node.extract("favoriteColor")
        rating = try node.extract("rating")
    }
    
    func makeNode(context: Context) throws -> Node {
        var serialized = try Node(node: [
            "id": id,
            "name": name,
            "favoriteColor": favoriteColor,
            "rating": rating
        ])
        
        // Don't serialize updatedAt if we are serializing for the graph.
        if (!context.isGraph()) {
            updatedAt = Date()
            serialized["updatedAt"] = Node(updatedAt!.description)
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

