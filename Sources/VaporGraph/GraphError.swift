//
//  GraphError.swift
//  VaporGraph
//
//  Created by David Monagle on 11/4/17.
//
//

import Foundation

public enum GraphError : Error {
    case noId
    case noGraph
    case wrongType
    case noSnapshot
    case sync(Graphable, Error)
}
