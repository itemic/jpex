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
    @State var showSheet: Bool = false
    @State var resetToggle: Bool = false
    @Environment(\.openURL) var openURL

    var code: String {
        var a = String(saveModel[15].score) + "" + String(saveModel[13].score) + "" + String(saveModel[7].score ) + "" + String(saveModel[11].score) + "" + String(saveModel[12].score) + "" + String(saveModel[21].score) + "" + String(saveModel[25].score) + "" + String(saveModel[29].score) + "" + String(saveModel[30].score) + ""
        
        var b = String(saveModel[34].score) + "" + String(saveModel[33].score) + "" + String(saveModel[31].score) + "" + String(saveModel[22].score) + "" + String(saveModel[23].score) + "" + String(saveModel[27].score) + "" + String(saveModel[16].score) + "" + String(saveModel[18].score) + "" + String(saveModel[26].score) + "" + String(saveModel[37].score) + "" + String(saveModel[38].score) + "" + String(saveModel[35].score) + "" + String(saveModel[10].score) + ""
        
        var c = String(saveModel[8].score) + "" + String(saveModel[32].score) + "" + String(saveModel[43].score) + "" + String(saveModel[39].score) + "" + String(saveModel[41].score) + "" + String(saveModel[36].score) + "" + String(saveModel[17].score) + "" + String(saveModel[46].score) + "" + String(saveModel[44].score) + "" + String(saveModel[42].score) + "" + String(saveModel[40].score) + ""
        
        var d = String(saveModel[45].score) + "" + String(saveModel[28].score) + "" + String(saveModel[24].score) + "" + String(saveModel[9].score ) + "" + String(saveModel[19].score) + "" + String(saveModel[20].score) + "" + String(saveModel[6].score ) + "" + String(saveModel[14].score) + "" + String(saveModel[3].score ) + "" + String(saveModel[5].score ) + "" + String(saveModel[2].score ) + "" + String(saveModel[4].score ) + "" + String(saveModel[1].score ) + "" + String(saveModel[0].score )
        
        return a + b + c + d 
    }
    
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
//                                            Text(localLanguage ? pref.name : pref.localName)
//                                                .font(.system(size: 18))
//                                                .fontWeight(.regular)
//                                                .kerning(-0.5)
//                                                .foregroundStyle(saveModel[pref.id - 1] == .never  ? .quaternary : .secondary)
                                        }
                                        
                                        Spacer()
                                       
                                        VisitPillView(text: "\(saveModel[pref.id - 1].text)".uppercased(), color: saveModel[pref.id - 1].color)
                                            .onTapGesture {
                                                saveModel[pref.id - 1] = saveModel[pref.id - 1].next
                                                saveModels.first?.visitStatus = saveModel
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
                                    .contentShape(.rect())
                                   
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
                    
                    var urlString = "https://zhung.com.tw/japanex/#" + code
                    openURL(URL(string: urlString)!)
                    

                } label: {
                    Image(systemName: "globe.asia.australia.fill")
                }
                Button {
                    showSheet.toggle()
                } label: {
                    Image(systemName: "gearshape.fill")
                }
            }
            .sheet(isPresented: $showSheet, content: {
                SettingsView(resetToggle: $resetToggle)
            })
            .onChange(of: resetToggle) {
                load()
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
