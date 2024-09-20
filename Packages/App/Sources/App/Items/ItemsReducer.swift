//
//  ItemsReducer.swift
//
//
//  Created by Ernest Chechelski on 29/03/2024.
//

import ComposableArchitecture

@Reducer
struct ItemsReducer {

    @ObservableState
    struct State {
        var isLoading: Bool = false
        var page = 0
        var moviesReducer = MoviesReducer.State()
        var filtersReducer = FiltersReducer.State()
        var filteredMovies = IdentifiedArrayOf<LikedMovie>()
    }

    enum Action: BindableAction {
        case onAppear
        case markAsFavourite(LikedMovie)
        case unmarkAsFavourite(LikedMovie)
        case onFinish
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case moviesReducer(MoviesReducer.Action)
        case filtersReducer(FiltersReducer.Action)
        case onDataUpdated

        enum Delegate {
            case closeScreenRequested
            case onMoviesUpdated
        }
    }

    @Dependency(\.moviesClient) private var moviesClient

    var body: some Reducer<State, Action> {
        BindingReducer()

        Scope(state: \.filtersReducer, action: \.filtersReducer) {
            FiltersReducer()
        }

        Scope(state: \.moviesReducer, action: \.moviesReducer) {
            MoviesReducer()
        }

        Reduce { state, action in
            switch action {
            case .markAsFavourite(let movie):
                return .send(
                    .moviesReducer(
                        .onMovieMarkedAsFavourite(movie)
                    )
                )

            case .unmarkAsFavourite(let movie):
                return .send(
                    .moviesReducer(
                        .onMovieUnmarkedAsFavourite(movie)
                    )
                )

            case .onAppear:
                state.isLoading = true
                return .run { @MainActor send in
                    send(
                        .moviesReducer(
                            .onFetchRequested
                        )
                    )

                    send(
                        .filtersReducer(
                            .onAppear
                        )
                    )

                    send(.onFinish)
                }

            case .onFinish:
                state.isLoading = false
                return .none
            case .moviesReducer(.delegate(.onMoviesUpdated)):
                return .send(.onDataUpdated)

            case .moviesReducer(_):
                return .none

            case .filtersReducer(.delegate(.filtersUpdated)):
                return .send(.onDataUpdated)

            case .filtersReducer(_):
                return .none

            case .onDataUpdated:
                let filtering = ORFiltering(
                    source: state.moviesReducer.likedMovies.elements,
                    factors: state.filtersReducer.genres.filter(\.isOn).filterFactors
                )
                
                let queryFiltering = ORFiltering(
                    source: filtering.result,
                    factors: [.init(stringFilter: state.filtersReducer.query)]
                )

                state.filteredMovies = IdentifiedArray(
                    uniqueElements: queryFiltering.result
                )
                return .none
                
            case .binding:
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

extension FilterFactor<LikedMovie> {
    init(boolFilter: BoolFilter<Category>) {
        isIncluded = { value in
            value.movie.categories.contains { category in
                boolFilter.isOn ? category.id == boolFilter.value.id : true
            }
        }
    }
    
    init(stringFilter: StringFilter<Movie>) {
        isIncluded = { value in
            if stringFilter.query.isEmpty {
                return true
            }
            return value.movie.title.contains(stringFilter.query)
        }
    }
}

extension Array where Element == BoolFilter<Category> {
    var filterFactors: [FilterFactor<LikedMovie>] {
        map { .init(boolFilter: $0) }
    }
}

struct ORFiltering<T> {
    let source: [T]
    let factors: [FilterFactor<T>]

    var result: [T] {
        guard !factors.isEmpty else {
            return source
        }

        return source.filter { item in
            factors.contains { factor in
                factor.isIncluded(item)
            }
        }
    }
}

struct FilterFactor<T> {
    var isIncluded: (T) -> Bool
}

struct ANDFiltering<T> {
    let source: [T]
    let factors: [FilterFactor<T>]

    var result: [T] {
        guard !factors.isEmpty else {
            return source
        }

        return source.filter { item in
            factors.allSatisfy { factor in
                factor.isIncluded(item)
            }
        }
    }
}
