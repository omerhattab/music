//
//  AuthManager.swift
//  Music
//
//  Created by btk-mac on 13.05.2022.
//

import Foundation

final class AutManager{
    static let shared = AutManager()
    private var refreshingToken = false
    
    struct Constans {
        static let clientID = "3b9ac3129cf24aacadcd7af43f9e7bec"
        static let clientSecret = "2430895cc1be4b6e91320e128cccc6dc"
        static let tokenAPIURL = "https://accounts.spotify.com/api/token"
        static let redirectURI = "https://www.google.com/"
        static let scopes = "user-read-private%20playlist-modify-public%20playlist-read-private%20playlist-modify-private%20user-follow-read%20user-library-modify%20user-library-read%20user-read-email"
    }
    
    private init(){}
    
    public var signInURL : URL?{
       
        let base = "https://accounts.spotify.com/authorize"
        let string = "\(base)?response_type=code&client_id=\(Constans.clientID)&scope=\(Constans.scopes)&redirect_uri=\(Constans.redirectURI)&show_dialog=TRUE"
        
        return URL(string: string)
    }
    
    var isSignedIn: Bool{
        return accessToken != nil
    }
    
    private var accessToken: String?{
        return UserDefaults.standard.string(forKey: "access_token")
    }
    
    private var refreshToken: String?{
        return UserDefaults.standard.string(forKey: "refresh_token")
    }
    
    private var tokenExpirationDate: Date?{
        return UserDefaults.standard.object(forKey: "expirationDate") as? Date
    }
    
    private var shouldRRefreshToken: Bool{
        guard let expirationDate = tokenExpirationDate else {
            return false
        }
        
        let currentDate = Date()
        let fiveMinutes: TimeInterval = 300
        return currentDate.addingTimeInterval(fiveMinutes) >= expirationDate
    }
    
    public func excahnageCodeForToken(code:String,completion: @escaping((Bool) -> Void)){
        //Get Token
        guard let url = URL(string: Constans.tokenAPIURL) else {
            return
        }
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: Constans.redirectURI)
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.query?.data(using: .utf8)
        let basicToken = Constans.clientID + ":" + Constans.clientSecret
        let data = basicToken.data(using: .utf8)
        guard let base64String = data?.base64EncodedString() else {
            print("Failure to get bbase64")
            completion(false)
            return
        }
        
        request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")

        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                completion(false)
                return
            }
            
            do {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                self?.cacheToken(result: result)
                completion(true)
            }
            catch{
                print(error.localizedDescription)
                completion(false)
            }
        }
        task.resume()
    }
    
    private var onRefreshBlocks = [((String) -> Void)]()
    
    
    public func withValidToken(completion: @escaping(String)-> Void){
        guard !refreshingToken else {
            // Append Completion
            onRefreshBlocks.append(completion)
            return
        }
        if shouldRRefreshToken{
            refreshIfNeeded { [weak self] success in
                if success {
                    if let token = self?.accessToken, success{
                        completion(token)
                    }
                }
            }
        }
        else if let token = accessToken{
            completion(token)
        }
    }
    
    public func refreshIfNeeded(completion: ((Bool) -> Void)?){
        guard !refreshingToken else {
            return
        }
        
        guard shouldRRefreshToken else {
            completion?(true)
            return
        }
        
        guard let refreshToken = self.refreshToken else {
            completion?(true)
            return
        }
        
        //Refresh the Token
        guard let url = URL(string: Constans.tokenAPIURL) else {
            return
        }
        
        refreshingToken = true
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.query?.data(using: .utf8)
        let basicToken = Constans.clientID + ":" + Constans.clientSecret
        let data = basicToken.data(using: .utf8)
        guard let base64String = data?.base64EncodedString() else {
            print("Failure to get bbase64")
            completion?(false)
            return
        }
        
        request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")

        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            self?.refreshingToken = false
            guard let data = data, error == nil else {
                completion?(false)
                return
            }
            
            do {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                self?.onRefreshBlocks.forEach{ $0(result.access_token)}
                self?.onRefreshBlocks.removeAll()
                self?.cacheToken(result: result)
                completion?(true)
            }
            catch{
                print(error.localizedDescription)
                completion?(false)
            }
        }
        task.resume()
    }
    
    private func cacheToken(result: AuthResponse){
        UserDefaults.standard.setValue(result.access_token, forKey: "access_token")
        if let refresh_token = result.refresh_token{
            UserDefaults.standard.setValue(refresh_token, forKey: "refresh_token")
        }
        UserDefaults.standard.setValue(Date().addingTimeInterval(TimeInterval(result.expires_in)), forKey: "expirationDate")
    }
}
