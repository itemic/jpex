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
    
    @State var visitStatus: VisitStatus = .never
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
                    ForEach(VisitStatus.allCases) { vCase in
                        Text(vCase.text).tag(vCase.id)
                    }
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
