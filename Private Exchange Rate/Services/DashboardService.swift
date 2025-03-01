//
//  DashboardService.swift
//  Private Exchange Rate
//
//  Created on behalf of Dmitriy Portenko
//

import Foundation
import Combine

enum DashboardError: Error {
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case unauthorized
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid server response"
        case .decodingError(let error):
            return "Data decoding error: \(error.localizedDescription)"
        case .unauthorized:
            return "Authentication required"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

class DashboardService {
    static let shared = DashboardService()
    
    // Use environment variable or default to a placeholder
    private let baseURL = "https://dashboard-router.fly.dev" // Your actual API URL
    
    private let tokenStorage = TokenStorage.shared
    private let database = DashboardDatabase.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Authentication
    
    func login(email: String, password: String) -> AnyPublisher<User, DashboardError> {
        let loginRequest = LoginRequest(email: email, password: password)
        let url = URL(string: "\(baseURL)/api/auth/login")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(loginRequest)
        } catch {
            return Fail(error: .decodingError(error)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { DashboardError.networkError($0) }
            .flatMap { data, response -> AnyPublisher<AuthResponse, DashboardError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: .invalidResponse).eraseToAnyPublisher()
                }
                
                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 401 {
                        return Fail(error: .unauthorized).eraseToAnyPublisher()
                    }
                    return Fail(error: .invalidResponse).eraseToAnyPublisher()
                }
                
                do {
                    let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                    return Just(authResponse)
                        .setFailureType(to: DashboardError.self)
                        .eraseToAnyPublisher()
                } catch {
                    return Fail(error: .decodingError(error)).eraseToAnyPublisher()
                }
            }
            .handleEvents(receiveOutput: { [weak self] authResponse in
                // Store tokens and user info
                self?.tokenStorage.saveAccessToken(authResponse.accessToken)
                self?.tokenStorage.saveRefreshToken(authResponse.refreshToken)
                self?.tokenStorage.saveUser(id: authResponse.user.id, email: authResponse.user.email)
            })
            .map { $0.user }
            .eraseToAnyPublisher()
    }
    
    func refreshToken() -> AnyPublisher<Void, DashboardError> {
        guard let refreshToken = tokenStorage.getRefreshToken() else {
            return Fail(error: .unauthorized).eraseToAnyPublisher()
        }
        
        let refreshRequest = RefreshTokenRequest(refreshToken: refreshToken)
        let url = URL(string: "\(baseURL)/api/auth/refresh-token")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(refreshRequest)
        } catch {
            return Fail(error: .decodingError(error)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { DashboardError.networkError($0) }
            .flatMap { data, response -> AnyPublisher<RefreshTokenResponse, DashboardError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: .invalidResponse).eraseToAnyPublisher()
                }
                
                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 401 {
                        // Clear tokens if refresh token is invalid
                        self.tokenStorage.clearAllTokens()
                        return Fail(error: .unauthorized).eraseToAnyPublisher()
                    }
                    return Fail(error: .invalidResponse).eraseToAnyPublisher()
                }
                
                do {
                    let refreshResponse = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
                    return Just(refreshResponse)
                        .setFailureType(to: DashboardError.self)
                        .eraseToAnyPublisher()
                } catch {
                    return Fail(error: .decodingError(error)).eraseToAnyPublisher()
                }
            }
            .handleEvents(receiveOutput: { [weak self] refreshResponse in
                // Store new tokens
                self?.tokenStorage.saveAccessToken(refreshResponse.accessToken)
                self?.tokenStorage.saveRefreshToken(refreshResponse.refreshToken)
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    func logout() {
        tokenStorage.clearAllTokens()
    }
    
    // MARK: - Dashboard Data
    
    func fetchTotalAmount(year: Int? = nil, month: Int? = nil) -> AnyPublisher<TotalAmountResponse, DashboardError> {
        guard let accessToken = tokenStorage.getAccessToken() else {
            return Fail(error: .unauthorized).eraseToAnyPublisher()
        }
        
        var urlComponents = URLComponents(string: "\(baseURL)/api/dashboard/total-amount")!
        
        // Add query parameters if provided
        var queryItems: [URLQueryItem] = []
        if let year = year {
            queryItems.append(URLQueryItem(name: "year", value: "\(year)"))
        }
        if let month = month {
            queryItems.append(URLQueryItem(name: "month", value: "\(month)"))
        }
        
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        return fetchWithTokenRefresh(request: request)
            .handleEvents(receiveOutput: { [weak self] response in
                print("Received response: \(response)")
                // Store the result in database
                self?.database.saveTotalAmount(
                    response.totalAmount,
                    year: response.year,
                    month: response.month
                )
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    private func fetchWithTokenRefresh<T: Decodable>(request: URLRequest) -> AnyPublisher<T, DashboardError> {
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { DashboardError.networkError($0) }
            .flatMap { data, response -> AnyPublisher<T, DashboardError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: .invalidResponse).eraseToAnyPublisher()
                }
                
                switch httpResponse.statusCode {
                case 200:
                    do {
                        let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                        return Just(decodedResponse)
                            .setFailureType(to: DashboardError.self)
                            .eraseToAnyPublisher()
                    } catch {
                        return Fail(error: .decodingError(error)).eraseToAnyPublisher()
                    }
                    
                case 401:
                    // Token might be expired, try to refresh
                    return self.refreshToken()
                        .flatMap { _ -> AnyPublisher<T, DashboardError> in
                            // Update the request with new access token
                            var newRequest = request
                            if let newToken = self.tokenStorage.getAccessToken() {
                                newRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                                
                                // Retry the request with new token
                                return URLSession.shared.dataTaskPublisher(for: newRequest)
                                    .mapError { DashboardError.networkError($0) }
                                    .flatMap { data, response -> AnyPublisher<T, DashboardError> in
                                        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                                            return Fail(error: .invalidResponse).eraseToAnyPublisher()
                                        }
                                        
                                        do {
                                            let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                                            return Just(decodedResponse)
                                                .setFailureType(to: DashboardError.self)
                                                .eraseToAnyPublisher()
                                        } catch {
                                            return Fail(error: .decodingError(error)).eraseToAnyPublisher()
                                        }
                                    }
                                    .eraseToAnyPublisher()
                            } else {
                                return Fail(error: .unauthorized).eraseToAnyPublisher()
                            }
                        }
                        .eraseToAnyPublisher()
                    
                default:
                    return Fail(error: .invalidResponse).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Local Data Access
    
    func getLocalTotalAmount(year: Int? = nil, month: Int? = nil) -> TotalAmountResponse? {
        return database.fetchTotalAmount(year: year, month: month)
    }
} 