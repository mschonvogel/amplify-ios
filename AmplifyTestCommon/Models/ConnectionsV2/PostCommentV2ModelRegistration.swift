//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

final public class PostCommentV2ModelRegistration: AmplifyModelRegistration {
    public func registerModels(registry: ModelRegistry.Type) {
        ModelRegistry.register(modelType: PostV2.self)
        ModelRegistry.register(modelType: CommentV2.self)
    }

    public let version: String = "1"
}
