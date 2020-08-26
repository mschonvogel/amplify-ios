//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public typealias GraphQLSort = [String: String]

extension QuerySortBy {
    var graphQLSort: GraphQLSort {
        switch self {
        case .descending(let field):
            return ["field": field.stringValue, "direction": "desc"]
        case .ascending(let field):
            return ["field": field.stringValue, "direction": "asc"]
        }
    }
}
