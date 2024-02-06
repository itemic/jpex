//
//  ProgressBarView.swift
//  jpex
//
//  Created by Terran Kroft on 6/2/2024.
//

import SwiftUI

struct ProgressBarView: View {
    var spacing = 10.0
    var width = 10.0
    var percentage: Double = 0.5
    var color: Color = .sdgBlue
    var degree: Double = 45
    @State var animationAmount = 0.0
    var clip: some View {
        GeometryReader { geometry in
            let long = max(geometry.size.width, geometry.size.height)
            let group = spacing + width
            let count = Int(2 * long / group)
            HStack(spacing: spacing) {
                ForEach(0..<count) { _ in
                    Color.white.opacity(0.2)
                        .frame(width: width, height: 2 * long)
                }
                
            }
            
            .frame(maxWidth: .infinity)
            .rotationEffect(Angle(degrees: degree), anchor: .center)
            .offset(x: -long, y: -long )
                        .offset(x: animationAmount)
                        .onAppear {
                            animationAmount = (group / cos(Angle(degrees: degree).radians))
                        }
            .background(color)
            .animation(
                .linear(duration: 2)
                .repeatForever(autoreverses: false),
                value: animationAmount)
        }
        
        .clipped()
        .clipShape(Capsule())
        
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                color.opacity(0.2)
                    .frame(width: geometry.size.width)
                clip.opacity(1)
                    .frame(width: percentage * geometry.size.width)
            }
            .clipShape(Capsule())
        }
        
    }
}

#Preview {
    ProgressBarView(percentage: 0.5, color: .sdgRed)
        .frame(height: 30)
}
