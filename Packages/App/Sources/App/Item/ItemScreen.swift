//
//  ItemScreen.swift
//  
//
//  Created by Ernest Chechelski on 29/03/2024.
//

import ComposableArchitecture
import SwiftUI

struct ItemScreen: View {
    @State var store: StoreOf<ItemReducer>

    var body: some View {
        Form {
            HStack {
                TextField("Type here", text: $store.text)
            }
            Button(
                action: {
                    store.send(.delegate(.closeScreenRequested))
                },
                label: {
                    Text("Close")
                })
        }
        .navigationTitle("PlaceholderView")
    }
}
