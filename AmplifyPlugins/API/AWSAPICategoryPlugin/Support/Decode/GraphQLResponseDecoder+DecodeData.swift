//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

extension GraphQLResponseDecoder {

    func decodeToResponseType(_ graphQLData: [String: JSONValue]) throws -> R {
        let graphQLData = try valueAtDecodePath(from: JSONValue.object(graphQLData))
        if request.responseType == String.self {
            let serializedJSON = try encoder.encode(graphQLData)
            guard let responseString = String(data: serializedJSON, encoding: .utf8) else {
                throw APIError.operationError("could not get string from data", "", nil)
            }
            guard let response = responseString as? R else {
                throw APIError.operationError("Not of type \(String(describing: R.self))", "", nil)
            }
            return response
        } else if request.responseType == AnyModel.self {
            let anyModel = try AnyModel(modelJSON: graphQLData)
            let serializedJSON = try encoder.encode(anyModel)
            return try decoder.decode(request.responseType, from: serializedJSON)
        } else {
            let serializedJSON = try encoder.encode(graphQLData)
            let responseData = try decoder.decode(request.responseType, from: serializedJSON)
            if responseData is Model {
                return try decodeToModelWithConnections(graphQLData: graphQLData) ?? responseData
            } else if responseData is ModelListMarker {
                return try decodeToAppSyncList(graphQLData: graphQLData)
            }
            return responseData
        }
    }

    func decodeToModelWithConnections(graphQLData: JSONValue) throws -> R? {
        let modelName = try getModelName(graphQLData: graphQLData)
        guard let modelType = ModelRegistry.modelType(from: modelName) else {
            return nil
        }
        let associations = modelType.schema.fields.values.filter {
            $0.isArray && $0.hasAssociation
        }
        guard !associations.isEmpty else {
            return nil
        }
        let id = try getId(graphQLData: graphQLData)
        guard case .object(var graphQLDataObject) = graphQLData else {
            return nil
        }
        modelType.schema.fields.values.forEach { modelField in
            if modelField.isArray && modelField.hasAssociation,
               let associatedField = modelField.associatedField {
                let modelFieldName = modelField.name
                let associatedFieldName = associatedField.name

                if graphQLData[modelFieldName] == nil {
                    let associationPayload: JSONValue = [
                        "associatedId": .string(id),
                        "associatedField": .string(associatedFieldName)
                    ]

                    graphQLDataObject.updateValue(associationPayload, forKey: modelFieldName)
                }
            }
        }
        let serializedJSON = try encoder.encode(graphQLDataObject)
        return try decoder.decode(request.responseType, from: serializedJSON)
    }

    func getModelName(graphQLData: JSONValue) throws -> String {
        guard case .string(let typename) = graphQLData["__typename"] else {
            throw APIError.operationError(
                "Could not retrieve __typename from object",
                """
                Could not retrieve the `__typename` attribute from the return value. Be sure to include __typename in \
                the selection set of the GraphQL operation. GraphQL:
                \(graphQLData)
                """
            )
        }

        return typename
    }

    func getId(graphQLData: JSONValue) throws -> String {
        guard case .string(let id) = graphQLData["id"] else {
            throw APIError.operationError(
                "Could not retrieve id from object",
                """
                Could not retrieve the `id` attribute from the return value. Be sure to include `id` in \
                the selection set of the GraphQL operation. GraphQL:
                \(graphQLData)
                """
            )
        }

        return id
    }

    func decodeToAppSyncList(graphQLData: JSONValue) throws -> R {
        let payload: AppSyncListPayload
        if let variables = request.variables {
            let variablesData = try JSONSerialization.data(withJSONObject: variables)
            let variablesJSON = try decoder.decode([String: JSONValue].self, from: variablesData)
            payload = AppSyncListPayload(document: request.document,
                                         variables: variablesJSON,
                                         graphQLData: graphQLData)
        } else {
            payload = AppSyncListPayload(document: request.document,
                                         graphQLData: graphQLData)
        }

        let encodedData = try encoder.encode(payload)
        return try decoder.decode(request.responseType, from: encodedData)
    }

    private func valueAtDecodePath(from graphQLData: JSONValue) throws -> JSONValue {
        guard let decodePath = request.decodePath else {
            return graphQLData
        }

        guard let model = graphQLData.value(at: decodePath) else {
            throw APIError.operationError("Could not retrieve object, given decode path: \(decodePath)", "", nil)
        }

        return model
    }
}
