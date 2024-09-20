//
//  File.swift
//  
//
//  Created by Ernest Chechelski on 29/03/2024.
//

import ComposableArchitecture

struct Filter {
    var isMovieIncluded: (LikedMovie) -> Bool
}

@Reducer
struct FiltersReducer {

    @ObservableState
    struct State: Equatable {
        var countries = [BoolFilter<Country>]()
        var genres = [BoolFilter<Category>]()
        var query = StringFilter<Movie>(id: 0, query: "")
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case onFinish
        case onCountriesFetched(TaskResult<[Country]>)
        case onGenresFetched(TaskResult<[Category]>)
        case filterCountriesTapped(BoolFilter<Country>)
        case filterGenresTapped(BoolFilter<Category>)
        case queryUpdated(StringFilter<Movie>)
        case delegate(Delegate)
        
        enum Delegate {
            case filtersUpdated
        }
    }

    @Dependency(\.moviesClient) var moviesClient

    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { @MainActor send in
                    let fetchCountriesResult = await TaskResult {
                        try await moviesClient.fetchCountries()
                    }
                    
                    let fetchCategoriesResult = await TaskResult {
                        try await moviesClient.fetchCategories()
                    }
                    
                    send(
                        .onCountriesFetched(
                            fetchCountriesResult
                        )
                    )

                    send(
                        .onGenresFetched(
                            fetchCategoriesResult
                        )
                    )

                    send(.onFinish)
                }
            case .onFinish:
                return .none
                
            case .onCountriesFetched(.success(let countries)):
                state.countries = countries.enumerated().map {
                    .init(id: $0.0, value: $0.1, isOn: false)
                }
                return .none
                
            case .onGenresFetched(.success(let categories)):
                state.genres = categories.enumerated().map {
                    .init(id: $0.1.id, value: $0.1, isOn: false)
                }
                return .none
                
            case .onCountriesFetched(.failure(_)):
                return .none
                
            case .onGenresFetched(.failure(_)):
                return .none
                
            case .filterCountriesTapped(_):
                return .none
                
            case .filterGenresTapped(let filter):
                state.genres[id: filter.id]?.isOn.toggle()
                return .send(.delegate(.filtersUpdated))
                
            case .binding(\.query.query):
                return .send(.delegate(.filtersUpdated))
        
            case .delegate:
                return .none
                
            case .binding:
                return .none

            case .queryUpdated(let query):
                state.query = query
                return .send(.delegate(.filtersUpdated))
            }
        }
    }
}

struct BoolFilter<Value: Equatable>: Identifiable, Equatable {
    var id: Int
    var value: Value
    var isOn: Bool
}

struct StringFilter<Value: Equatable>: Identifiable, Equatable {
    var id: Int
    var query: String
}

fileprivate extension Array where Element: Identifiable {
    subscript (id id: Element.ID) -> Element? {
        get {
            first { item in
                item.id == id
            }
        }
        set {
            guard 
                let index = firstIndex(where: { item in
                    item.id == id
                }),
                let newValue
            else {
                return
            }
            
            var array = self
            array[index] = newValue
            self = array
        }
    }
}
