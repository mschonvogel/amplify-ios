//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Vote {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case createdAt
    case updatedAt
    case upvotes
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let vote = Vote.keys

    model.pluralName = "Votes"

    model.fields(
      .id(),
      .field(vote.title, is: .required, ofType: .string),
      .field(vote.createdAt, is: .required, ofType: .string),
      .field(vote.updatedAt, is: .required, ofType: .string),
      .field(vote.upvotes, is: .optional, ofType: .int)
    )
    }
}
