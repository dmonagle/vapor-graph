//
//  StructuredDataWrapperExtension.swift
//  VaporGraph
//
//  Created by David Monagle on 12/7/17.
//
//

import Node

extension StructuredDataWrapper {
    /// Performs the standard get on the StructuredData path. If there is no defined data at the given path, sets the default instead.
    public func get<T>(_ path: String, default value: T) throws -> T {
        if wrapped[path] == nil { return value }
        return try get(path)
    }
}
