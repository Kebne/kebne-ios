//
//  NotificationService.swift
//  Kebne
//
//  Created by Emil Lundgren on 2018-09-27.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import UIKit
import UserNotifications


struct KebneNotification {

    let topic: String
    let title: String
    let body: String
    
    enum NotificationKeys : CodingKey {
        case title
        case body
    }
    
    enum MessageKeys: CodingKey {
        case topic
        case notification
    }
    
    enum RootKeys: CodingKey {
        case message
    }
    
    init(user: User, didEnter: Bool) {
        let boundaryCrossing = BoundaryCrossing(didEnter: didEnter, user: user)
        title = boundaryCrossing.notificationTitle
        body = boundaryCrossing.notificationBody
        topic = boundaryCrossing.notificationTopic
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
        let container = try decoder.container(keyedBy: RootKeys.self)
        let messageContainer = try container.nestedContainer(keyedBy: MessageKeys.self, forKey: .message)
        topic = try messageContainer.decode(String.self, forKey: .topic)
        let notificationContainer = try messageContainer.nestedContainer(keyedBy: NotificationKeys.self, forKey: .notification)
        title = try notificationContainer.decode(String.self, forKey: .title)
        body = try notificationContainer.decode(String.self, forKey: .body)
    }
}

extension KebneNotification : Encodable {
    func encode(to encoder: Encoder) throws
    {
        var dataContainer = encoder.container(keyedBy: RootKeys.self)
        var messageContainer = dataContainer.nestedContainer(keyedBy: MessageKeys.self, forKey: .message)
        try messageContainer.encode(topic, forKey: .topic)
        var notificationContainer = messageContainer.nestedContainer(keyedBy: NotificationKeys.self, forKey: .notification)
        try notificationContainer.encode(title, forKey: .title)
        try notificationContainer.encode(body, forKey: .body)
    }
}

extension KebneNotification {
    enum BoundaryCrossing {
        case didEnter(User)
        case didExit(User)
        
        init(didEnter: Bool, user: User) {
            self = didEnter ? .didEnter(user) : .didExit(user)
        }
        
        var notificationBody: String {
            switch self {
            case .didEnter(let user):
                return user.name + " är på kontoret"
            case .didExit(let user):
                return user.name + " har lämnat kontoret"
            }
        }
        
        var notificationTitle: String {
            switch self {
            case .didEnter(_):
                return "Någon är på kontoret."
            case .didExit(_):
                return "Någon har lämnat kontoret."
            }
        }
        
        var notificationTopic: String {
            switch self {
            case .didEnter(_):
                return "topic/didEnter"
            case .didExit(_):
                return "topic/didExit"
            }
        }
    }
}



class NotificationService: NSObject {

    func requestAuthForNotifications(completion: @escaping (Bool)->()) {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: {(settings) in
            if settings.authorizationStatus == .notDetermined {
                let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {(granted, _) in
                    completion(granted)
                })
            } else if settings.authorizationStatus == .denied {
                completion(false)
            } else {
                completion(true)
            }
        })
        
    }
    
    func regionBoundaryCrossedBy(user: User, didEnter: Bool) {
        let notification = KebneNotification(user: user, didEnter: didEnter)
        sendLocal(notification: notification)
        do {
            let data = try JSONEncoder().encode(notification)
            postRemoteNotification(data: data)
        } catch let e {
            print("Error encoding json: \(e)")
        }
    }
    
    private func postRemoteNotification(data: Data) {
        
    }
    
    private func sendLocal(notification: KebneNotification) {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: {(settings) in
            guard settings.authorizationStatus == .authorized else {return}
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1,
                                                            repeats: false)
            let request = UNNotificationRequest(identifier: "LocalNotification", content: notification.localNotificationContent, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        })
        
    }
    
}


extension NotificationService : UNUserNotificationCenterDelegate {
    
}
