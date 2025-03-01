//
//  DashboardView.swift
//  Private Exchange Rate
//
//  Created on behalf of Dmitriy Portenko
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        VStack {
            Text("Dashboard")
                .font(.largeTitle)
                .padding()
            
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
} 