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
                            Text("\(saveModel.visitStatus.reduce(0, +))")
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
                                    
                                    
                                    HStack {
                                        Text(pref.name).bold()
                                            .foregroundStyle(getPrefectureColor(saveModel.visitStatus[pref.id-1]))
                                        Spacer()
                                        Text("\(saveModel.visitStatus[pref.id - 1])")
                                        
                                        //                                        Text(saveModel.visitStatus[pref.id - 1])
                                    }
                                    
                                })
                                .listRowBackground(getPrefectureColor(saveModel.visitStatus[pref.id-1]).opacity(0.05))

                            }
                        } header: {
                            Text(region.rawValue)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .onAppear(perform: load)
            .navigationTitle("Prefectures")
            
        }
        
    }
    
    func load() {
        print("WAHOO")
        if saveModels.isEmpty {
            modelContext.insert(SaveModel())
        }
//        saveModel = data?.first
    }
    
   
    
    func getVisitStatus(pref: Prefecture) -> VisitStatus {
        let code = UserDefaults.standard.integer(forKey: "JP-\(pref.id)") as VisitCode
        return VisitStatus(rawValue: code ) ?? .never
    }
    
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
