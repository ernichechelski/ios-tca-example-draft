//
//  PlaceholderView.swift
//
//
//  Created by Ernest Chechelski on 29/03/2024.
//

import SwiftUI
import ComposableArchitecture

struct PlaceholderView: View {
    @State var store: StoreOf<PlaceholderReducer>

    var body: some View {
        Form {
            HStack {
                TextField("Type here", text: $store.text)
            }
        }
        .navigationTitle("PlaceholderView")
    }
}
