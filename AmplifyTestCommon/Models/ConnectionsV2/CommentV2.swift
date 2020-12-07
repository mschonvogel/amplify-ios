//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct CommentV2: Model {
  public let id: String
  public var content: String?
  public var postID: String

  public init(id: String = UUID().uuidString,
      content: String? = nil,
      postID: String) {
      self.id = id
      self.content = content
      self.postID = postID
  }
}
