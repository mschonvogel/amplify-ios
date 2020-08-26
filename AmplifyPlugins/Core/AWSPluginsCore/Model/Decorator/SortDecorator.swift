//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Decorates a GraphQL document with a "sort" input
public struct SortDecorator: ModelBasedGraphQLDocumentDecorator {

    private let sortBy: QuerySortBy

    public init(sortBy: QuerySortBy) {
        self.sortBy = sortBy
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        var inputs = document.inputs
        let modelName = modelType.schema.name

        inputs["sort"] = GraphQLDocumentInput(type: "Searchable\(modelName)SortInput",
            value: .object(sortBy.graphQLSort))

        return document.copy(inputs: inputs)
    }
}
