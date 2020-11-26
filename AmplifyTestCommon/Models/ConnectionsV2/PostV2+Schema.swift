//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension PostV2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case description
    case comments
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let postV2 = PostV2.keys

    model.pluralName = "PostV2s"

    model.fields(
      .id(),
      .field(postV2.title, is: .optional, ofType: .string),
      .field(postV2.description, is: .optional, ofType: .string),
      .hasMany(postV2.comments, is: .optional, ofType: CommentV2.self, associatedWith: CommentV2.keys.postID)
    )
    }
}
