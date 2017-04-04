//
//  ModelFactory.swift
//  Graph
//
//  Created by David Monagle on 04/04/2017.
//
//

import Graph
import Fluent
import Vapor

final class Person : Graphable {
    /**
     The revert method should undo any actions
     caused by the prepare method.
     
     If this is impossible, the `PreparationError.revertImpossible`
     error should be thrown.
     */
    public static func revert(_ database: Database) throws {
    }
    
    /**
     The prepare method should call any methods
     it needs on the database to prepare.
     */
    public static func prepare(_ database: Database) throws {
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            ])
    }
    
    var graph: Graph? = nil
    
    var id : Node? = nil
    var name : String = ""
    
    init(named name: String) {
        self.name = name
    }
    
    init(node: Node, in context: Context) throws {
    }
}

