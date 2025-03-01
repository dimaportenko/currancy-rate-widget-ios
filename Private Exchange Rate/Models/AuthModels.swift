//
//  AuthModels.swift
//  Private Exchange Rate
//
//  Created on behalf of Dmitriy Portenko
//

import Foundation

// MARK: - Authentication Models

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
}

struct User: Codable {
    let id: String
    let email: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
}

// MARK: - Dashboard Models

struct TotalAmountResponse: Codable {
    let totalAmount: Double
    let year: Int
    let month: Int
} 