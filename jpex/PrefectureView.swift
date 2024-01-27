//
//  PrefectureView.swift
//  jpex
//
//  Created by Terran Kroft on 26/1/2024.
//

import SwiftUI
import MapKit
struct PrefectureView: View {
    
    var prefecture: Prefecture
    
    @State var visitStatus: Int = 0
    @Environment(\.modelContext) var modelContext
    var saveModel: SaveModel
    
    
    
    
    var body: some View {
        VStack(spacing: 0) {
            Map {}
            List {
                HStack {
                    Text("Region")
                    Spacer()
                    Text(prefecture.region.rawValue)
                        .foregroundStyle(.secondary)
                }
                Picker("Visit status", selection: $visitStatus) {
                    Text("Never").tag(0)
                    Text("Passed").tag(1)
                    Text("Alighted").tag(2)
                    Text("Visited").tag(3)
                    Text("Stayed").tag(4)
                    Text("Lived").tag(5)
                }
                .onChange(of: visitStatus) {
                    var existingStatus = saveModel.visitStatus
                    existingStatus[prefecture.id - 1] = visitStatus
                    saveModel.visitStatus = existingStatus
                }
            }
            .listStyle(.sidebar)
        }
        .onAppear {
            visitStatus = saveModel.visitStatus[prefecture.id - 1]
        }
        .navigationTitle(prefecture.name)
    }
    
   
}



//#Preview {
//    PrefectureView(prefecture: Prefecture(id: 1, name: "Hokkaido", region: .hokkaido))
//}
