//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Vote: Model {
  public let id: String
  public var title: String
  public var createdAt: String
  public var updatedAt: String
  public var upvotes: Int?

  public init(id: String = UUID().uuidString,
      title: String,
      createdAt: String,
      updatedAt: String,
      upvotes: Int? = nil) {
      self.id = id
      self.title = title
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.upvotes = upvotes
  }
}
