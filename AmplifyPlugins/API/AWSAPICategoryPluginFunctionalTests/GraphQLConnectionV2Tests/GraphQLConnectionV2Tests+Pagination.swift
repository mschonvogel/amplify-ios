//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
import AWSPluginsCore
@testable import AWSAPICategoryPlugin
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPluginTestCommon

extension GraphQLConnectionV2Tests {

    /// Test paginated list query returns a List containing pagination functionality. This test also aggregates page
    /// results by appending to an in-memory Array, useful to backing UI components which.
    ///
    /// - Given: Two posts, and a query with the predicate for the two posts and a limit of 1
    /// - When:
    ///    - first query returns a List that provides Paginatable methods, and contains next page.
    ///    - subsequent queries exhaust the results from the API to retrieve the remaining results
    /// - Then:
    ///    - the in-memory Array is a populated with all expected items.
    func testPaginatedListFetch() throws {
        var resultsArray: [PostV2] = []
        let uuid1 = UUID().uuidString
        let uuid2 = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard createPost(id: uuid1, title: title) != nil,
              createPost(id: uuid2, title: title) != nil else {
            XCTFail("Failed to ensure at least two Posts to be retrieved on the listQuery")
            return
        }

        let firstQueryCompleted = expectation(description: "first query completed")
        let post = PostV2.keys
        let predicate = post.id == uuid1 || post.id == uuid2
        var results: List<PostV2>?
        _ = Amplify.API.query(request: .paginatedList(PostV2.self, where: predicate, limit: 1)) { event in
            switch event {
            case .success(let response):
                guard case let .success(graphQLResponse) = response else {
                    XCTFail("Missing successful response")
                    return
                }

                results = graphQLResponse
                firstQueryCompleted.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failure event: \(error)")
            }
        }

        wait(for: [firstQueryCompleted], timeout: TestCommonConstants.networkTimeout)
        guard var subsequentResults = results else {
            XCTFail("Could not get first results")
            return
        }

        resultsArray.append(contentsOf: subsequentResults)

        while subsequentResults.hasNextPage() {
            let semaphore = DispatchSemaphore(value: 0)
            subsequentResults.getNextPage { result in
                defer {
                    semaphore.signal()
                }
                switch result {
                case .success(let listResult):
                    subsequentResults = listResult
                    resultsArray.append(contentsOf: subsequentResults)
                case .failure(let coreError):
                    XCTFail("Unexpected error: \(coreError)")
                }

            }
            semaphore.wait()
        }
        XCTAssertEqual(resultsArray.count, 2)
    }

    /// Test paginated list query returns a List containing pagination functionality. This test also aggregates page
    /// results by appending to an in-memory Array, useful to backing UI components which.
    ///
    /// - Given: Two posts, and a query with the predicate, exhausted `fetch` calls
    /// - When:
    ///    - A `fetch` is made when `hasNextPage` returns false.
    /// - Then:
    ///    - A validation error is returned
    func testPaginatedListFetchValidationError() throws {
        let uuid1 = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard createPost(id: uuid1, title: title) != nil else {
            XCTFail("Failed to create post")
            return
        }

        let firstQueryCompleted = expectation(description: "first query completed")
        let post = PostV2.keys
        let predicate = post.id == uuid1
        var results: List<PostV2>?
        _ = Amplify.API.query(request: .paginatedList(PostV2.self, where: predicate)) { event in
            switch event {
            case .success(let response):
                guard case let .success(graphQLResponse) = response else {
                    XCTFail("Missing successful response")
                    return
                }

                results = graphQLResponse
                firstQueryCompleted.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failure event: \(error)")
            }
        }

        wait(for: [firstQueryCompleted], timeout: TestCommonConstants.networkTimeout)
        guard var subsequentResults = results else {
            XCTFail("Could not get first results")
            return
        }
        while subsequentResults.hasNextPage() {
            let semaphore = DispatchSemaphore(value: 0)
            subsequentResults.getNextPage { result in
                defer {
                    semaphore.signal()
                }
                switch result {
                case .success(let listResult):
                    subsequentResults = listResult
                case .failure(let coreError):
                    XCTFail("Unexpected error: \(coreError)")
                }

            }
            semaphore.wait()
        }
        XCTAssertFalse(subsequentResults.hasNextPage())
        let invalidFetchCompleted = expectation(description: "fetch completed with validation error")
        subsequentResults.getNextPage { result in

            switch result {
            case .success(let listResult):
                XCTFail("Unexpected .success \(listResult)")
            case .failure(let coreError):
                guard case .validation = coreError else {
                    XCTFail("Unexpected CoreError \(coreError)")
                    return
                }
                invalidFetchCompleted.fulfill()
            }
        }

        wait(for: [invalidFetchCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testFetchListOfCommentsFromPost() {
        let uuid1 = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let createdPost = createPost(id: uuid1, title: title) else {
            XCTFail("Failed to create post")
            return
        }
        guard createComment(content: title, post: createdPost) != nil else {
            XCTFail("Failed to create comment")
            return
        }

        let firstQueryCompleted = expectation(description: "first query completed")
        var post: PostV2?
        _ = Amplify.API.query(request: .get(PostV2.self, byId: createdPost.id)) { event in
            switch event {
            case .success(let response):
                guard case let .success(graphQLResponse) = response else {
                    XCTFail("Missing successful response")
                    return
                }

                post = graphQLResponse
                firstQueryCompleted.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failure event: \(error)")
            }
        }

        wait(for: [firstQueryCompleted], timeout: TestCommonConstants.networkTimeout)
        guard let retrievedPost = post else {
            XCTFail("Could not get post")
            return
        }
        guard let comments = retrievedPost.comments else {
            XCTFail("Could not get comments")
            return
        }
        XCTAssertTrue(comments.isEmpty)
        let fetchCommentsCompleted = expectation(description: "Fetch comments completed")
        comments.fetch { result in
            switch result {
            case .success(let comments):
                print("comments \(comments)")
                fetchCommentsCompleted.fulfill()
            case .failure(let coreError):
                print("Error: \(coreError)")
            }
        }
        wait(for: [fetchCommentsCompleted], timeout: TestCommonConstants.networkTimeout)
        XCTAssertFalse(comments.isEmpty)
        comments.forEach { comment in
            XCTAssertEqual(comment.postID, retrievedPost.id)
        }
    }
}
