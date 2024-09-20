//
//  PackageError.swift
//  IOS_BASE
//

import Foundation

enum PackageConstants {
    static var packageDebugMode = false
}

public enum PackageError: LocalizedError {
    case development(file: String = #file, line: UInt = #line)
    case arc
    case noData
    case operationCanceled

    public var errorDescription: String? {
        switch self {
        case .arc: return "Memory allocation error"
        case let .development(file, line):
            if PackageConstants.packageDebugMode {
                return "Development error at \(file), \(line)"
            } else {
                return "Development error"
            }
        case .noData: return "Required data not found"
        case .operationCanceled: return "Operation canceled"
        }
    }

    public var recoverySuggestion: String? {
        "Contact support"
    }
}
