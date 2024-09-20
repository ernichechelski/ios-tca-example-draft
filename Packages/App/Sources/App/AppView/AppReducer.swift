//
//  AppReducer.swift
//  
//
//  Created by Ernest Chechelski on 29/03/2024.
//

import ComposableArchitecture

@Reducer
struct AppReducer {
    @Reducer
    struct Path {
        @ObservableState
        enum State {
            case items(ItemsReducer.State)
            case addItem(PlaceholderReducer.State)
            case detailItem(ItemReducer.State)
            case editItem(PlaceholderReducer.State)
        }

        enum Action {
            case items(ItemsReducer.Action)
            case addItem(PlaceholderReducer.Action)
            case detailItem(ItemReducer.Action)
            case editItem(PlaceholderReducer.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: \.items, action: \.items) {
                ItemsReducer()
            }
            Scope(state: \.addItem, action: \.addItem) {
                PlaceholderReducer()
            }
            Scope(state: \.detailItem, action: \.detailItem) {
                ItemReducer()
            }
            Scope(state: \.editItem, action: \.editItem) {
                PlaceholderReducer()
            }
        }
    }

    @ObservableState
    struct State {
        var path = StackState<Path.State>(
            [
                .items(.init())
            ]
        )

        var itemDelegate = ItemDelegateReducer.State()
    }

    enum Action {
        case path(StackAction<Path.State, Path.Action>)
        case itemDelegate(ItemDelegateReducer.Action)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .path(.element(id: id, action: .detailItem(.delegate(delegateAction)))):
                guard
                    case .detailItem = state.path[id: id]
                else {
                    return .none
                }
                return .send(.itemDelegate(.item(delegateAction)))

            case .path:
                return .none

            case .itemDelegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            Path()
        }

        Scope(state: \.itemDelegate, action: \.itemDelegate) {
            ItemDelegateReducer()
        }
    }
}

// MARK: AppReducer + ItemDelegateReducer, ItemReducer Delegate.
extension AppReducer {
    @Reducer
    struct ItemDelegateReducer {
        struct State: Equatable {}

        enum Action {
            case item(ItemReducer.Action.Delegate)
            case delegate(Delegate)
            enum Delegate {
                case popScreen
            }
        }

        var body: some Reducer<State, Action> {
            Reduce { state, action in
                switch action {
                case .item(let action):
                    switch action {
                    case .closeScreenRequested:
                        return .send(.delegate(.popScreen))
                    }
                case .delegate:
                    return .none
                }
            }
        }
    }
}
