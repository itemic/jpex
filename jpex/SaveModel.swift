//
//  SaveModel.swift
//  jpex
//
//  Created by Terran Kroft on 27/1/2.never24.
//

import Foundation
import SwiftData
import SwiftUI

@Model class SaveModel {
    
    var visitStatus: [VisitStatus] = []
    
    init() {
        visitStatus = [
            .never, //VISIT_hokkaido,
            .never, //VISIT_aomori,
            .never, //VISIT_iwate,
            .never, //VISIT_miyagi,
            .never, //VISIT_akita,
            .never, //VISIT_yamagata,
            .never, //VISIT_fukushima,
            .never, //VISIT_ibaraki,
            .never, //VISIT_tochigi,
            .never, //VISIT_gunma,
            .never, //VISIT_saitama,
            .never, //VISIT_chiba,
            .never, //VISIT_tokyo,
            .never, //VISIT_kanagawa,
            .never, //VISIT_niigata,
            .never, //VISIT_toyama,
            .never, //VISIT_ishikawa,
            .never, //VISIT_fukui,
            .never, //VISIT_yamanashi,
            .never, //VISIT_nagano,
            .never, //VISIT_gifu,
            .never, //VISIT_shizuoka,
            .never, //VISIT_aichi,
            .never, //VISIT_mie,
            .never, //VISIT_shiga,
            .never, //VISIT_kyoto,
            .never, //VISIT_osaka,
            .never, //VISIT_hyogo,
            .never, //VISIT_nara,
            .never, //VISIT_wakayama,
            .never, //VISIT_tottori,
            .never, //VISIT_shimane,
            .never, //VISIT_okayama,
            .never, //VISIT_hiroshima,
            .never, //VISIT_yamaguchi,
            .never, //VISIT_tokushima,
            .never, //VISIT_kagawa,
            .never, //VISIT_ehime,
            .never, //VISIT_kochi,
            .never, //VISIT_fukuoka,
            .never, //VISIT_saga,
            .never, //VISIT_nagano,
            .never, //VISIT_kumamoto,
            .never, //VISIT_oita,
            .never, //VISIT_miyagi,
            .never, //VISIT_kagoshima,
            .never, //VISIT_okinawa
        ]
    }
    
    
}

enum VisitStatus: CaseIterable, Identifiable, Codable {
    case never
    case passed
    case alighted
    case visited
    case stayed
    case lived
    
    
    var id: Self { self }
    
    var next: VisitStatus {
        switch self {
        case .never:
            return .passed
        case .passed:
            return .alighted
        case .alighted:
            return .visited
        case .visited:
            return .stayed
        case .stayed:
            return .lived
        case .lived:
            return .never
        }
    }
    
    var color: Color {
        switch self {
        case .never:
            return .gray
        case .passed:
            return .sdgBlue
        case .alighted:
            return .sdgGreen
        case .visited:
            return .sdgYellow
        case .stayed:
            return .sdgOrange
        case .lived:
            return .sdgRed
        }
    
    }
    
    var text: String {
        switch self {
        case .never:
            return "Never been"
        case .passed:
            return "Passed"
        case .alighted:
            return "Alighted"
        case .visited:
            return "Visited"
        case .stayed:
            return "Stayed"
        case .lived:
            return "Lived"
        }
    }
    
    var score: Int {
        switch self {
        case .never:
            return 0
        case .passed:
            return 1
        case .alighted:
            return 2
        case .visited:
            return 3
        case .stayed:
            return 4
        case .lived:
            return 5
        }
    }
    
    
}
