//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSPluginsCore
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPlugin

class AppSyncListTests: XCTestCase {

    override func setUp() {
        Amplify.reset()
        ModelRegistry.register(modelType: Post.self)
        ModelListDecoderRegistry.registerDecoder(AppSyncList<AnyModel>.self)
        do {
            let configWithAPI = try setUpAPICategory()
            try Amplify.configure(configWithAPI)
        } catch {
            XCTFail(String(describing: "Unable to setup API category for unit tests"))
        }
    }

    func testAppSyncListDeserializeFromGraphQLResponse() throws {
        let graphQLData: JSONValue = [
            "items": [[
                "id": "1",
                "title": JSONValue.init(stringLiteral: "title"),
                "content": JSONValue.init(stringLiteral: "content"),
                "createdAt": JSONValue.init(stringLiteral: Temporal.DateTime.now().iso8601String)
            ], [
                "id": "2",
                "title": JSONValue.init(stringLiteral: "title"),
                "content": JSONValue.init(stringLiteral: "content"),
                "createdAt": JSONValue.init(stringLiteral: Temporal.DateTime.now().iso8601String)
            ]],
            "nextToken": "nextToken"
        ]
        let serializedData = try AppSyncListTests.serialize(json: graphQLData)

        let list = try AppSyncListTests.deserialize(serializedData, responseType: Post.self)
        XCTAssertNotNil(list)
    }

    func testAppSyncListDeserializeFromAppSyncListPayload() throws {
        let graphQLData: JSONValue = [
            "items": [[
                "id": "1",
                "title": JSONValue.init(stringLiteral: "title"),
                "content": JSONValue.init(stringLiteral: "content"),
                "createdAt": JSONValue.init(stringLiteral: Temporal.DateTime.now().iso8601String)
            ], [
                "id": "2",
                "title": JSONValue.init(stringLiteral: "title"),
                "content": JSONValue.init(stringLiteral: "content"),
                "createdAt": JSONValue.init(stringLiteral: Temporal.DateTime.now().iso8601String)
            ]],
            "nextToken": "nextToken"
        ]
        let document = "query listPost"
        let variables: [String: JSONValue] = ["limit": "1000"]
        let payload = AppSyncListPayload(document: document,
                                         variables: variables,
                                         graphQLData: graphQLData)
        let serializedPayload = try AppSyncListTests.serialize(payload: payload)

        let list = try AppSyncListTests.deserialize(serializedPayload, responseType: Post.self)

        XCTAssertTrue(list.hasNextPage())
        let fetchCompleted = expectation(description: "Fetch completed")
        list.fetch(completion: { result in
            switch result {
            case .success(let list):
                XCTAssertNotNil(list)
                fetchCompleted.fulfill()
            case .failure(let coreError):
                XCTFail("Failed with error: \(coreError)")
            }
        })
        wait(for: [fetchCompleted], timeout: 1.0)
    }

    private static func serialize(json: JSONValue) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
        return try encoder.encode(json)
    }

    private static func serialize(payload: AppSyncListPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
        return try encoder.encode(payload)
    }

    private static func deserialize<R: Decodable>(_ data: Data, responseType: R.Type) throws -> List<R> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        return try decoder.decode(List<R>.self, from: data)
    }

    private func setUpAPICategory() throws -> AmplifyConfiguration {
        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestListener] = QueryRequestListenerResponder<AppSyncList<Post>> { _, listener in
            let list = AppSyncList<Post>()
            let event: GraphQLOperation<AppSyncList<Post>>.OperationResult = .success(.success(list))
            listener?(event)
            return nil
        }
        try Amplify.add(plugin: apiPlugin)

        let apiConfig = APICategoryConfiguration(plugins: [
            "MockAPICategoryPlugin": true
        ])
        let amplifyConfig = AmplifyConfiguration(api: apiConfig)
        return amplifyConfig
    }
}
