//
//  Codable+JSON.swift
//
//
//

import Foundation

enum AppCodableError: LocalizedError {
  case cannotEncodeData
  case cannotEncodeString
  case cannotCast(object: Any)

  var errorDescription: String? {
    switch self {
    case .cannotEncodeData: return "Cannot create data from string"
    case .cannotEncodeString: return "Cannot create string from data"
    case let .cannotCast(object): return "Cannot cast object \(object)"
    }
  }
}

public extension Encodable {
  /// - Returns: Json string from encodable using default encoder.
  func asJSON(encoder: JSONEncoding = JSONEncoder()) throws -> String {
    let data = try encoder.encode(self)
    let result = try String(data: data, encoding: .utf8)
      .throwing(error: AppCodableError.cannotEncodeString)
    return result
  }

  /// - Returns: Default json string from encodable as data.
  func asData(encoder: JSONEncoding = JSONEncoder()) throws -> Data {
    let result = try asJSON(encoder: encoder)
      .data(using: .utf8)
      .throwing(error: AppCodableError.cannotEncodeData)
    return result
  }
}

public enum DecodableError: LocalizedError {
  case cannotEncodeData
  case cannotEncodeString

  public var errorDescription: String? {
    switch self {
    case .cannotEncodeData: return "Cannot create data from string"
    case .cannotEncodeString: return "Cannot create string from data"
    }
  }
}

public protocol JSONDecoding {
  func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable
}

public protocol JSONEncoding {
  func encode<T>(_ value: T) throws -> Data where T: Encodable
}

extension JSONDecoder: JSONDecoding {}

extension JSONEncoder: JSONEncoding {}

public extension Decodable {
  ///
  /// Tries to parse json string and make instance of decodable.
  ///
  /// - Parameters:
  ///   - jsonString: string in json format with all required properties.
  /// - Returns: new instance of decodable based on provided json string.
  static func from(jsonString: String, decoder: JSONDecoding = JSONDecoder()) throws -> Self {
    let data = try jsonString.data(using: .utf8)
      .throwing(error: AppCodableError.cannotEncodeData)
    return try decoder.decode(Self.self, from: data)
  }

  ///
  /// Tries to parse dictionary and make instance of decodable.
  ///
  /// - Parameters:
  ///   - dictionary: dictionary which matches decoded object.
  /// - Returns: new instance of decodable based on provided dictionary.
  static func from(dictionary: [AnyHashable: Any], decoder: JSONDecoding = JSONDecoder()) throws -> Self {
    try from(jsonString: dictionary.asJson(), decoder: decoder)
  }

  ///
  /// Tries to parse data which contains json string and make instance of decodable.
  ///
  /// - Parameters:
  ///   - data: data with string in json format with all required properties.
  /// - Returns: new instance of decodable based on provided data.
  static func from(data: Data, decoder: JSONDecoding = JSONDecoder()) throws -> Self {
    let string = try String(data: data, encoding: .utf8)
      .throwing(error: AppCodableError.cannotEncodeString)
    return try Self.from(jsonString: string, decoder: decoder)
  }

  static func empty() throws -> Self { try from(jsonString: "{}") }
}

public extension Encodable {
  // Produces dictionary from encodable
  func dictionary(encoder: JSONEncoding = JSONEncoder()) throws -> [String: Any] {
    let fragmentedObject = try fragmentedObject(encoder: encoder)
    guard let result = fragmentedObject as? [String: Any] else {
      throw AppCodableError.cannotCast(object: fragmentedObject)
    }
    return result
  }

  // Produces dictionary from encodable
  func stringDictionary(encoder: JSONEncoding = JSONEncoder()) throws -> [String: String] {
    if let result = try fragmentedObject(encoder: encoder) as? [String: String] {
      return result
    }
    if let result = try fragmentedObject(encoder: encoder) as? [String: Any] {
      return result.mapValues { "\($0)" }
    }
    throw AppCodableError.cannotCast(object: fragmentedObject)
  }

  private func fragmentedObject(encoder: JSONEncoding = JSONEncoder()) throws -> Any {
    let data = try encoder.encode(self)
    let fragmentedObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
    return fragmentedObject
  }
}

public extension Dictionary {
  /// Returns json from the dictionary.
  func asJson() throws -> String {
    let data = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
    return try String(data: data, encoding: .utf8)
      .throwing(error: AppCodableError.cannotEncodeString)
  }
}
