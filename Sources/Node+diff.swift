//
//  Node+diff.swift
//  VaporGraph
//
//  Created by David Monagle on 10/4/17.
//
//

import Node

extension Node {
    /// Returns a structure outlining the differences between self and the given reference node
    func diff(from referenceNode: Node) throws -> Node? {
        // Make sure both nodes are objects
        switch (self, referenceNode) {
        case let (.object(changed), .object(reference)):
            var result : Node = [:]
            
            // Check each key in the changed node for differences
            try changed.forEach { changedKey, changedValue in
                if let referenceValue = reference[changedKey] {
                    // The key exists in both the reference and the changed, set it with a recursive diff
                    if let changes = try changedValue.diff(from: referenceValue) {
                        result[changedKey] = changes
                    }
                }
                else {
                    // This is a new key that did not exist in the original, add it to the result
                    result[changedKey] = changedValue
                }
            }

            // Check each key in the reference node for keys that have been removed
            reference.forEach { referenceKey, _ in
                if let _ = changed[referenceKey] {}
                else {
                    result[referenceKey] = Node.null
                }
            }
            
            // If there are no differences, return nil
            if (result.object?.count == 0) { return nil }
            
            return result
        case let (.array(changed), .array(reference)):
            if (reference != changed) { return self }
            return nil
        case let (.string(changed), .string(reference)):
            if (reference != changed) { return self }
            return nil
        case let (.bool(changed), .bool(reference)):
            if (reference != changed) { return self }
            return nil
        case let (.number(changed), .number(reference)):
            if (reference != changed) { return self }
            return nil
        case let (.bytes(changed), .bytes(reference)):
            if (reference != changed) { return self }
            return nil
        default:
            return self
        }
    }
}
