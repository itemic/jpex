//
//  HomeView.swift
//  jpex
//
//  Created by Terran Kroft on 5/2/2024.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            HStack {
                Text("Kanagawa")
                Spacer()
                Text("Visited")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Tohoku")
                Spacer()
                Text("Visited")
                    .foregroundStyle(.secondary)
            }
               
        }
        .padding()
        .font(.system(size: 32))
        .fontWeight(.semibold)
        .kerning(-0.5)
    }
}

#Preview {
    HomeView()
}
