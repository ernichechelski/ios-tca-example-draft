//
//  RequestBuilder.swift
//  IOS_BASE
//

import Combine
import Foundation

public final class RequestBuilder<
  RequestPerformerAssociatedType: RequestPerformerType,
  Headers: Encodable,
  QueryItems: Encodable,
  Body: Encodable
>: URLRequestConvertible {
  static func withType(type: RequestPerformerAssociatedType.Type) -> RequestBuilder<
    RequestPerformerAssociatedType,
    RequestPerformerAssociatedType.Request.Headers,
    RequestPerformerAssociatedType.Request.QueryItems,
    RequestPerformerAssociatedType.Request.Body
  > {
    RequestBuilder<
      RequestPerformerAssociatedType,
      RequestPerformerAssociatedType.Request.Headers,
      RequestPerformerAssociatedType.Request.QueryItems,
      RequestPerformerAssociatedType.Request.Body
    >()
  }

  public typealias T = RequestPerformerAssociatedType

  public enum RequestBuilderError: Error {
    case missingArgument(text: String)
  }

  @ThrowingOptional(RequestBuilderError.missingArgument(text: "_method"))
  private var _method: HTTPMethod? = nil

  @ThrowingOptional(RequestBuilderError.missingArgument(text: "_path"))
  private var _path: String? = nil

  @ThrowingOptional(RequestBuilderError.missingArgument(text: "_headers"))
  private var _headers: Headers? = nil

  @ThrowingOptional(RequestBuilderError.missingArgument(text: "_queryItems"))
  private var _queryItems: QueryItems? = nil

  @ThrowingOptional(RequestBuilderError.missingArgument(text: "_body"))
  private var _body: Body? = nil

  @ThrowingOptional(RequestBuilderError.missingArgument(text: "_encoder"))
  private var _encoder: JSONEncoding? = JSONEncoder()

  private var _queryEncoder: JSONEncoding?

  private var _headersEncoder: JSONEncoding?

  @ThrowingOptional(RequestBuilderError.missingArgument(text: "_decoder"))
  private var _decoder: JSONDecoding? = JSONDecoder()
}

public struct ResponseContainer<T: Decodable> {
  public var data: T
  public var response: URLResponse
}

public extension RequestBuilder {
  /// Simplest way to propagate all parameters from request to builder.
  ///
  /// - parameter request: Custom request type to fill all parameters such body and path. Do not modify any values if nil.
  func request(
    _ request: RequestPerformerAssociatedType.Request
  ) -> Self where
    Body == RequestPerformerAssociatedType.Request.Body,
    QueryItems == RequestPerformerAssociatedType.Request.QueryItems,
    Headers == RequestPerformerAssociatedType.Request.Headers {
    _ = request.path.flatMap(path)
    _ = request.body.flatMap(body)
    _ = request.queryItems.flatMap(queryItems)
    _ = request.headers.flatMap(headers)
    _ = request.method.flatMap(method)
    return self
  }

  /// Sets the method of request.
  func method(_ method: HTTPMethod) -> Self {
    _method = method
    return self
  }

  /// Sets the path of request.
  func path(_ path: String) -> Self {
    _path = path
    return self
  }

  /// Sets the headers of request.
  func headers(_ headers: Headers) -> Self {
    _headers = headers
    return self
  }

  /// Sets the queryItems of request.
  func queryItems(_ queryItems: QueryItems) -> Self {
    _queryItems = queryItems
    return self
  }

  // Sets the body of request.
  func body(_ body: Body) -> Self {
    _body = body
    return self
  }

  /// Sets the encoder of request.
  func encoder(_ encoder: JSONEncoding) -> Self {
    _encoder = encoder
    return self
  }

  /// Sets the decoder of request.
  func decoder(_ decoder: JSONDecoding) -> Self {
    _decoder = decoder
    return self
  }

  /// Sets the encoder of query items.
  func queryEncoder(_ encoder: JSONEncoding) -> Self {
    _queryEncoder = encoder
    return self
  }

  /// Sets the encoder of header items.
  func headerEncoder(_ encoder: JSONEncoding) -> Self {
    _headersEncoder = encoder
    return self
  }
}

public extension RequestBuilder where T: RequestPerformerType {
  /// Recommended way to trigger a request build by RequestBuilder.
  /// Allows to not loose a type context and proceed with decoding response.
  ///
  /// - parameter with: Requests performer which is responsible for triggering the request.
  /// - parameter interrupt: Closure which gives as chance to modify builder before building request.
  func perform(
    with: RequestPerformer,
    interrupt: (RequestBuilder) throws -> (URLRequest) = { try $0.asURLRequest() }
  ) -> AnyPublisher<ResponseContainer<T.Response.Body>, Error> {
    Just(self)
      .tryMap { builder in
        (try interrupt(builder), try builder.decoder())
      }
      .flatMap { request, decoder in
        print("->", request.curl(), "<-", "Waiting")
        return with.perform(request: request)
          .tryMap {
            print(
                "->",
                request.curl(),
                "<-",
                $0.response,
                String(data: $0.data, encoding: .utf8),
                "Decoding to \(T.Response.Body.self)"
            )
            return ResponseContainer(
              data: try T.Response.Body.from(
                data: $0.data,
                decoder: decoder
              ),
              response: $0.response
            )
          }
          .eraseToAnyPublisher()
      }
      .mapError { error in
        print("->", "Error", error)
        return error
      }
      .eraseToAnyPublisher()
  }
}

public extension RequestBuilder {
  func path() throws -> String {
    try $_path.value()
  }

  func method() throws -> HTTPMethod {
    try $_method.value()
  }

  func headers() throws -> [String: String] {
    try $_headers.value().asHeaders(encoder: headerEncoder() ?? encoder())
  }

  func queryItems() throws -> [URLQueryItem] {
    try $_queryItems.value().asQueryItems(encoder: queryEncoder() ?? encoder())
  }

  func body() throws -> Data {
    if RequestPerformerAssociatedType.Request.Body.self == Data.self {
      return try (try $_body.value() as? Data).throwing()
    } else {
      return try $_body.value().asData(encoder: try encoder())
    }
  }

  func encoder() throws -> JSONEncoding {
    try $_encoder.value()
  }

  func decoder() throws -> JSONDecoding {
    try $_decoder.value()
  }

  func queryEncoder() -> JSONEncoding? {
    _queryEncoder
  }

  func headerEncoder() -> JSONEncoding? {
    _queryEncoder
  }
}

// MARK: - RequestBuilder with empty body.

public extension RequestBuilder where Body == EmptyCodable {
  func body() throws -> Data {
    try EmptyCodable().asData()
  }
}

// MARK: - RequestBuilder with empty headers.

public extension RequestBuilder where Headers == EmptyCodable {
  func headers() throws -> [String: String] {
    [String: String]()
  }
}

// MARK: - RequestBuilder with empty query items.

public extension RequestBuilder where QueryItems == EmptyCodable {
  func queryItems() throws -> [URLQueryItem] {
    []
  }
}

// MARK: - Encoding parameters

private extension Encodable {
  func asQueryItems(encoder: JSONEncoding = JSONEncoder()) throws -> [URLQueryItem] {
    try dictionary(encoder: encoder).compactMap { key, value in
      guard !key.isEmpty else {
        return nil
      }
      return URLQueryItem(name: key, value: "\(value)")
    }
  }

  func asHeaders(encoder: JSONEncoding = JSONEncoder()) throws -> [String: String] {
    try dictionary(encoder: encoder).mapValues { "\($0)" }
  }
}

extension URLRequestConvertible where Self: PerformerRequest {
  func path() throws -> String {
    try path.throwing()
  }

  func method() throws -> HTTPMethod {
    try method.throwing()
  }

  func headers() throws -> [String: String] {
    try headers.throwing().asHeaders(encoder: try encoder())
  }

  func queryItems() throws -> [URLQueryItem] {
    try queryItems.throwing().asQueryItems(encoder: try encoder())
  }

  func body() throws -> Data {
    try body.throwing().asData(encoder: try encoder())
  }

  func encoder() throws -> JSONEncoding {
    JSONEncoder()
  }

  func decoder() throws -> JSONDecoding {
    JSONDecoder()
  }
}

@propertyWrapper struct ThrowingOptional<T> {
  var wrappedValue: T?

  let error: Error

  init(wrappedValue: T?, _ error: Error) {
    self.wrappedValue = wrappedValue
    self.error = error
  }

  var projectedValue: Self {
    self
  }

  func value() throws -> T {
    if let empty = EmptyCodable() as? T {
      return empty
    }
    return try wrappedValue.throwing(error: error)
  }
}
