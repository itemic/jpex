//
//  Prefecture.swift
//  jpex
//
//  Created by Terran Kroft on 26/1/2024.
//

import Foundation

struct Prefecture: Identifiable {
    let id: Int
    let name: String
    let region: Region
    
    static var hokkaidoPrefectures: [Prefecture] {
        allPrefectures.filter {$0.region == .hokkaido}
    }
    
    static var tohokuPrefectures: [Prefecture] {
        allPrefectures.filter {$0.region == .tohoku}
    }
    
    static var kantoPrefectures: [Prefecture] {
        allPrefectures.filter {$0.region == .kanto}
    }
    
    static var chubuPrefectures: [Prefecture] {
        allPrefectures.filter {$0.region == .chubu}
    }
    
    static var kansaiPrefectures: [Prefecture] {
        allPrefectures.filter {$0.region == .kansai}
    }
    
    static var chugokuPrefectures: [Prefecture] {
        allPrefectures.filter {$0.region == .chugoku}
    }
    
    static var shikokuPrefectures: [Prefecture] {
        allPrefectures.filter {$0.region == .shikoku}
    }
    
    static var kyushuPrefectures: [Prefecture] {
        allPrefectures.filter {$0.region == .kyushu}
    }
    
    static func prefecturesFrom(_ region: Region) -> [Prefecture] {
        return allPrefectures.filter {$0.region == region}
    }
    
    static var allPrefectures: [Prefecture] = [
        Prefecture(id: 1, name: "Hokkaido", region: .hokkaido),
        
        Prefecture(id: 2, name: "Aomori", region: .tohoku),
        Prefecture(id: 3, name: "Iwate", region: .tohoku),
        Prefecture(id: 4, name: "Miyagi", region: .tohoku),
        Prefecture(id: 5, name: "Akita", region: .tohoku),
        Prefecture(id: 6, name: "Yamagata", region: .tohoku),
        Prefecture(id: 7, name: "Fukushima", region: .tohoku),
        
        Prefecture(id: 8, name: "Ibaraki", region: .kanto),
        Prefecture(id: 9, name: "Tochigi", region: .kanto),
        Prefecture(id: 10, name: "Gunma", region: .kanto),
        Prefecture(id: 11, name: "Saitama", region: .kanto),
        Prefecture(id: 12, name: "Chiba", region: .kanto),
        Prefecture(id: 13, name: "Tokyo", region: .kanto),
        Prefecture(id: 14, name: "Kanagawa", region: .kanto),
        
        Prefecture(id: 15, name: "Niigata", region: .chubu),
        Prefecture(id: 16, name: "Toyama", region: .chubu),
        Prefecture(id: 17, name: "Ishikawa", region: .chubu),
        Prefecture(id: 18, name: "Fukui", region: .chubu),
        Prefecture(id: 19, name: "Yamanashi", region: .chubu),
        Prefecture(id: 20, name: "Nagano", region: .chubu),
        Prefecture(id: 21, name: "Gifu", region: .chubu),
        Prefecture(id: 22, name: "Shizuoka", region: .chubu),
        Prefecture(id: 23, name: "Aichi", region: .chubu),
        
        Prefecture(id: 24, name: "Mie", region: .kansai),
        Prefecture(id: 25, name: "Shiga", region: .kansai),
        Prefecture(id: 26, name: "Kyoto", region: .kansai),
        Prefecture(id: 27, name: "Osaka", region: .kansai),
        Prefecture(id: 28, name: "Hyogo", region: .kansai),
        Prefecture(id: 29, name: "Nara", region: .kansai),
        Prefecture(id: 30, name: "Wakayama", region: .kansai),
        
        Prefecture(id: 31, name: "Tottori", region: .chugoku),
        Prefecture(id: 32, name: "Shimane", region: .chugoku),
        Prefecture(id: 33, name: "Okayama", region: .chugoku),
        Prefecture(id: 34, name: "Hiroshima", region: .chugoku),
        Prefecture(id: 35, name: "Yamaguchi", region: .chugoku),
        
        Prefecture(id: 36, name: "Tokushima", region: .shikoku),
        Prefecture(id: 37, name: "Kagawa", region: .shikoku),
        Prefecture(id: 38, name: "Ehime", region: .shikoku),
        Prefecture(id: 39, name: "Kochi", region: .shikoku),
        
        Prefecture(id: 40, name: "Fukuoka", region: .kyushu),
        Prefecture(id: 41, name: "Saga", region: .kyushu),
        Prefecture(id: 42, name: "Nagasaki", region: .kyushu),
        Prefecture(id: 43, name: "Kumamoto", region: .kyushu),
        Prefecture(id: 44, name: "Oita", region: .kyushu),
        Prefecture(id: 45, name: "Miyazaki", region: .kyushu),
        Prefecture(id: 46, name: "Kagoshima", region: .kyushu),
        Prefecture(id: 47, name: "Okinawa", region: .kyushu),
        
    ]
}

enum Region: String, CaseIterable {
    case hokkaido,
    tohoku,
    kanto,
    chubu,
    kansai,
    chugoku,
    shikoku,
    kyushu
}


