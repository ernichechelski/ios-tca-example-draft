//
//  File.swift
//  
//
//  Created by Ernest Chechelski on 29/03/2024.
//

import SwiftUI
import ComposableArchitecture

struct ItemsScreen: View {
    @Perception.Bindable var store: StoreOf<ItemsReducer>

    var body: some View {
        WithPerceptionTracking {
            List {
                ForEach(store.filteredMovies) { movie in
                    MovieCell(
                        title: movie.movie.title,
                        isLiked: movie.isFavourite
                    ) {
                        store.send(
                            movie.isFavourite ?
                                .unmarkAsFavourite(movie) :
                                .markAsFavourite(movie)
                        )
                    }
                }
            }
            .animation(.default, value: store.filteredMovies)
            .listStyle(.grouped)
            .safeAreaInset(edge: .bottom) {
                GenresFiltersView(
                    filters: store.filtersReducer.genres
                ) { event in
                    switch event {
                    case .onFilterTapped(let filter):
                        store.send(
                            .filtersReducer(
                                .filterGenresTapped(filter)
                            )
                        )
                    }
                }
                .background(Color.white)
            }
            .searchable(text: $store.filtersReducer.query.sending(\.filtersReducer.queryUpdated).query)
            .refreshable {
                await store.send(.onAppear).finish()
            }
            .onAppear(perform: {
                store.send(.onAppear)
            })
            .navigationTitle("PlaceholderView")
        }
    }

    struct MovieCell: View {
        let title: String
        let isLiked: Bool
        let onTap: () -> Void

        var body: some View {
            GroupBox {
                Button {
                    onTap()
                } label: {
                    isLiked ? Text("Mark as unfavourite") : Text("Mark as favourite")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } label: {
                Text(title)
            }
            .padding([.horizontal, .bottom], 30)
        }
    }
    
    struct GenresFiltersView: View  {
        
        enum Event {
            case onFilterTapped(BoolFilter<Category>)
        }
        
        let filters: [BoolFilter<Category>]
        let onEvent: (Event) -> Void
        
        struct FilterCell: View {
            let text: String
            
            var body: some View {
                Text(text)
            }
        }
        
        var body: some View {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(filters) { filter in
                        Button {
                            onEvent(.onFilterTapped(filter))
                        } label: {
                            Text(filter.value.englishName)
                        }
                        .foregroundStyle(filter.isOn ? .green : .red)
                        .buttonStyle(BorderedProminentButtonStyle())
                    }
                }
                .padding(10)
            }
        }
    }
}
