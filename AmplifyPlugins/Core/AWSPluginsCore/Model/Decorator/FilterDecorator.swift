//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Decorates a GraphQL mutation with a "condition" input or a GraphQL query with a "filter" input.
/// The value is a `GraphQLFilter` object
public struct FilterDecorator: ModelBasedGraphQLDocumentDecorator {

    private let filter: GraphQLFilter
    private let queryType: GraphQLQueryType?

    public init(filter: GraphQLFilter, queryType: GraphQLQueryType? = nil) {
        self.filter = filter
        self.queryType = queryType
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        var inputs = document.inputs
        let modelName = modelType.schema.name
        if case .mutation = document.operationType {
            inputs["condition"] = GraphQLDocumentInput(type: "Model\(modelName)ConditionInput",
                value: .object(filter))
        } else if case .query = document.operationType {
            if let queryType = queryType, queryType == .search {
                inputs["filter"] = GraphQLDocumentInput(type: "Searchable\(modelName)FilterInput",
                    value: .object(filter))
            } else {
                inputs["filter"] = GraphQLDocumentInput(type: "Model\(modelName)FilterInput",
                    value: .object(filter))
            }
        }

        return document.copy(inputs: inputs)
    }
}
