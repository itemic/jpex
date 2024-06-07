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
            .never, //VISIT_hokkaido,0
            .never, //VISIT_aomori,1
            .never, //VISIT_iwate,2
            .never, //VISIT_miyagi,3
            .never, //VISIT_akita,4
            .never, //VISIT_yamagat5a,
            .never, //VISIT_fukushim6a,
            .never, //VISIT_ibaraki,7
            .never, //VISIT_tochigi,8
            .never, //VISIT_gunma,9
            .never, //VISIT_saitama10,
            .never, //VISIT_chiba,11
            .never, //VISIT_tokyo,12
            .never, //VISIT_kanagawa13,
            .never, //VISIT_niigata,14
            .never, //VISIT_toyama,15
            .never, //VISIT_ishikawa,16
            .never, //VISIT_fukui,17
            .never, //VISIT_yamanash18i,
            .never, //VISIT_nagano,19
            .never, //VISIT_gifu,20
            .never, //VISIT_shizuok21a,
            .never, //VISIT_aichi,22
            .never, //VISIT_mie,23
            .never, //VISIT_shiga,24
            .never, //VISIT_kyoto,25
            .never, //VISIT_osaka,26
            .never, //VISIT_hyogo,27
            .never, //VISIT_nara,28
            .never, //VISIT_wakayam29a,
            .never, //VISIT_tottori,30
            .never, //VISIT_shimane,31
            .never, //VISIT_okayama,32
            .never, //VISIT_hiroshima,33
            .never, //VISIT_yamaguchi,34
            .never, //VISIT_tokushima,35
            .never, //VISIT_kagawa,36
            .never, //VISIT_ehime,37
            .never, //VISIT_kochi,38
            .never, //VISIT_fukuoka,39
            .never, //VISIT_saga,40
            .never, //VISIT_nagasaki,41
            .never, //VISIT_kumamoto,42
            .never, //VISIT_oita,43
            .never, //VISIT_miyagi,44
            .never, //VISIT_kagoshima45,
            .never, //VISIT_okinawa46
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
