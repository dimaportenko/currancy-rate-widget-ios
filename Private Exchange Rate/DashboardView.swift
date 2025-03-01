//
//  DashboardView.swift
//  Private Exchange Rate
//
//  Created on behalf of Dmitriy Portenko
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack {
                    // Main content based on state
                    switch viewModel.state {
                    case .loading:
                        ProgressView("Loading...")
                            .progressViewStyle(CircularProgressViewStyle())
                        
                    case .needsAuthentication:
                        loginView
                        
                    case .authenticated(let totalAmount):
                        if let totalAmount = totalAmount {
                            dashboardDataView(totalAmount)
                        } else {
                            ProgressView("Fetching data...")
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        
                    case .error(let message):
                        errorView(message)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                if case .authenticated = viewModel.state {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Logout") {
                            viewModel.logout()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Refresh") {
                            viewModel.fetchDashboardData()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Login View
    
    private var loginView: some View {
        VStack(spacing: 20) {
            Text("Login to Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 20)
            
            TextField("Email", text: $viewModel.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                viewModel.login()
            } label: {
                if viewModel.isLoggingIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(minWidth: 100, maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                } else {
                    Text("Login")
                        .frame(minWidth: 100, maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(viewModel.isLoggingIn)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Dashboard Data View
    
    private func dashboardDataView(_ data: TotalAmountResponse) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Financial Summary")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                // Period
                HStack {
                    Text("\(viewModel.formatMonth(data.month + 1)) \(data.year)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                // Amount Card
                VStack {
                    Text("Total Amount")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.formatCurrency(data.totalAmount))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.top, 5)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .padding(.vertical)
                
                // Last updated info
                Text("Last updated: \(Date(), formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .refreshable {
            // Pull-to-refresh action
            await withCheckedContinuation { continuation in
                viewModel.fetchDashboardData()
                // Since fetchDashboardData() isn't async, we need to continue manually
                continuation.resume()
            }
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            Text("Error")
                .font(.title)
                .fontWeight(.bold)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Try Again") {
                viewModel.checkAuthenticationStatus()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
    
    // MARK: - Formatters
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
} 