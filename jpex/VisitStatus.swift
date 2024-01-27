//
//  VisitStatus.swift
//  jpex
//
//  Created by Terran Kroft on 26/1/2024.
//

import Foundation

typealias VisitCode = Int

enum VisitStatus: VisitCode {
    case never = 0
    case passed = 1
    case alighted = 2
    case visited = 3
    case stayed = 4
    case lived = 5
    
    
}
