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
    let localName: String
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
        Prefecture(id: 1, name: "Hokkaido", localName: "北海道",region: .hokkaido),
        
        Prefecture(id: 2, name: "Aomori", localName: "青森県", region: .tohoku),
        Prefecture(id: 3, name: "Iwate",localName: "岩手県", region: .tohoku),
        Prefecture(id: 4, name: "Miyagi",localName: "宮城県", region: .tohoku),
        Prefecture(id: 5, name: "Akita",localName: "秋田県", region: .tohoku),
        Prefecture(id: 6, name: "Yamagata",localName: "山形県", region: .tohoku),
        Prefecture(id: 7, name: "Fukushima", localName: "福島県",region: .tohoku),
        
        Prefecture(id: 8, name: "Ibaraki",localName: "茨城県", region: .kanto),
        Prefecture(id: 9, name: "Tochigi",localName: "栃木県", region: .kanto),
        Prefecture(id: 10, name: "Gunma", localName: "群馬県",region: .kanto),
        Prefecture(id: 11, name: "Saitama",localName: "埼玉県", region: .kanto),
        Prefecture(id: 12, name: "Chiba",localName: "千葉県", region: .kanto),
        Prefecture(id: 13, name: "Tokyo", localName: "東京都",region: .kanto),
        Prefecture(id: 14, name: "Kanagawa", localName: "神奈川県",region: .kanto),
        
        Prefecture(id: 15, name: "Niigata",localName: "新潟県", region: .chubu),
        Prefecture(id: 16, name: "Toyama", localName: "富山県",region: .chubu),
        Prefecture(id: 17, name: "Ishikawa",localName: "石川県", region: .chubu),
        Prefecture(id: 18, name: "Fukui", localName: "福井県",region: .chubu),
        Prefecture(id: 19, name: "Yamanashi",localName: "山梨県", region: .chubu),
        Prefecture(id: 20, name: "Nagano",localName: "長野県", region: .chubu),
        Prefecture(id: 21, name: "Gifu", localName: "岐阜県",region: .chubu),
        Prefecture(id: 22, name: "Shizuoka",localName: "静岡県", region: .chubu),
        Prefecture(id: 23, name: "Aichi", localName: "愛知県",region: .chubu),
        
        Prefecture(id: 24, name: "Mie", localName: "三重県",region: .kansai),
        Prefecture(id: 25, name: "Shiga",localName: "滋賀県", region: .kansai),
        Prefecture(id: 26, name: "Kyoto",localName: "京都府", region: .kansai),
        Prefecture(id: 27, name: "Osaka",localName: "大阪府", region: .kansai),
        Prefecture(id: 28, name: "Hyogo",localName: "兵庫県", region: .kansai),
        Prefecture(id: 29, name: "Nara", localName: "奈良県",region: .kansai),
        Prefecture(id: 30, name: "Wakayama",localName: "和歌山県", region: .kansai),
        
        Prefecture(id: 31, name: "Tottori",localName: "鳥取県", region: .chugoku),
        Prefecture(id: 32, name: "Shimane",localName: "島根県", region: .chugoku),
        Prefecture(id: 33, name: "Okayama",localName: "岡山県", region: .chugoku),
        Prefecture(id: 34, name: "Hiroshima",localName: "広島県", region: .chugoku),
        Prefecture(id: 35, name: "Yamaguchi",localName: "山口県", region: .chugoku),
        
        Prefecture(id: 36, name: "Tokushima",localName: "徳島県", region: .shikoku),
        Prefecture(id: 37, name: "Kagawa",localName: "香川県", region: .shikoku),
        Prefecture(id: 38, name: "Ehime", localName: "愛媛県",region: .shikoku),
        Prefecture(id: 39, name: "Kochi", localName: "高知県",region: .shikoku),
        
        Prefecture(id: 40, name: "Fukuoka", localName: "福岡県",region: .kyushu),
        Prefecture(id: 41, name: "Saga", localName: "佐賀県",region: .kyushu),
        Prefecture(id: 42, name: "Nagasaki",localName: "長崎県", region: .kyushu),
        Prefecture(id: 43, name: "Kumamoto",localName: "熊本県", region: .kyushu),
        Prefecture(id: 44, name: "Oita", localName: "大分県",region: .kyushu),
        Prefecture(id: 45, name: "Miyazaki",localName: "宮崎県", region: .kyushu),
        Prefecture(id: 46, name: "Kagoshima", localName: "鹿児島県",region: .kyushu),
        Prefecture(id: 47, name: "Okinawa", localName: "沖縄県",region: .kyushu),
        
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
    
    var eng: String {
        switch self {
        case .hokkaido:
            return "Hokkaido"
        case .tohoku:
            return "Tohoku"
        case .kanto:
            return "Kanto"
        case .chubu:
            return "Chubu"
        case .kansai:
            return "Kansai"
        case .chugoku:
            return "Chugoku"
        case .shikoku:
            return "Shikoku"
        case .kyushu:
            return "Kyushu"
        }
    }
    
    var jpn: String {
        switch self {
        case .hokkaido:
            return "北海道"
        case .tohoku:
            return "東北"
        case .kanto:
            return "関東"
        case .chubu:
            return "中部"
        case .kansai:
            return "関西"
        case .chugoku:
            return "中国"
        case .shikoku:
            return "四国"
        case .kyushu:
            return "九州"
        }
    }
}



