## Model Based GraphQL 

The following steps demonstrate how to set up a GraphQL endpoint with AppSync. The auth configured will be API key. The set up is used to run the tests in `GraphQLModelBasedTests.swift`


### Set-up

1. `amplify-init`

2. `amplify add api`


```perl
? Please select from one of the below mentioned services: `GraphQL`
? Provide API name: `<APIName>`
? Choose the default authorization type for the API `API key`
? Enter a description for the API key:
? After how many days from now the API key should expire (1-365): `365`
? Do you want to configure advanced settings for the GraphQL API `No, I am done`
? Do you have an annotated GraphQL schema? `Yes`
? Provide your schema file path: `schema.graphql`
```
When asked to provide the schema, create the `schema.graphql` file
```
type CommentV2 @model @auth(rules: [{allow: public}]) @key(name: "byPost", fields: ["postID"]) {
  id: ID!
  content: String
  postID: ID!
}

type PostV2 @model @auth(rules: [{allow: public}]) {
  id: ID!
  title: String
  description: String
  comments: [CommentV2] @connection(keyName: "byPost", fields: ["id"])
}

```

3.  `amplify push`
