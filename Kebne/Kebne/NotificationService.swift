//
//  NotificationService.swift
//  Kebne
//
//  Created by Emil Lundgren on 2018-09-27.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import UIKit
import UserNotifications
import Firebase
import GoogleSignIn

extension String {
    var emailWithoutIllegalCharacters : String {
        return self.replacingOccurrences(of: "@", with: "").replacingOccurrences(of: ".", with: "")
    }
}



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



class NotificationService: NSObject {
    
    let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    //MARK: Auth and setup
    func requestAuthForNotifications(completion: @escaping (Bool)->(), user: KebneUser) {
        
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler:{[weak self](settings) in
            if settings.authorizationStatus == .notDetermined {
                let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {(granted, _) in
                    if granted {
                        self?.subscribeToFirebaseMessaging(user: user)
                    }
                    completion(granted)
                })
            } else if settings.authorizationStatus == .denied {
                completion(false)
            } else {
                completion(true)
                self?.subscribeToFirebaseMessaging(user: user)
            }
        })
        
    }
    
    func subscribeToFirebaseMessaging(user: KebneUser) {
        
        Messaging.messaging().subscribe(toTopic: BoundaryCrossing.didEnterTopic)
        Messaging.messaging().subscribe(toTopic: BoundaryCrossing.didExitTopic)
        Messaging.messaging().subscribe(toTopic: user.email.emailWithoutIllegalCharacters)
    }
    
    func setup() {
        
        Messaging.messaging().delegate = self

        let greetWithTextField = UNTextInputNotificationAction(identifier: KebneNotification.greetingAction, title: KebneAppStrings.boundaryCrossingNotificationPlaceholder,
                                                               options: .destructive, textInputButtonTitle: KebneAppStrings.boundaryCrossingNotificationOkTitle, textInputPlaceholder: KebneAppStrings.boundaryCrossingNotificationPlaceholder)

        let boundaryCrossingCategory =
            UNNotificationCategory(identifier: KebneNotification.Category.boundaryCrossing.rawValue,
                                   actions: [greetWithTextField],
                                   intentIdentifiers: [],
                                   hiddenPreviewsBodyPlaceholder: "",
                                   options: .customDismissAction)
  
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([boundaryCrossingCategory])
    }
    
    //MARK: Notifications
    
    func regionBoundaryCrossedBy(user: KebneUser, didEnter: Bool) {
        let boundaryCrossing = BoundaryCrossing(didEnter: didEnter, userName: user.name, isLocal: true)
        let localNotification = KebneNotification(title: boundaryCrossing.notificationTitle, body: boundaryCrossing.notificationBody)
        sendLocal(notification: localNotification)
        let localBoundaryCrossing = BoundaryCrossing(didEnter: didEnter, userName: user.name)
        let notification = KebneNotification(localizedTitle: localBoundaryCrossing.notificationTitle, localizedBody: localBoundaryCrossing.notificationBody,
                                             topic: localBoundaryCrossing.notificationTopic, userEmail: user.email, category: .boundaryCrossing, userName: user.name)
        handleRemote(notification: notification)
        
    }
    
    func respondTo(notification: KebneNotification, userName: String, greeting: String) {
        var responseNotification = KebneNotification(title: "", body: greeting,
                                                     topic: notification.userEmail, userEmail: "", category: .other, userName: userName)
        responseNotification.localizedTitle = "notification.greeting.title"
        handleRemote(notification: responseNotification)
    }
    
    func handleIncomingNotification(response: UNNotificationResponse, userName: String) {
        guard let textResponse = response as? UNTextInputNotificationResponse else {
            return
        }
        do {
            let notification = try notificationFrom(userInfo: response.notification.request.content.userInfo)
            respondTo(notification: notification, userName: userName, greeting: textResponse.userText)
        } catch let e {
            print("Error decoding incoming notification response: \(e)")
        }
        
    }
    
    func notificationFrom(userInfo: [AnyHashable: Any]) throws ->KebneNotification  {
        let data = try JSONSerialization.data(withJSONObject: userInfo, options: [])
        let notification = try JSONDecoder().decode(KebneNotification.self, from: data)
        return notification
    }
    
    //MARK: Private
    
    private func handleRemote(notification: KebneNotification) {
        
        do {
            let data = try JSONEncoder().encode(notification)
            networkService.sendGoogleCloudMessage(data: data)
        } catch let e {
            print("Error encoding json: \(e)")
        }
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



extension NotificationService : MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Did receive remote message.")
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Messaging did receive registration token: \(fcmToken)")
    }
}

