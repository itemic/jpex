//
//  VisitButtonView.swift
//  jpex
//
//  Created by Terran Kroft on 7/6/2024.
//

import SwiftUI

struct VisitButtonView: View {
    @Environment(\.modelContext) var modelContext
    var color: Color = .gray
    @State var status: VisitStatus = .never
    @State var isSelected = false
    @Namespace var animation
    var body: some View {
        HStack {
            Spacer()
            if (isSelected) {
                Text(status.text.uppercased())
                    .modifier(ColorButton(color: status.color))
                    .onTapGesture {
                        withAnimation {
                            isSelected.toggle()
                        }
                    }
                    .matchedGeometryEffect(id: status.text, in: animation)
            } else { 
                Text("0")
                    .modifier(ColorButton(color: .gray))
                    .onTapGesture {
                        withAnimation {
                            status = .never
                            isSelected.toggle()
                        }
                    }
                    .matchedGeometryEffect(id: VisitStatus.never.text, in: animation)
                Text("1")
                    .modifier(ColorButton(color: .sdgBlue))
                    .onTapGesture {
                        withAnimation {
                            status = .passed
                            isSelected.toggle()
                        }
                    }
                    .matchedGeometryEffect(id: VisitStatus.passed.text, in: animation)
                Text("2")
                    .modifier(ColorButton(color: .sdgGreen))
                    .onTapGesture {
                        withAnimation {
                            status = .alighted
                            isSelected.toggle()
                        }
                    }
                    .matchedGeometryEffect(id: VisitStatus.alighted.text, in: animation)
                Text("3")
                    .modifier(ColorButton(color: .sdgYellow))
                    .onTapGesture {
                        withAnimation {
                            status = .visited
                            isSelected.toggle()
                        }
                    }
                    .matchedGeometryEffect(id: VisitStatus.visited.text, in: animation)
                Text("4")
                    .modifier(ColorButton(color: .sdgOrange))
                    .onTapGesture {
                        withAnimation {
                            status = .stayed
                            isSelected.toggle()
                        }
                    }
                    .matchedGeometryEffect(id: VisitStatus.stayed.text, in: animation)
                Text("5")
                    .modifier(ColorButton(color: .sdgRed))
                    .onTapGesture {
                        withAnimation {
                            status = .lived
                            isSelected.toggle()
                        }
                    }
                    .matchedGeometryEffect(id: VisitStatus.lived.text, in: animation)
            }
            
            
        }
    }
}

#Preview {
    VisitButtonView(status: VisitStatus.never)
}

struct ColorButton: ViewModifier {
    var color: Color
    func body(content: Content) -> some View {
        content
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
            .padding(.horizontal, 8)
            .frame(minWidth: 20, minHeight: 20)
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
            
            
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            .contentShape(.rect)
            
            
    }
}
