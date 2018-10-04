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

