//
//  Node+merge.swift
//  VaporGraph
//
//  Created by David Monagle on 10/4/17.
//
//

import Node

extension StructuredData {
    /// Returns a node with the values of the given node merged with this node
    func merge(with data: StructuredData) throws -> StructuredData? {
        // Make sure both nodes are objects
        switch (self, data) {
        case (var .object(original), let .object(toMerge)):
            var result = self
            // Check each key in the changed node for differences
            try toMerge.forEach { mergeKey, mergeValue in
                if let originalValue = original[mergeKey] {
                    // The key exists in both the original and the merge, merge recursively
                    try result[mergeKey] = originalValue.merge(with: mergeValue)
                }
                else {
                    // The merge value doesn't exist in the original, so add it.
                    result[mergeKey] = mergeValue
                }
            }
            return result
        // All other cases where the types match result in self being replaced with the merge
        case (.array(_), .array(_)),
             (.string(_), .string(_)),
             (.bool(_), .bool(_)),
             (.number(_), .number(_)),
             (.bytes(_), .bytes(_)):
            return data
        default:
            return nil
        }
    }
}

extension StructuredDataWrapper {
    func merge<T : StructuredDataWrapper>(with referenceWrapper: T) throws -> T? {
        guard let returnValue = try self.wrapped.merge(with: referenceWrapper.wrapped) else { return nil }
        return T(returnValue)
    }
}
