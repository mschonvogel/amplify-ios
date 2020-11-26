//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct PostV2: Model {
  public let id: String
  public var title: String?
  public var description: String?
  public var comments: List<CommentV2>?

  public init(id: String = UUID().uuidString,
      title: String? = nil,
      description: String? = nil,
      comments: List<CommentV2>? = []) {
      self.id = id
      self.title = title
      self.description = description
      self.comments = comments
  }
}
