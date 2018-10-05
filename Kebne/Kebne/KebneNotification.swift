//
//  KebneNotification.swift
//  Kebne
//
//  Created by Emil Lundgren on 2018-10-04.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import Foundation
import UserNotifications

struct KebneNotification {
    let topic: String
    let body: String
    let title: String
    var localizedBody: String?
    var localizedTitle: String?
    let category: Category
    let userName: String
    let userEmail: String
    
    enum Category : String {
        case boundaryCrossing = "BOUNDARYCROSSING_CATEGORY"
        case other = "OTHER_CATEGORY"
    }
    
    static let greetingAction = "GREETING_ACTION"
    
    enum DataKeys : CodingKey {
        case email
    }
    
    enum PayloadKeys : CodingKey {
        case aps
    }
    
    enum APSKeys :String, CodingKey {
        case category = "category"
        case alert = "alert"
    }
    
    enum MessageKeys: CodingKey {
        case topic
        case notification
        case data
        case apns
    }
    
    enum APNSKeys : CodingKey {
        case payload
    }
    
    enum RootKeys: CodingKey {
        case message
    }
    
    enum NotificationResponseKeys : CodingKey {
        case email
        case aps
    }
    
    enum NotificationResponseAPSKeys : CodingKey {
        case alert
        case category
    }
    
    enum AlertKeys : String, CodingKey {
        case title = "title"
        case body = "body"
        case localizedTitle = "title-loc-key"
        case localizedBody = "loc-key"
        case titleArg = "title-loc-args"
        case bodyArg = "loc-args"
    }
    
    init(title: String, body: String, topic: String, userEmail: String, category: Category, userName: String) {
        self.title = title
        self.body = body
        self.topic = topic
        self.userEmail = userEmail.emailWithoutIllegalCharacters
        self.category = category
        self.userName = userName
    }
    
    init(localizedTitle: String, localizedBody: String, topic: String, userEmail: String, category: Category, userName: String) {
        self.title = localizedTitle
        self.body = localizedBody
        self.localizedTitle = localizedTitle
        self.localizedBody = localizedBody
        self.topic = topic
        self.userEmail = userEmail.emailWithoutIllegalCharacters
        self.category = category
        self.userName = userName
    }
    
    init(title: String, body: String) {
        self.init(title: title, body: body, topic: "", userEmail: "", category: .other, userName: "")
    }
    
    init(title: String, body: String, topic: String) {
        self.init(title: title, body: body, topic: topic, userEmail: "", category: .other, userName: "")
    }
    
    var localNotificationContent: UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.body = body
        content.title = title
        content.sound = UNNotificationSound.default
        return content
    }
}

extension KebneNotification : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NotificationResponseKeys.self)
        userEmail = try container.decode(String.self, forKey: .email)
        let apsContainer = try container.nestedContainer(keyedBy: APSKeys.self, forKey: .aps)
        let alertContainer = try apsContainer.nestedContainer(keyedBy: AlertKeys.self, forKey: .alert)
        localizedTitle = try? alertContainer.decode(String.self, forKey: .localizedTitle)
        localizedBody = try? alertContainer.decode(String.self, forKey: .localizedBody)
        let aBody = try? alertContainer.decode(String.self, forKey: .body)
        let aTitle = try? alertContainer.decode(String.self, forKey: .title)
        let bodyArg = try? alertContainer.decode([String].self, forKey: .bodyArg)
        let titleArg = try? alertContainer.decode([String].self, forKey: .titleArg)
        userName = bodyArg?.first ?? titleArg?.first ?? ""
        if let locTitle = localizedTitle {
            title = String(format: NSLocalizedString(locTitle, comment: ""), userName)
        } else {
            title = aTitle ?? ""
        }
        if let locBody = localizedBody {
            body = String(format: NSLocalizedString(locBody, comment: ""), userName)
        } else {
            body = aBody ?? ""
        }
        topic = ""
        let unwrappedCategoryString = try? apsContainer.decode(String.self, forKey:.category)
        let unwrappedCategory = Category(rawValue: unwrappedCategoryString ?? "")
        category = unwrappedCategory ?? .other
    }
}

extension KebneNotification : Encodable {
    func encode(to encoder: Encoder) throws
    {
        var dataContainer = encoder.container(keyedBy: RootKeys.self)
        var messageContainer = dataContainer.nestedContainer(keyedBy: MessageKeys.self, forKey: .message)
        try messageContainer.encode(topic, forKey: .topic)
        var extendedDataContainer = messageContainer.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
        try extendedDataContainer.encode(userEmail, forKey: .email)
        var apnsContainer = messageContainer.nestedContainer(keyedBy: APNSKeys.self, forKey: .apns)
        var payloadContainer = apnsContainer.nestedContainer(keyedBy: PayloadKeys.self, forKey: .payload)
        var apsContainer = payloadContainer.nestedContainer(keyedBy: APSKeys.self, forKey: .aps)
        try apsContainer.encode(category.rawValue, forKey: .category)
        var alertContainer = apsContainer.nestedContainer(keyedBy: AlertKeys.self, forKey: .alert)
        if let locTitle = localizedTitle {
            try alertContainer.encode(locTitle, forKey: .localizedTitle)
            try alertContainer.encode([userName], forKey: .titleArg)
        } else {
            try alertContainer.encode(title, forKey: .title)
        }
        
        if let locBody = localizedBody {
            try alertContainer.encode(locBody, forKey: .localizedBody)
            try alertContainer.encode([userName], forKey: .bodyArg)
        } else {
            try alertContainer.encode(body, forKey: .body)
        }
    }
}
