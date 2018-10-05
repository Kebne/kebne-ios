//
//  BoundaryCrossing.swift
//  Kebne
//
//  Created by Emil Lundgren on 2018-10-04.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import Foundation

enum BoundaryCrossing {
    case didEnter
    case didExit
    case didEnterLocal(String)
    case didExitLocal(String)
    
    static let didEnterTopic = "didEnter"
    static let didExitTopic = "didExit"
    
    init(didEnter: Bool, userName: String, isLocal: Bool = false) {
        if isLocal {
            self = didEnter ? .didEnterLocal(userName) : .didExitLocal(userName)
        } else {
            self = didEnter ? .didEnter : .didExit
        }
        
    }
    
    var notificationBody: String {
        switch self {
        case .didEnter:
            return "notification.boundarycrossing.enter.body"
        case .didExit:
            return "notification.boundarycrossing.exit.body"
        case .didEnterLocal:
            return NSLocalizedString("localnotification.boundarycrossing.enter.body", comment: "")
        case .didExitLocal:
            return NSLocalizedString("localnotification.boundarycrossing.exit.body", comment: "")
        }
    }
    
    var notificationTitle: String {
        switch self {
        case .didEnter:
            return "notification.boundarycrossing.enter.title"
        case .didExit:
            return "notification.boundarycrossing.exit.title"
        case .didEnterLocal(let userName):
            return String(format: NSLocalizedString("localnotification.boundarycrossing.enter.title", comment: ""), userName)
        case .didExitLocal(let userName):
            return String(format: NSLocalizedString("localnotification.boundarycrossing.exit.title", comment: ""), userName)
        }
    }
    
    var notificationTopic: String {
        switch self {
        case .didEnter:
            return BoundaryCrossing.didEnterTopic
        case .didExit:
            return BoundaryCrossing.didExitTopic
        default: return ""
        }
        
    }
}
