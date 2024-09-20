//
//  Optional+Extensions.swift
//
//
//  Created by Ernest Chechelski on 12/12/2023.
//

import Foundation

public extension Optional {
  /// Throws error if no data required
  func throwing(error: Error = PackageError.development()) throws -> Wrapped {
    if let wrapped = self {
      return wrapped
    } else {
      throw error
    }
  }
}
