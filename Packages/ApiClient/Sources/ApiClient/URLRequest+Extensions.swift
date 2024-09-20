//
//  URLRequest+Extensions.swift
//  IOS_BASE
//

import Foundation

public extension URLRequest {
  /// In debugger usage: `po print(request.curl())`
  func curl(pretty: Bool = false, cookies: [HTTPCookie] = []) -> String {
    var data: String = ""
    let complement = pretty ? "\\\n" : ""
    let method = "-X \(httpMethod ?? "GET") \(complement)"
    let url = "\"" + (self.url?.absoluteString ?? "") + "\""

    var header = ""

    if let httpHeaders = allHTTPHeaderFields?.sorted(by: { element1, element2 -> Bool in
      element1.key > element2.key
    }) {
      for (key, value) in httpHeaders {
        header += "-H \"\(key): \(value)\" \(complement)"
      }
    }
    if !cookies.isEmpty {
      let sortedCookies = cookies.sorted(by: { element1, element2 -> Bool in
        element1.name > element2.name
      })
      for value in sortedCookies {
        header += "-H \"Cookie: \(value.name)=\(value.value)\" \(complement)"
      }
    }

    if let bodyData = httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
      data = "-d \'\(bodyString)\' \(complement)"
    }

    let command = "curl -i " + complement + method + header + data + url

    return command
  }
}
