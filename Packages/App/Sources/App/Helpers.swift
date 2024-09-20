//
//  Helpers.swift
//
//
//  Created by Ernest Chechelski on 19/03/2024.
//

import ApiClient
import Combine
import Dependencies
import Foundation
import UIKit

// MARK: - Movies API Schema

enum Movies {
	struct GetMovies: RequestPerformerType {
		struct Request: PerformerRequest, MoviesRequest {
			var subpath: String? { "/3/movie/now_playing" }

			struct QueryItems: Encodable {
				let page: Int
				let language: String
			}

			struct Headers: Encodable {
				let authorisation: String
				let accept = "application/json"

				enum CodingKeys: String, CodingKey {
					case authorisation = "Authorization"
					case accept
				}
			}
		}

		struct Response: PerformerResponse {
			struct Body: Decodable {
				let dates: Dates
				let page: Int
				let results: [Movie]
				let totalPages, totalResults: Int

				enum CodingKeys: String, CodingKey {
					case dates, page, results
					case totalPages = "total_pages"
					case totalResults = "total_results"
				}

				struct Dates: Codable {
					let maximum, minimum: String
				}

				struct Movie: Codable {
					let adult: Bool
					let backdropPath: String?
					let genreIDS: [Int]
					let id: Int
					let originalLanguage: String
					let originalTitle, overview: String
					let popularity: Double
					let posterPath: String?
					let releaseDate, title: String
					let video: Bool
					let voteAverage: Double
					let voteCount: Int

					enum CodingKeys: String, CodingKey {
						case adult
						case backdropPath = "backdrop_path"
						case genreIDS = "genre_ids"
						case id
						case originalLanguage = "original_language"
						case originalTitle = "original_title"
						case overview, popularity
						case posterPath = "poster_path"
						case releaseDate = "release_date"
						case title, video
						case voteAverage = "vote_average"
						case voteCount = "vote_count"
					}
				}
			}
		}
	}

	struct GetMovieSearchSuggestionsMovies: RequestPerformerType {
		struct Request: PerformerRequest, MoviesRequest {
			var subpath: String? { "/3/search/movie" }

			struct QueryItems: Encodable {
				let query: String
				let page: Int
				let language: String
			}

			typealias Headers = GetMovies.Request.Headers
		}

		struct Response: PerformerResponse {
			struct Body: Decodable {
				let page: Int
				let results: [Movie]
				let totalPages, totalResults: Int

				enum CodingKeys: String, CodingKey {
					case page, results
					case totalPages = "total_pages"
					case totalResults = "total_results"
				}

				struct Movie: Codable {
					let originalTitle: String

					enum CodingKeys: String, CodingKey {
						case originalTitle = "original_title"
					}
				}
			}
		}
	}

	struct GetCountries: RequestPerformerType {
		struct Request: PerformerRequest, MoviesRequest {
			var subpath: String? { "/3/configuration/countries" }
            typealias Headers = GetMovies.Request.Headers
		}

		struct Response: PerformerResponse {
			struct Country: Decodable {
				var iso_3166_1: String
				var english_name: String
				var native_name: String

				enum CodingKeys: String, CodingKey {
					case iso_3166_1 = "iso_3166_1"
					case english_name = "english_name"
					case native_name = "native_name"
				}
			}

			typealias Body = [Country]
		}
	}
    
    struct GetCategories: RequestPerformerType {
        struct Request: PerformerRequest, MoviesRequest {
            var subpath: String? { "/3/genre/movie/list" }
            typealias Headers = GetMovies.Request.Headers
        }

        struct Response: PerformerResponse {
            struct Category: Decodable {
                var id: Int
                var name: String
            }
            
            struct Body: Decodable {
                var genres: [Category]
            }
        }
    }
}

// MARK: Common for whole schema.

protocol MoviesRequest {
	var basePath: String { get }
	var subpath: String? { get }
}

extension MoviesRequest where Self: PerformerRequest {
	var basePath: String { MoviesDBConstants.baseApiPath }
	var path: String? { basePath + (subpath ?? "") }
}

enum MoviesDBConstants {
	static let baseApiPath = "https://api.themoviedb.org"
	static let basePostersPath = "https://image.tmdb.org/t/p/original"
}

extension Movies.GetMovies.Request.Headers {
	init(token: String) {
		self.init(authorisation: "Authorization: Bearer \(token)")
	}
}

// MARK: AppModel

struct Movie: Identifiable, Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    let id: Int
	let title: String
	let image: ImageResource
	let releseDate: Date
	let grade: Float
	let overview: String
    let categories: [LazyCategory]
    
    struct LazyCategory {
        var id: Int
    }
}

struct Country: Equatable {
    var id: String
    var englishName: String
    var nativeName: String
}

struct Category: Equatable {
    var id: Int
    var englishName: String
}


struct MovieSearchSuggestion: Equatable {
	let text: String
}

protocol ImageResource {
	var uiImage: AnyPublisher<UIImage, Error> { get }
}

protocol MovieDBMoviesRepository {
    func fetchCountries() -> AnyPublisher<Movies.GetCountries.Response.Body, Error>
    func fetchCategories() -> AnyPublisher<Movies.GetCategories.Response.Body, Error>
	func fetchMovies(page: Int) -> AnyPublisher<Movies.GetMovies.Response.Body, Error>
	func fetchSearchSuggestions(text: String) -> AnyPublisher<[MovieSearchSuggestion], Error>
    func fetchImage(path: String) -> any ImageResource
}

struct MovieDBMoviesImageResource: ImageResource {
	let uiImage: AnyPublisher<UIImage, Error>
}

struct MoviesClient {
    var markAsFavouirite: (Int) async throws -> Void
    var unmarkAsFavouirite: (Int) async throws -> Void
	var fetchMovies: (Int) async throws -> [Movie]
    var fetchCountries: () async throws -> [Country]
    var fetchCategories: () async throws -> [Category]
    var fetchLikedMovies: () async throws -> [Int]
}

import ComposableArchitecture

struct LikedMovie: Identifiable, Equatable {
    var id: Int {
        movie.id
    }
    
    var movie: Movie
    var isFavourite: Bool
}

@Reducer
struct MoviesReducer { 
    struct State {
        var movies = IdentifiedArrayOf<Movie>()
        var likedMovies = IdentifiedArrayOf<LikedMovie>()
        var likedIds = [Int]()
    }
    
    enum Action {
        case onMovieMarkedAsFavourite(LikedMovie)
        case onMovieUnmarkedAsFavourite(LikedMovie)
        case onMergeStateChanged
        case onMoviesFetched(TaskResult<[Movie]>, TaskResult<[Int]>)
        case onLikedFetched(TaskResult<[Int]>)
        case onFetchRequested
        case delegate(Delegate)
        
        enum Delegate {
            case onMoviesUpdated
        }
    }
    
    @Dependency(\.moviesClient) var moviesClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onMovieMarkedAsFavourite(let movie):
                return .run { @MainActor send in
                    try await moviesClient.markAsFavouirite(movie.id)
                    
                    await send(
                        .onLikedFetched(
                            TaskResult {
                                try await moviesClient.fetchLikedMovies()
                            }
                        )
                    )
        
                    send(.onMergeStateChanged)
                }
                
            case .onMovieUnmarkedAsFavourite(let movie):
                return .run { @MainActor send in
                    try await moviesClient.unmarkAsFavouirite(movie.id)
                    
                    await send(
                        .onLikedFetched(
                            TaskResult {
                                try await moviesClient.fetchLikedMovies()
                            }
                        )
                    )
        
                    send(.onMergeStateChanged)
                }
                
            case .onFetchRequested:
                return .run { @MainActor send in
                    let moviesTask = await TaskResult {
                        try await moviesClient.fetchMovies(1)
                    }
                    
                    let likedTask = await TaskResult {
                        try await moviesClient.fetchLikedMovies()
                    }
                    
                    send(
                        .onMoviesFetched(
                            moviesTask, likedTask
                        )
                    )
                }
                
            case .onMoviesFetched(.success(let movies), .success(let ids)):
                state.likedIds = ids
                state.movies = IdentifiedArrayOf<Movie>(
                    uniqueElements: movies
                )
                return .send(.onMergeStateChanged)
                
            case .onMoviesFetched:
                return .none
                
            case .onMergeStateChanged:
                state.likedMovies = IdentifiedArrayOf<LikedMovie>(
                    uniqueElements: state.movies.elements.map {
                        LikedMovie(
                            movie: $0,
                            isFavourite: state.likedIds.contains($0.id)
                        )
                    }
                )
                return .send(.delegate(.onMoviesUpdated))
                
            case .onLikedFetched(.success(let ids)):
                state.likedIds = ids
                return .send(.onMergeStateChanged)
                
            case .onLikedFetched:
                return .none
                
            case .delegate(_):
                return .none
            }
        }
    }
}



extension MoviesClient: DependencyKey {
    private static let repository: MoviesListRepository = RealMoviesListRepository(
        moviesRepository: RealMovieDBMoviesRepository(),
        likedRepository: UserDefaultsLikedListRepository()
    )
    
    static var liveValue: MoviesClient = {
        Self { [repository] id in
            try await repository
                .markAsFavourite(movieId: id)
                .async()
        } unmarkAsFavouirite: { id in
            try await repository
                .unmarkAsFavourite(movieId: id)
                .async()
        } fetchMovies: { [repository] page in
            try await repository
                .fetchMovies(page: page)
                .async()
        } fetchCountries: { [repository] in
            try await repository
                .fetchCountries()
                .async()
        } fetchCategories: { [repository] in
            try await repository
                .fetchCategories()
                .async()
        } fetchLikedMovies: {
            try await repository
                .fetchLikedIds()
                .async()
        }
    }()
}

extension DependencyValues {
	var moviesClient: MoviesClient {
		get { self[MoviesClient.self] }
		set { self[MoviesClient.self] = newValue }
	}
}

struct RealMovieDBMoviesRepository: MovieDBMoviesRepository {
    func fetchCategories() -> AnyPublisher<Movies.GetCategories.Response.Body, Error> {
        RequestBuilderFactory
            .create(Movies.GetCategories.self)
            .request(.init())
            .headers(.init(token: Constants.apiKey))
            .perform(with: URLSession.shared)
            .map { response in
                response.data
            }
            .eraseToAnyPublisher()
    }
    
    func fetchCountries() -> AnyPublisher<Movies.GetCountries.Response.Body, Error> {
        RequestBuilderFactory
            .create(Movies.GetCountries.self)
            .request(.init())
            .headers(.init(token: Constants.apiKey))
            .perform(with: URLSession.shared)
            .map { response in
                response.data
            }
            .eraseToAnyPublisher()
    }

	func fetchImage(path: String) -> ImageResource {
		/// There is no authentication layer here, so just Data(contentsOf:) initialiser is sufficient here.
		MovieDBMoviesImageResource(
			uiImage:
				Just(path)
				.tryMap {
					try Data(
						contentsOf: URL(
							string: MoviesDBConstants.basePostersPath + $0
						)
						.throwing()
					)
				}
				.tryMap {
					try UIImage(data: $0)
						.throwing()
				}
				.eraseToAnyPublisher()
		)
	}

	func fetchSearchSuggestions(text: String) -> AnyPublisher<[MovieSearchSuggestion], Error> {
		RequestBuilderFactory
			.create(Movies.GetMovieSearchSuggestionsMovies.self)
			.request(.init())
			.headers(.init(token: Constants.apiKey))
			.queryItems(
				.init(
					query: text,
					page: 1,
					language: Constants.locale
				)
			)
			.perform(with: URLSession.shared)
			.map {
				$0.data.results.map {
					.init(text: $0.originalTitle)
				}
			}
			.eraseToAnyPublisher()
	}

	func fetchMovies(page: Int) -> AnyPublisher<Movies.GetMovies.Response.Body, Error> {
		RequestBuilderFactory
			.create(Movies.GetMovies.self)
			.request(.init())
			.headers(.init(token: Constants.apiKey))
			.queryItems(
				.init(
					page: page,
					language: Constants.locale
				)
			)
			.perform(with: URLSession.shared)
			.map { $0.data }
			.eraseToAnyPublisher()
	}

	public init() {}
}

import AppSecrets

private enum Constants {
	static let locale = "en"
    static let apiKey = AppSecrets().key
}

enum AsyncError: Error {
	case finishedWithoutValue
}

extension AnyPublisher {
	func async() async throws -> Output {
		try await withCheckedThrowingContinuation { continuation in
			var cancellable: AnyCancellable?
			var finishedWithoutValue = true
			cancellable = first()
				.sink { result in
					switch result {
					case .finished:
						if finishedWithoutValue {
							continuation.resume(throwing: AsyncError.finishedWithoutValue)
						}
					case let .failure(error):
						continuation.resume(throwing: error)
					}
					cancellable?.cancel()
				} receiveValue: { value in
					finishedWithoutValue = false
					continuation.resume(with: .success(value))
				}
		}
	}

	func asyncOptional() async -> Output? where Failure == Never {
		await withCheckedContinuation { continuation in
			var cancellable: AnyCancellable?
			var finishedWithoutValue = true
			cancellable = first()
				.sink { result in
					switch result {
					case .finished:
						if finishedWithoutValue {
							continuation.resume(returning: nil)
						}
					case let .failure(error):
						continuation.resume(throwing: error)
					}
					cancellable?.cancel()
				} receiveValue: { value in
					finishedWithoutValue = false
					continuation.resume(with: .success(value))
				}
		}
	}

	func async() async -> Output where Failure == Never {
		await withCheckedContinuation { continuation in
			var cancellable: AnyCancellable?
			cancellable = first()
				.sink { result in
					switch result {
					case .finished:
						assertionFailure("Finished without value")
					case let .failure(error):
						continuation.resume(throwing: error)
					}
					cancellable?.cancel()
				} receiveValue: { value in
					continuation.resume(with: .success(value))
				}
		}
	}
    
    func asyncStream() -> AsyncThrowingStream<Output, Error> {
        AsyncThrowingStream { continuation in
                // Subscribe to publisher &
                // Store a reference to the cancellable to cancel it when continuation finishes
                let cancellable = self
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.finish()
                    case .failure(let error):
                        continuation.finish(throwing: error)
                    }
                   
                }, receiveValue: { output in
                    continuation.yield(output)
                })
                // Any combine methods you please go here
                  
                continuation.onTermination = { termination in
                    switch termination {
                    case .finished:
                        Swift.print("Stream finished.")
                    case .cancelled:
                        Swift.print("Stream cancelled.")
                    @unknown default:
                        fatalError()
                    }
                    // Cancel subscriber
                    cancellable.cancel()
                }
            }
        }
    
}

protocol MoviesListRepository {
    func markAsFavourite(movieId: Int) -> AnyPublisher<Void, Error>
    func unmarkAsFavourite(movieId: Int) -> AnyPublisher<Void, Error>
    
    func fetchLikedIds() -> AnyPublisher<[Int], Error>
    
	func fetchMovies(page: Int) -> AnyPublisher<[Movie], Error>
    func fetchCountries() -> AnyPublisher<[Country], Error>
    func fetchCategories() -> AnyPublisher<[Category], Error>
}


protocol LikedListRepository {
    func fetchLikedMoviesIds() -> AnyPublisher<[Int], Error>
    func markAsLikedMovie(id: Int) -> AnyPublisher<Void, Error>
    func unmarkAsLikedMovie(id: Int) -> AnyPublisher<Void, Error>
}

final class UserDefaultsLikedListRepository: LikedListRepository {
    
    let subject = CurrentValueSubject<Set<Int>, Never>(.init())
    
    func fetchLikedMoviesIds() -> AnyPublisher<[Int], Error> {
        subject
            .setFailureType(to: Error.self)
            .map {
                $0.sorted()
            }
            .eraseToAnyPublisher()
    }
    
    func markAsLikedMovie(id: Int) -> AnyPublisher<Void, Error> {
        Just(())
            .setFailureType(to: Error.self)
            .handleEvents(receiveOutput: { [weak self, id] _ in
                self?.subject.value.insert(id)
            })
            .eraseToAnyPublisher()
    }
    
    func unmarkAsLikedMovie(id: Int) -> AnyPublisher<Void, Error> {
        Just(())
            .setFailureType(to: Error.self)
            .handleEvents(receiveOutput: { [weak self, id] _ in
                self?.subject.value.remove(id)
            })
            .eraseToAnyPublisher()
    }
}

final class RealMoviesListRepository: MoviesListRepository {
	private enum Failure: Error {
		case wrongDateFormat
	}

	private let modelSubject = CurrentValueSubject<[Int: Movies.GetMovies.Response.Body], Never>([:])
	private let moviesRepository: MovieDBMoviesRepository
    private let likedRepository: LikedListRepository

	init(
        moviesRepository: MovieDBMoviesRepository,
        likedRepository: LikedListRepository
	) {
		self.moviesRepository = moviesRepository
        self.likedRepository = likedRepository
	}
    
    func fetchLikedIds() -> AnyPublisher<[Int], Error> {
        likedRepository.fetchLikedMoviesIds()
    }
    
    func markAsFavourite(movieId: Int) -> AnyPublisher<Void, Error> {
        likedRepository.markAsLikedMovie(id: movieId)
    }
    
    func unmarkAsFavourite(movieId: Int) -> AnyPublisher<Void, Error> {
        likedRepository.unmarkAsLikedMovie(id: movieId)
    }
    
    func fetchCountries() -> AnyPublisher<[Country], Error> {
        moviesRepository
            .fetchCountries()
            .map { countries in
                countries.map {
                    Country(
                        id: $0.iso_3166_1,
                        englishName: $0.english_name,
                        nativeName: $0.native_name
                    )
                }
            }
            .eraseToAnyPublisher()
    }

	func fetchMovies(page: Int) -> AnyPublisher<[Movie], Error> {
		moviesRepository
			.fetchMovies(page: page)
			.tryMap { [weak self] movies in
				guard let self else {
					return []
				}
				return try movies.results.map {
					Movie(
						id: $0.id,
						title: $0.originalTitle,
						image: self.moviesRepository
							.fetchImage(
								path: $0.posterPath ?? $0.backdropPath ?? ""
							),
						releseDate: try RealMoviesListRepositoryConstants.moviesDBDateFormatter.date(
							from: $0.releaseDate
						).throwing(error: Failure.wrongDateFormat),
						grade: Float($0.voteAverage),
						overview: $0.overview,
                        categories: $0.genreIDS.map {
                            Movie.LazyCategory(id: $0)
                        }
					)
				}
			}
			.eraseToAnyPublisher()
	}
    
    func fetchCategories() -> AnyPublisher<[Category], Error> {
        moviesRepository
            .fetchCategories()
            .map { countries in
                countries.genres.map {
                    Category(
                        id: $0.id,
                        englishName: $0.name
                    )
                }
            }
            .eraseToAnyPublisher()
    }
}

private enum RealMoviesListRepositoryConstants {
	static let moviesDBDateFormatter = with(DateFormatter()) {
		$0.dateFormat = "YYYY-mm-dd"
	}
}

/// Creates value and runs given block on it, then returns it.
/// Useful when creating new variables with configuration, to avoid
/// introducing temporary variables.
///
/// - Parameters:
///   - target: Target object
///   - block: Method to be run on target object
@inline(__always) func with<T>(_ target: T, block: (T) -> Void) -> T {
	block(target)
	return target
}

@inline(__always) func with<T>(_ target: T, block: () -> Void) -> T {
	block()
	return target
}

actor AnyPublisherNotifier<Output> {
    let subject: AnyPublisher<Output, Never>
    
    private var cancellables: [UUID: AnyCancellable] = [:]
    
    init(subject: AnyPublisher<Output, Never>) {
        self.subject = subject
    }
    
    func values() -> AsyncStream<Output> {
        AsyncStream { continuation in
            let id = UUID()

            cancellables[id] = subject.sink { _ in
                continuation.finish()
            } receiveValue: { value in
                continuation.yield(value)
            }

            continuation.onTermination = { _ in
                Task { await self.cancel(id) }
            }
        }
    }
}

private extension AnyPublisherNotifier {
    func cancel(_ id: UUID) {
        cancellables[id] = nil
    }
}
