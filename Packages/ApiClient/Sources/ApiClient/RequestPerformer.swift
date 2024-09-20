//
//  RequestPerformer.swift
//  IOS_BASE
//

import Combine
import Foundation

public protocol RequestPerformer {
  typealias ResponseResult = Result<URLSession.DataTaskPublisher.Output, Error>

  /// Returns publisher which triggers a URLRequest.
  func perform(
    request: URLRequest
  ) -> AnyPublisher<(data: Data, response: URLResponse), Error>

  /// Returns the publisher which allows triggering URLRequest later.
  func store(
    request: URLRequest
  ) -> Publishers.MakeConnectable<Publishers.Share<AnyPublisher<ResponseResult, Never>>>
}

// MARK: - URLSession default request performer.

public extension RequestPerformer {
  func perform(
    request: URLRequest
  ) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
    URLSession.shared
      .dataTaskPublisher(for: request)
      .mapError { $0 as Error }
      .eraseToAnyPublisher()
  }
}

public extension RequestPerformer {
  func store(
    request: URLRequest
  ) -> Publishers.MakeConnectable<Publishers.Share<AnyPublisher<ResponseResult, Never>>> {
    perform(request: request)
      .map { ResponseResult.success($0) }
      .catch { Just(ResponseResult.failure($0)).eraseToAnyPublisher() }
      .eraseToAnyPublisher()
      .share()
      .makeConnectable()
  }
}

extension URLSession: RequestPerformer {}
