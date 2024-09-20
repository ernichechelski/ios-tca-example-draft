//
//  File.swift
//  
//
//  Created by Ernest Chechelski on 29/03/2024.
//

import ComposableArchitecture

@Reducer
struct PlaceholderReducer {

    @ObservableState
    struct State: Equatable {
        var text = ""
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
    }

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            }
        }
    }
}
