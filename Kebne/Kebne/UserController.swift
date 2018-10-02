//
//  UserControler.swift
//  Kebne
//
//  Created by Emil Lundgren on 2018-09-24.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import Foundation
import GoogleSignIn
import Firebase
import UserNotifications

protocol UserControllerDelegate : AnyObject {
    func handleBoundaryCrossNotificationWith(title: String, body: String, responseHandler: @escaping (String?)->())
    func didReceiveNotificationWith(title: String, body: String)
}

protocol KebneNotificationResponder {
    func appDidReceiveRemoteNotification(withUserInfo userInfo: [AnyHashable: Any])
}

class UserController : NSObject {
    var locationMonitorService: LocationMonitorService
    var notificationService: NotificationService
    weak var delegate: UserControllerDelegate?
    enum Constant {
        static let googleFirebaseScope = "https://www.googleapis.com/auth/firebase.messaging"
    }
    init(locationMonitorService: LocationMonitorService, notificationService: NotificationService) {
        self.locationMonitorService = locationMonitorService
        self.notificationService = notificationService
    }
    
    var user: User? {
        if let currentGoogleUser = GIDSignIn.sharedInstance()?.currentUser {
            return User(name: currentGoogleUser.profile.givenName, email: currentGoogleUser.profile.email)
        }
        return nil
    }
    
    func googleSetup() {
        UNUserNotificationCenter.current().delegate = self
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        
        var scopes = [Any]()
        if let currentScopes = GIDSignIn.sharedInstance()?.scopes {
            scopes.append(contentsOf: currentScopes)
        }
        scopes.append(Constant.googleFirebaseScope)
        GIDSignIn.sharedInstance()?.scopes = scopes
        notificationService.setup()
        
    }
    
    func observeRegionBoundaryCrossing() {
        locationMonitorService.registerRegion(observer: self)
    }
    
    func signOut() {
        GIDSignIn.sharedInstance()?.signOut()
    }
    
    
    
}

extension UserController : KebneNotificationResponder {
    func appDidReceiveRemoteNotification(withUserInfo userInfo: [AnyHashable: Any]) {
        do {
            print("Remote notification: \(userInfo)")
            let kebneNotification = try notificationService.notificationFrom(userInfo: userInfo)
            switch kebneNotification.category {
            case .boundaryCrossing:
                delegate?.handleBoundaryCrossNotificationWith(title: kebneNotification.title, body: kebneNotification.body) {[unowned self] response in
                    guard let response = response, let user = self.user else {return}
                    self.notificationService.respondTo(notification: kebneNotification, userName: user.name, greeting: response)
                }
            case .other:
                delegate?.didReceiveNotificationWith(title: kebneNotification.title, body: kebneNotification.body)
            }
            
        } catch let e {
            print("Error handling notification user info: \(e)")
        }
    }
}

extension UserController : OfficeRegionObserver {
    func regionStateDidChange(toEntered: Bool) {
        guard let user = user else {return}
        notificationService.regionBoundaryCrossedBy(user: user, didEnter: toEntered)
    }
    
    
}

extension UserController : UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let user = user else {
            completionHandler()
            return
        }
        notificationService.handleIncomingNotification(response: response, userName: user.name)
        completionHandler()
    }
    
    
}


