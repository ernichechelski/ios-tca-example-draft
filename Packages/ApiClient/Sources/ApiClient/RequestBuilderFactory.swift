//
//  RequestBuilderFactory.swift
//  IOS_BASE
//

import Foundation

public enum RequestBuilderFactory {
  // Returns new RequestBuilder with certain type. Recommended way to create RequestsBuilder without previous generic context.
  public static func create<T: RequestPerformerType>(_ type: T.Type) -> RequestBuilder<T, T.Request.Headers, T.Request.QueryItems, T.Request.Body> {
    RequestBuilder<T, T.Request.Headers, T.Request.QueryItems, T.Request.Body>()
  }
}
