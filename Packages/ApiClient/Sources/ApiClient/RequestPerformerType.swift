//
//  RequestPerformerType.swift
//  IOS_BASE
//

import Foundation

public protocol RequestPerformerType {
  associatedtype Request: PerformerRequest
  associatedtype Response: PerformerResponse
}

public struct EmptyCodable: Codable {}

/// All requirements for type which wants to become a request.
public protocol PerformerRequest {
  var method: HTTPMethod? { get }
  var path: String? { get }
  var body: Body? { get }
  var headers: Headers? { get }
  var queryItems: QueryItems? { get }
  associatedtype Body: Encodable = EmptyCodable
  associatedtype Headers: Encodable = EmptyCodable
  associatedtype QueryItems: Encodable = EmptyCodable
}

public protocol PerformerResponse {
  associatedtype Body: Decodable = EmptyCodable
}

// MARK: - PerformerRequest instance defaults.

public extension PerformerRequest {
  var method: HTTPMethod? { .get }
  var path: String? { nil }
  var body: Body? { nil }
  var headers: Headers? { nil }
  var queryItems: QueryItems? { nil }
}

public extension PerformerRequest where Body == EmptyCodable {
  var body: Body? { EmptyCodable() }
}

public extension PerformerRequest where Headers == EmptyCodable {
  var headers: Headers? { EmptyCodable() }
}

public extension PerformerRequest where QueryItems == EmptyCodable {
  var queryItems: QueryItems? { EmptyCodable() }
}

public protocol SimpleEncodable {
  init()
}

public extension PerformerRequest where Body: SimpleEncodable {
  var body: Body? { Body() }
}

public extension PerformerRequest where Headers: SimpleEncodable {
  var headers: Headers? { Headers() }
}

public extension PerformerRequest where QueryItems: SimpleEncodable {
  var queryItems: QueryItems? { QueryItems() }
}
