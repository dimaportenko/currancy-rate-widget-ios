//
//  DashboardViewModel.swift
//  Private Exchange Rate
//
//  Created on behalf of Dmitriy Portenko
//

import Foundation
import Combine
import SwiftUI

enum DashboardState {
    case loading
    case needsAuthentication
    case authenticated(totalAmount: TotalAmountResponse?)
    case error(String)
}

class DashboardViewModel: ObservableObject {
    @Published var state: DashboardState = .loading
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoggingIn: Bool = false
    @Published var errorMessage: String = ""
    
    private let dashboardService = DashboardService.shared
    private let tokenStorage = TokenStorage.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication
    
    func checkAuthenticationStatus() {
        state = .loading
        
        if tokenStorage.isAuthenticated() {
            // Load local data if available
            let localData = dashboardService.getLocalTotalAmount()
            state = .authenticated(totalAmount: localData)
            
            // Fetch fresh data from API
            fetchDashboardData()
        } else {
            state = .needsAuthentication
        }
    }
    
    func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required"
            return
        }
        
        isLoggingIn = true
        errorMessage = ""
        
        dashboardService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoggingIn = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] user in
                // Successfully logged in
                self?.state = .authenticated(totalAmount: nil)
                self?.fetchDashboardData()
            }
            .store(in: &cancellables)
    }
    
    func logout() {
        dashboardService.logout()
        state = .needsAuthentication
        email = ""
        password = ""
        errorMessage = ""
    }
    
    // MARK: - Dashboard Data
    
    func fetchDashboardData() {
        // Get current date for default year/month
        let calendar = Calendar.current
        let currentDate = Date()
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate) - 1
        
        dashboardService.fetchTotalAmount(year: year, month: month)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    if case .unauthorized = error {
                        self?.state = .needsAuthentication
                    } else {
                        // If we failed to get fresh data but have local data, keep showing it
                        if case .authenticated(let totalAmount) = self?.state, totalAmount != nil {
                            // Keep the current state with local data
                        } else {
                            self?.state = .error(error.localizedDescription)
                        }
                    }
                }
            } receiveValue: { [weak self] totalAmount in
                self?.state = .authenticated(totalAmount: totalAmount)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Helpers
    
    func formatCurrency(_ amount: Double) -> String {
        return DashboardUtils.formatCurrency(amount, currencyCode: "UAH")
    }
    
    func formatMonth(_ month: Int) -> String {
        return DashboardUtils.formatMonth(month)
    }
} 