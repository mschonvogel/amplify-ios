//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSPluginsCore
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPlugin


class GraphQLResponseDecoderTests: XCTestCase {
    static let decoder = JSONDecoder()
    static let encoder = JSONEncoder()

    override class func setUp() {
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
    }

    struct SimpleModel: Model {
        public let id: String

        public init(id: String = UUID().uuidString) {
            self.id = id
        }

        public enum CodingKeys: String, ModelKey {
            case id
        }

        public static let keys = CodingKeys.self

        public static let schema = defineSchema { model in
            let post = Post.keys
            model.pluralName = "SimpleModels"
            model.fields(
                .id()
            )
        }
    }

    func testDecodeToString() throws {
        let request = GraphQLRequest<String>(document: "",
                                             responseType: String.self,
                                             decodePath: "data.getSimpleModel")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "data": [
                "getSimpleModel": [
                    "id": "id"
                ]
            ]
        ]

        let result = try decoder.decodeToResponseType(graphQLData)
        XCTAssertEqual(result, "{\"id\":\"id\"}")
    }

    func testDecodeToAnyModel() throws {
        ModelRegistry.register(modelType: SimpleModel.self)
        let request = GraphQLRequest<AnyModel>(document: "",
                                                  responseType: AnyModel.self,
                                                  decodePath: "data.getSimpleModel")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "data": [
                "getSimpleModel": [
                    "id": "id",
                    "__typename": "SimpleModel"
                ]
            ]
        ]

        let result = try decoder.decodeToResponseType(graphQLData)
        XCTAssertNotNil(result)
        XCTAssertEqual(result.id, "id")
        XCTAssertEqual(result.modelName, "SimpleModel")
        guard let simpleModel = result.instance as? SimpleModel else {
            XCTFail("Failed to get SimpleModel")
            return
        }
        XCTAssertEqual(simpleModel.id, "id")
    }

    func testDecodeToModel() throws {
        let request = GraphQLRequest<SimpleModel>(document: "",
                                                  responseType: SimpleModel.self,
                                                  decodePath: "data.getSimpleModel")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "data": [
                "getSimpleModel": [
                    "id": "id"
                ]
            ]
        ]

        let result = try decoder.decodeToResponseType(graphQLData)
        XCTAssertNotNil(result)
        XCTAssertEqual(result.id, "id")
    }

    func testDecodeToModelList() throws {
        ModelListDecoderRegistry.registerDecoder(AppSyncList<AnyModel>.self)
        let request = GraphQLRequest<List<SimpleModel>>(document: "",
                                                        responseType: List<SimpleModel>.self,
                                                        decodePath: "data.listSimpleModels")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "data": [
                "listSimpleModels": [
                    "items": [
                        ["id": "id1"],
                        ["id": "id2"]
                    ],
                    "nextToken": "nextToken123"
                ]
            ]
        ]


        let result = try decoder.decodeToResponseType(graphQLData)
        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.hasNextPage())
        guard let appSyncList = result as? AppSyncList else {
            XCTFail("Could not get AppSyncList")
            return
        }
        XCTAssertEqual(appSyncList.nextToken, "nextToken123")
    }

    // TODO: refactor to use PostV2
    func testDecodeToPostWithComments() throws {
        ModelListDecoderRegistry.registerDecoder(AppSyncList<AnyModel>.self)
        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)
        let request = GraphQLRequest<Post>(document: "",
                                           responseType: Post.self,
                                           decodePath: "data.getPost")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "data": [
                "getPost": [
                    "id": .string("postId123"),
                    "content": .string("content"),
                    "title": .string("title"),
                    "createdAt": .string(Temporal.DateTime.now().iso8601String),
                    "updatedAt": .string(Temporal.DateTime.now().iso8601String),
                    "__typename": "Post"
                ]
            ]
        ]

        let post = try decoder.decodeToResponseType(graphQLData)
        XCTAssertNotNil(post)

        guard let comments = post.comments else {
            XCTFail("Could not get non-nil comments of type List")
            return
        }

        XCTAssertTrue(comments.isEmpty)
        guard let appSyncList = comments as? AppSyncList else {
            XCTFail("Failed to check comments is of type AppSyncList")
            return
        }

        XCTAssertNotNil(appSyncList.associatedId)
        XCTAssertEqual(appSyncList.associatedId!, "postId123")
        XCTAssertNotNil(appSyncList.associatedField)
        XCTAssertEqual(appSyncList.associatedField!.name, "post")
        XCTAssertNil(appSyncList.nextToken)

        let apiConfig = APICategoryConfiguration(plugins: ["MockAPICategoryPlugin": true])
        let amplifyConfig = AmplifyConfiguration(api: apiConfig)
        let apiPlugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: apiPlugin)
        try Amplify.configure(amplifyConfig)

        let apiWasQueried = expectation(description: "API was queried")
        let responder = QueryRequestListenerResponder<AppSyncList<Comment>> { _, listener in
            let comment = Comment(content: "content", createdAt: .now(), post: post)
            let list = AppSyncList<Comment>([comment, comment],
                                            nextToken: "nextTokenForComments",
                                            document: "",
                                            variables: ["limit": 1_000])
            let event: GraphQLOperation<AppSyncList<Comment>>.OperationResult = .success(.success(list))
            listener?(event)
            apiWasQueried.fulfill()
            return nil
        }
        apiPlugin.responders[.queryRequestListener] = responder

        let fetchCommentsCompleted = expectation(description: "Fetch comments completed")
        comments.fetch { listResult in
            switch listResult {
            case .success(let comments):
                XCTAssertEqual(comments.count, 2)
                fetchCommentsCompleted.fulfill()
            case .failure(let coreError):
                XCTFail("Failed to fetch comments, error: \(coreError)")
            }
        }
        wait(for: [apiWasQueried, fetchCommentsCompleted], timeout: 1)

        guard let updatedList = comments as? AppSyncList else {
            XCTFail("Failed to check comments is of type AppSyncList")
            return
        }
        XCTAssertEqual(updatedList.nextToken, "nextTokenForComments")
    }
}
