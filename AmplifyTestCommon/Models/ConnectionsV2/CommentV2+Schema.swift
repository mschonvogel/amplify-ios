//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension CommentV2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case postID
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let commentV2 = CommentV2.keys

    model.pluralName = "CommentV2s"

    model.fields(
      .id(),
      .field(commentV2.content, is: .optional, ofType: .string),
      .field(commentV2.postID, is: .required, ofType: .string)
    )
    }
}
