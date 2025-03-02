//
//  TokenStorage.swift
//  Private Exchange Rate
//
//  Created on behalf of Dmitriy Portenko
//

import Foundation
import KeychainAccess

class TokenStorage {
    private enum Keys {
        static let accessToken = "dashboard.accessToken"
        static let refreshToken = "dashboard.refreshToken"
        static let userID = "dashboard.userID"
        static let userEmail = "dashboard.userEmail"
    }
    
    // Configure keychain with shared access group
    private let keychain: Keychain = {
        let service = "com.privateexchangerate.app"
        let accessGroup = "group.com.dimaportenko.privateexchangerate.Private-Exchange-Rate.sharedcontainer"
        
        // Create a keychain with both service and accessGroup for sharing between app and extensions
        return Keychain(service: service, accessGroup: accessGroup)
            .synchronizable(true) // Enable iCloud synchronization if desired
    }()
    
    static let shared = TokenStorage()
    
    private init() {
        print("TokenStorage initialized with shared keychain access")
    }
    
    // MARK: - Access Token
    
    func saveAccessToken(_ token: String) {
        do {
            try keychain.set(token, key: Keys.accessToken)
        } catch {
            print("Error saving access token: \(error)")
        }
    }
    
    func getAccessToken() -> String? {
        do {
            return try keychain.get(Keys.accessToken)
        } catch {
            print("Error retrieving access token: \(error)")
            return nil
        }
    }
    
    // MARK: - Refresh Token
    
    func saveRefreshToken(_ token: String) {
        do {
            try keychain.set(token, key: Keys.refreshToken)
        } catch {
            print("Error saving refresh token: \(error)")
        }
    }
    
    func getRefreshToken() -> String? {
        do {
            return try keychain.get(Keys.refreshToken)
        } catch {
            print("Error retrieving refresh token: \(error)")
            return nil
        }
    }
    
    // MARK: - User Info
    
    func saveUser(id: String, email: String) {
        do {
            try keychain.set(id, key: Keys.userID)
            try keychain.set(email, key: Keys.userEmail)
        } catch {
            print("Error saving user info: \(error)")
        }
    }
    
    func getUserInfo() -> (id: String, email: String)? {
        do {
            guard let id = try keychain.get(Keys.userID),
                  let email = try keychain.get(Keys.userEmail) else {
                return nil
            }
            return (id, email)
        } catch {
            print("Error retrieving user info: \(error)")
            return nil
        }
    }
    
    // MARK: - Clear All
    
    func clearAllTokens() {
        do {
            try keychain.remove(Keys.accessToken)
            try keychain.remove(Keys.refreshToken)
            try keychain.remove(Keys.userID)
            try keychain.remove(Keys.userEmail)
        } catch {
            print("Error clearing tokens: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    func isAuthenticated() -> Bool {
        return getAccessToken() != nil && getRefreshToken() != nil
    }
} 