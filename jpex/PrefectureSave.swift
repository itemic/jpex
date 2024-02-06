//
//  PrefectureSave.swift
//  jpex
//
//  Created by Terran Kroft on 5/2/2024.
//

import Foundation
import SwiftData
import SwiftUI

@Model class PrefectureSave {
    var id: Int
    var status: VisitStatus
    
    init(id: Int, status: VisitStatus) {
        self.id = id
        self.status = status
    }
}


