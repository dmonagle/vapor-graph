//
//  StructuredData+Operators.swift
//  Geo
//
//  Created by David Monagle on 5/7/17.
//
//

import Foundation
import Node
import Fluent
import JSON


public protocol StructuredDataRepresentable : JSONRepresentable, RowRepresentable, NodeRepresentable {
    func makeStructuredData<T>() throws -> T where T : StructuredDataWrapper
}

extension StructuredDataRepresentable {
    public func makeNode(in context: Context?) throws -> Node {
        let value : Node = try makeStructuredData()
        return value
    }
    
    public func makeJSON() throws -> JSON {
        let value : JSON = try makeStructuredData()
        return value
    }
    
    public func makeRow() throws -> Row {
        let value : Row = try makeStructuredData()
        return value
    }
}

public protocol StructuredDataInitializable : JSONInitializable, RowInitializable, NodeInitializable {
    init?<T>(structuredData: T?) where T : StructuredDataWrapper
}

extension StructuredDataInitializable {
    public init(node: Node) throws {
        guard let value = Self.init(structuredData: node) else { throw StructuredDataError.initFailedWithValue(Self.self, node.wrapped) }
        self = value
    }
    
    public init(json: JSON) throws {
        guard let value = Self.init(structuredData: json) else { throw StructuredDataError.initFailedWithValue(Self.self, json.wrapped) }
        self = value
    }
    
    public init(row: Row) throws {
        guard let value = Self.init(structuredData: row) else { throw StructuredDataError.initFailedWithValue(Self.self, row.wrapped) }
        self = value
    }
}

public protocol StructuredDataConvertible : StructuredDataRepresentable, StructuredDataInitializable {
}

infix operator =?

private protocol OptionalProtocol {}
extension Optional : OptionalProtocol {}

/// Deserializes the value of the data at the given path into the given target as long as it's not nil
public func =?<T,W>(left: inout T, data: W?) throws where W : StructuredDataWrapper {
    guard let data = data else { return } // No assignment if the data is nil
    if data.isNull && !(T.self is OptionalProtocol.Type) { return } // Can only assign null if T is an optional
    try left = data.get()
}
