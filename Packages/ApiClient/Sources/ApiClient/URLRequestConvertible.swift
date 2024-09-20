//
//  URLRequestConvertible.swift
//  IOS_BASE
//

import Foundation

public protocol URLRequestConvertible {
  /// Returns a `URLRequest` or throws if an `Error` was encountered.
  ///
  /// - Returns: A `URLRequest`.
  /// - Throws:  Any error thrown while constructing the `URLRequest`.
  func asURLRequest() throws -> URLRequest

  func path() throws -> String

  func method() throws -> HTTPMethod

  func headers() throws -> [String: String]

  func queryItems() throws -> [URLQueryItem]

  func body() throws -> Data

  func encoder() throws -> JSONEncoding

  func decoder() throws -> JSONDecoding

  func queryEncoder() -> JSONEncoding?

  func headerEncoder() -> JSONEncoding?
}

public enum URLRequestConvertibleError: Error {
  case ConvertingError(cause: String)
}

public extension URLRequestConvertible {
  func asURLRequest() throws -> URLRequest {
    var pathComponents = try URLComponents(
      string: try path()
    ).throwing(
      error: URLRequestConvertibleError.ConvertingError(
        cause: "components"
      )
    )
    let queryItems = try queryItems()
    pathComponents.queryItems = queryItems.isEmpty ? nil : queryItems
    var request = URLRequest(
      url: try pathComponents.url.throwing(
        error: URLRequestConvertibleError.ConvertingError(cause: "url")
      )
    )
    let method = try method()
    request.httpMethod = method.rawValue
    request.allHTTPHeaderFields = try headers()
    if method != .get {
      request.httpBody = try body()
    }
    return request
  }
}
