//
//  ContentView.swift
//  jpex
//
//  Created by Terran Kroft on 26/1/2024.
//

import SwiftUI
import MapKit
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Query var saveModels: [SaveModel]
    @AppStorage("localLanguage") var localLanguage: Bool = false
    @State var saveModel: [VisitStatus] = [VisitStatus](repeating: .never, count: 47)
    
    func maximumColorFrom(_ region: Region) -> Color {
        var max = 0
        var maxStatus = VisitStatus.never
        let ids = Prefecture.prefecturesFrom(region).map({$0.id})
        
            for id in ids {
                let score = saveModel[id-1].score
                if score > max {
                    max = score
                    maxStatus = saveModel[id-1]
                }
            }
            
        return maxStatus.color
    }
    
    func completionFrom(_ region: Region) -> Int {
        let ids = Prefecture.prefecturesFrom(region).map({$0.id})
        var counter = 0
        
            for id in ids {
                if (saveModel.count > id && saveModel[id-1].score > 0) {
                    counter += 1
                }
            }
            
        
        
        return counter
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    
                        ForEach(Region.allCases, id: \.self) { region in
                            Section(header: HStack {
                                Text(localLanguage ? region.jpn : region.eng)
                                    .font(.system(size: 24))
                                    .fontWeight(.medium)
                                    .kerning(0.5)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(completionFrom(region)) / \(Prefecture.prefecturesFrom(region).count)").monospacedDigit()
                                        .font(.body.smallCaps()).bold()
                                        .foregroundStyle(maximumColorFrom(region))
                                    ProgressBarView(percentage: Double(completionFrom(region)) / Double(Prefecture.prefecturesFrom(region).count), color: maximumColorFrom(region), animated: completionFrom(region) != Prefecture.prefecturesFrom(region).count)
                                        .frame(width: 60, height: 6)
                                }
                            }
                                .padding()
                                .background(.thickMaterial)) {
                                    ForEach(Prefecture.prefecturesFrom(region)) { pref in
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: -2) {
                                            Text(localLanguage ? pref.localName : pref.name)
                                                .font(.system(size: 32))
                                                .fontWeight(.light)
                                                .kerning(-0.5)
                                                .foregroundStyle(saveModel[pref.id - 1] == .never  ? .tertiary : .primary)
                                            Text(localLanguage ? pref.name : pref.localName)
                                                .font(.system(size: 18))
                                                .fontWeight(.regular)
                                                .kerning(-0.5)
                                                .foregroundStyle(saveModel[pref.id - 1] == .never  ? .quaternary : .secondary)
                                        }
                                        
                                        Spacer()
                                        Button("ABC") {
                                            print("BBBC")
                                            saveModel[pref.id - 1] = saveModel[pref.id - 1].next
                                        }
                                        Button("DEF") {
                                            print("ABD")
                                        }
                                        .buttonStyle(.borderedProminent)
                                        VisitPillView(text: "\(saveModel[pref.id - 1].text)".uppercased(), color: saveModel[pref.id - 1].color)
                                            .onTapGesture {
                                                print("BBB")
        //                                        var existingStatus = saveModel.visitStatus
                                                saveModel[pref.id - 1] = saveModel[pref.id - 1].next
        //                                        saveModel.visitStatus = existingStatus
                                            }
                                            
                                        
                                    }
                                    .padding()
                                   
                                    .background(
                                        ZStack {
                                            saveModel[pref.id - 1].color.opacity(0.2)
                                                .mask(
                                                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black.opacity(1)]), startPoint: .leading, endPoint: .trailing)
                                                )
                                            
                                            HStack {
                                                Image("jp_flag\(pref.id)").resizable().aspectRatio(contentMode: .fill).frame(width: 300)
                                                    .grayscale(saveModel[pref.id - 1] == .never ? 1 : 0)
                                                
                                                    .mask(
                                                        LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.3), Color.black.opacity(0)]), startPoint: .leading, endPoint: .trailing)
                                                    )
                                                Spacer()
                                            }
                                            
                                        })
                                    .clipped()
                                    
                                    .scrollTransition { view, phase in
                                                            view.opacity(phase.isIdentity ? 1 : 0.3)
                                                            .scaleEffect(phase.isIdentity ? 1 : 0.75)
                                                            .blur(radius: phase.isIdentity ? 0 : 10)
                                                        }
                                }
                            }
                        
                    }
                }
            }
            .onAppear(perform: load)
            .navigationTitle("Prefectures")
            .toolbar {
                Button {
                    localLanguage.toggle()
                } label: {
                    Text("toggle")
                }
            }
        }
    }
    
    
    
    func load() {
        if saveModels.isEmpty {
            modelContext.insert(SaveModel())
        }
        saveModel = saveModels.first?.visitStatus ?? [VisitStatus](repeating: .never, count: 47)

    }
    

}

//#Preview {
////    ContentView()
//}
