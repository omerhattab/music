//
//  APICaller.swift
//  Music
//
//  Created by btk-mac on 13.05.2022.
//

import Foundation

final class APICaller{
    static let shared = APICaller()
    
    private init(){}
    
    struct Contants {
        static let baseAPIURL = "https://api.spotify.com/v1"
    }
    
    enum APIError:Error{
        case failedToGetData
    }
    
    public func getCurrentUserProfile(completion: @escaping(Result<UserProfile,Error>)-> Void){
        createRequest(with: URL(string: Contants.baseAPIURL + "/me"), type: .GET) { (baseRequest) in
            let task = URLSession.shared.dataTask(with: baseRequest) { (data, _, error) in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do{
                    let result = try JSONDecoder().decode(UserProfile.self, from: data)
                    completion(.success(result))
                    print(result)
                }
                catch{
                    print(error.localizedDescription)
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    public func getNewsReleases(completion: @escaping((Result<NewReleaseResponse, Error>))-> Void){
        createRequest(with: URL(string: Contants.baseAPIURL + "/browse/new-releases?limit=50"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(NewReleaseResponse.self, from: data)
                    completion(.success(result))
                }
                catch{
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    public func getFeaturedPlayLists(completion:@escaping((Result<FeaturedPlaylistsResponse, Error>)-> Void)){
        createRequest(with: URL(string: Contants.baseAPIURL + "/browse/featured-playlists?limit=2"), type: .GET) { (request) in
            let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(FeaturedPlaylistsResponse.self, from: data)
                    print(result)
                    completion(.success(result))
                }
                catch{
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    public func getRecommendations(genres: Set<String>, completion: @escaping((Result<RecommendationsResponse, Error>) -> Void)){
        let seeds = genres.joined(separator: ",")
        createRequest(with: URL(string: Contants.baseAPIURL + "/recommendations?limit=40&seed_genres=\(seeds)"), type: .GET) { (request) in
            let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }

                do {
                    let result = try JSONDecoder().decode(RecommendationsResponse.self, from: data)
                    print(result)
                    completion(.success(result))
                }
                catch{
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    public func gerRecommendedGenres(completion: @escaping((Result<RecommendedGenresResponse, Error>) -> Void)){
        createRequest(with: URL(string: Contants.baseAPIURL + "/recommendations/available-genre-seeds"), type: .GET) { (request) in
            let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(RecommendedGenresResponse.self, from:data)
                    print(result)
                    completion(.success(result))
                }
                catch{
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    // MARK: - Private
    enum HTTPMethod: String {
        case GET
        case POST
    }
    
    private func createRequest(with url: URL?, type: HTTPMethod, completion: @escaping(URLRequest) -> Void){
        AutManager.shared.withValidToken { (token) in
            guard let apiURL = url else{ return }
            var request = URLRequest(url: apiURL)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpMethod = type.rawValue
            request.timeoutInterval = 30
            completion(request)
        }
    }
}
