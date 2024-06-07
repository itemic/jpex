//
//  VisitPill.swift
//  jpex
//
//  Created by Terran Kroft on 6/2/2024.
//

import SwiftUI

struct VisitPillView: View {
    var text: String
    var color: Color
    
    var body: some View {
        Text(text)
            .foregroundStyle(
                .white.gradient
                    .shadow(.inner(color: .white.opacity(0.1), radius: 1, x: 0, y: 1))
                    .shadow(.drop(radius: 0.5, x: 0, y: 1))
                    .shadow(.drop(color: .black.opacity(0.1), radius: 10, x: 0, y: -1))
                    .shadow(.drop(color: color, radius: 2, x: 0, y: -1))
            )
            .font(.system(size: 14))
            .fontWeight(.semibold)
            .kerning(-0.5)
            .padding(4)
            .padding(.horizontal, 4)
            .background(
                ZStack {
                    color
                    
                    Color.white
                        .mask(LinearGradient(colors: [.black.opacity(0.6), .black.opacity(0)], startPoint: .top, endPoint: .bottom))
                    
                    color.brightness(0.2).saturation(2)
                        .mask(LinearGradient(colors: [.black.opacity(0.2), .black.opacity(0)], startPoint: .top, endPoint: .bottom))
                    
                    color.brightness(-0.2)
                        .mask(LinearGradient(colors: [.black.opacity(0), .black.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                        
                }
            )
            
            
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            .contentShape(.rect())
    }
}

#Preview {
    VStack {
        VisitPillView(text: "WANT TO", color: .sdgBlue)
        VisitPillView(text: "WANT TO", color: .sdgRed)
        VisitPillView(text: "WANT TO", color: .sdgGreen)
        VisitPillView(text: "WANT TO", color: .sdgOrange)
        VisitPillView(text: "WANT TO", color: .sdgYellow)
    }
    
}
