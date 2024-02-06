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
//    @State private var saveModel: SaveModel?
    @Query var saveModels: [SaveModel]
    @Query var save: [PrefectureSave]
    
    func getPrefectureColor(_ value: Int) -> Color {
        switch(value) {
        case 0: Color.secondary
        case 1: Color.blue
        case 2: Color.green
        case 3: Color.yellow
        case 4: Color.orange
        case 5: Color.red
        default: Color.secondary
        }
    }
    
    var body: some View {

        NavigationView {
            List {
                if let saveModel = saveModels.first {
                    HStack {
                        Spacer()
                        VStack {
                            Text("Travel Score")
                                .font(.body.smallCaps()).bold()
                                .foregroundStyle(.secondary)
                            Text("\(saveModel.visitStatus.reduce(0) {$0 + $1.score})")
                                .font(.largeTitle)
                        }
                        Spacer()
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
                                            Text(pref.name).bold()
                                                .font(.system(size: 32))
                                                .fontWeight(.light)
                                                .kerning(-0.5)
                                                .foregroundStyle(saveModel.visitStatus[pref.id - 1] == .never || saveModel.visitStatus[pref.id - 1] == .want ? .tertiary : .primary)
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
                                            Image("jp_flag\(pref.id)").resizable().aspectRatio(contentMode: .fill).frame(width: 300, height: 60)
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
            
        }
        
    }
    
    func load() {
        print("WAHOO")
        if saveModels.isEmpty {
            modelContext.insert(SaveModel())
        }
        if save.count != 47 {
            // TODO: Delete all
            try? modelContext.delete(model: PrefectureSave.self)
            for prefecture in Prefecture.allPrefectures {
                let p = PrefectureSave(id: prefecture.id, status: .never)
                modelContext.insert(p)
            }
        }
        print (save.count)
//        saveModel = data?.first
    }
    
   
    
//    func getVisitStatus(pref: Prefecture) -> VisitStatus {
//        let code = UserDefaults.standard.integer(forKey: "JP-\(pref.id)") as VisitCode
//        return VisitStatus(rawValue: code ) ?? .never
//    }
    
//    init() {
//        /// In a real app, the event data probably downloads from a server. This sample loads GeoJSON data from a local file instead.
//        var initOverlays: [MKPolygon] = []
//        if let jsonUrl = Bundle.main.url(forResource: "mie", withExtension: "geojson") {
//            do {
//                let eventData = try Data(contentsOf: jsonUrl)
//                
//
//                // Use the `MKGeoJSONDecoder` to convert the JSON data into MapKit objects, such as `MKGeoJSONFeature`.
//                let decoder = MKGeoJSONDecoder()
//                
//                let jsonObjects = try decoder.decode(eventData)
//                
//                
//                for object in jsonObjects {
//                    
//                    if let mp = object as? MKMultiPolygon {
//                        for polygon in mp.polygons {
//                            initOverlays.append(polygon)
//                        }
//                    }
//                }
//                
////                parse(jsonObjects)
//            } catch {
//                print("Error decoding GeoJSON: \(error).")
//            }
//        }
//        _overlays = State(initialValue: initOverlays)
//        
//    }


//    func parse(_ jsonObjects: [MKGeoJSONObject]) {
//        
//        for object in jsonObjects {
//            print("OBDJEC")
//            
//            if let mp = object as? MKMultiPolygon {
//                print("mpd")
//                print(mp.polygons.count)
////                print(mp.polygons)
//                for polygon in mp.polygons {
//                    overlays.append(polygon)
//                    bb += 1
//                }
//                bb = 4
//                overlays = mp.polygons
//                print(overlays.count)
//                print("BB \(bb)")
////                overlays.append(contentsOf: mp.polygons)
//            }
//           
//        }
//    }
}

//#Preview {
//    ContentView()
//}
