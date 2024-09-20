// The Swift Programming Language
// https://docs.swift.org/swift-book

import ComposableArchitecture
import SwiftUI

// TODO:
// - Grid of items.
// - When the user taps search bar we show "Fill search to see propositions"
// - Categories horizontal section.
// - Recommended items horizontal section.
// - Liked items horizontal section.
// - Grid of liked items.
// - Grid of liked searches.
// - Example analitycs.
// - Separate package with https://wojciechkulik.pl/ios/redux-architecture-and-mind-blowing-features

struct AppReducerView: View {
    @Perception.Bindable var store: StoreOf<AppReducer>

    var body: some View {
        WithPerceptionTracking {
            NavigationStack(
                path: $store.scope(state: \.path, action: \.path)
            ) {
                Text("Landing Page")
            } destination: { store in
                switch store.state {
                case .items:
                    if let store = store.scope(state: \.items, action: \.items) {
                        ItemsScreen(store: store)
                    }
                case .addItem:
                    if let store = store.scope(state: \.addItem, action: \.addItem) {
                        PlaceholderView(store: store)
                    }
                case .detailItem:
                    if let store = store.scope(state: \.detailItem, action: \.detailItem) {
                        ItemScreen(store: store)
                    }
                case .editItem:
                    if let store = store.scope(state: \.editItem, action: \.editItem) {
                        PlaceholderView(store: store)
                    }
                }
            }
        }
    }
}

#Preview {
    AppReducerView(
        store: Store(initialState: AppReducer.State()) {
            AppReducer()
        }
    )
}

struct UserQuery {
    let text: String
    let country: Country
}

enum Filters {
    struct NameFilter {
        let text: String
    }

    struct VoteFilter {
        let max: Double
        let min: Double
    }

    struct CategoryFilter {
        let included: Category
    }
}

protocol FilterPredicate {
    associatedtype Element
    func isIncluded(_ element: Element) -> Bool

}

extension Filters.NameFilter: FilterPredicate {

    func isIncluded(_ movie: Movie) -> Bool {
        movie.title.contains(text)
    }
}

struct FilterForm<FilterPredicate> {
    var isOn: Bool
    var description: Localisalble
}

protocol Localisalble {
    var value: String { get }
    var description: String { get }
}

enum Localisables {

}
