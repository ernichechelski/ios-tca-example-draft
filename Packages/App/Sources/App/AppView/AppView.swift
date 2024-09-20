//
//  AppView.swift
//
//
//  Created by Ernest Chechelski on 29/03/2024.
//

import SwiftUI
import ComposableArchitecture

public struct AppView: View {
    public init() {}
    public var body: some View {
        AppReducerView(
            store: Store(initialState: AppReducer.State()) {
                AppReducer()
            }
        )
    }
}
