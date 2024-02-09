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
    
    func getPrefectureColor(_ value: Int) -> Color {
        switch(value) {
        case 0: Color.secondary
        case 1: Color.sdgBlue
        case 2: Color.sdgGreen
        case 3: Color.sdgYellow
        case 4: Color.sdgOrange
        case 5: Color.sdgRed
        default: Color.secondary
        }
    }
    
    func maximumColorFrom(_ region: Region) -> Color {
        var max = 0
        let ids = Prefecture.prefecturesFrom(region).map({$0.id})
        var counter = 0
        if let saveModel = saveModels.first {
            for id in ids {
                let score = saveModel.visitStatus[id-1].score
                if score > max {
                    max = score
                }
            }
            
        }
        return getPrefectureColor(max)
    }
    
    func completionFrom(_ region: Region) -> Int {
        let ids = Prefecture.prefecturesFrom(region).map({$0.id})
        var counter = 0
        if let saveModel = saveModels.first {
            for id in ids {
                if (saveModel.visitStatus[id-1].score > 0) {
                    counter += 1
                }
            }
            
        }
        
        return counter
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    if let saveModel = saveModels.first {
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
                                                .foregroundStyle(saveModel.visitStatus[pref.id - 1] == .never || saveModel.visitStatus[pref.id - 1] == .want ? .tertiary : .primary)
                                            Text(localLanguage ? pref.name : pref.localName)
                                                .font(.system(size: 18))
                                                .fontWeight(.regular)
                                                .kerning(-0.5)
                                                .foregroundStyle(saveModel.visitStatus[pref.id - 1] == .never || saveModel.visitStatus[pref.id - 1] == .want ? .quaternary : .secondary)
                                        }
                                        
                                        Spacer()
                                        VisitPillView(text: "\(saveModel.visitStatus[pref.id - 1].text)".uppercased(), color: saveModel.visitStatus[pref.id - 1].color)
                                            .onTapGesture {
                                                print("BBB")
        //                                        var existingStatus = saveModel.visitStatus
                                                saveModel.visitStatus[pref.id - 1] = saveModel.visitStatus[pref.id - 1].next
        //                                        saveModel.visitStatus = existingStatus
                                            }
                                            
                                        
                                    }
                                    .padding()
                                   
                                    .background(
                                        ZStack {
                                            saveModel.visitStatus[pref.id - 1].color.opacity(0.2)
                                                .mask(
                                                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black.opacity(1)]), startPoint: .leading, endPoint: .trailing)
                                                )
                                            
                                            HStack {
                                                Image("jp_flag\(pref.id)").resizable().aspectRatio(contentMode: .fill).frame(width: 300)
                                                    .grayscale(saveModel.visitStatus[pref.id - 1] == .never || saveModel.visitStatus[pref.id - 1] == .want ? 1 : 0)
                                                
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
    
    var boxdy: some View {

        NavigationView {
            List {
                if let saveModel = saveModels.first {
                    HStack {
                        VStack {
                            ForEach(Region.allCases, id: \.self) { region in
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(region.rawValue)
                                        .font(.body.smallCaps()).bold()
                                        .foregroundStyle(.secondary)
                                    HStack {
                                        ProgressBarView(percentage: Double(completionFrom(region)) / Double(Prefecture.prefecturesFrom(region).count), color: maximumColorFrom(region), animated: completionFrom(region) != Prefecture.prefecturesFrom(region).count)
                                            .frame(height: 10)
                                        Text("\(completionFrom(region)) / \(Prefecture.prefecturesFrom(region).count)").monospacedDigit()
                                            .font(.body.smallCaps()).bold()
                                            .foregroundStyle(maximumColorFrom(region))
                                    }
                                }
                            }
                        }
                        
//                        Spacer()
                    }
                    .listRowInsets(.none)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    
                    ForEach(Region.allCases, id: \.self) { region in
                        Section {
                            ForEach(Prefecture.prefecturesFrom(region)) { pref in
                                
                               
                                NavigationLink(destination: PrefectureView(prefecture: pref, saveModel: saveModel), label: {
                                    
                                    ZStack {
                                        HStack {
                                            VStack(alignment: .leading, spacing: -2) {
                                                Text(localLanguage ? pref.localName : pref.name).bold()
                                                    .font(.system(size: 32))
                                                    .fontWeight(.light)
                                                    .kerning(-0.5)
                                                    .foregroundStyle(saveModel.visitStatus[pref.id - 1] == .never || saveModel.visitStatus[pref.id - 1] == .want ? .tertiary : .primary)
                                                Text(localLanguage ? pref.name : pref.localName).bold()
                                                    .font(.system(size: 18))
                                                    .fontWeight(.regular)
                                                    .kerning(-0.5)
                                                    .foregroundStyle(saveModel.visitStatus[pref.id - 1] == .never || saveModel.visitStatus[pref.id - 1] == .want ? .quaternary : .secondary)
                                            }
                                            
                                            Spacer()
                                            VisitPillView(text: "\(saveModel.visitStatus[pref.id - 1].text)".uppercased(), color: saveModel.visitStatus[pref.id - 1].color)
                                            
                                        }
                                    }
                                    
                                    .listRowSeparator(.hidden)
                                    
                                })
                                .listRowBackground(
                                    ZStack {
                                        saveModel.visitStatus[pref.id - 1].color.opacity(0.2)
                                            .mask(
                                                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black.opacity(1)]), startPoint: .leading, endPoint: .trailing)
                                            )
                                            
                                        HStack {
                                            Image("jp_flag\(pref.id)").resizable().aspectRatio(contentMode: .fill).frame(width: 300, height: 80)
                                                .grayscale(saveModel.visitStatus[pref.id - 1] == .never || saveModel.visitStatus[pref.id - 1] == .want ? 1 : 0)

                                                .mask(
                                                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.3), Color.black.opacity(0)]), startPoint: .leading, endPoint: .trailing)
                                                )
                                            Spacer()
                                        }
                                        
                                    }
                                        
                                )
                                
                                
                                .listRowSeparator(.hidden)

                            }
                        } header: {
                            Text(region.rawValue)
                        }
                    }
                }
            }
            .listStyle(.plain)
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

    }
    

}

//#Preview {
////    ContentView()
//}
