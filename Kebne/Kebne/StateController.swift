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

protocol GoogleSignInHandler {
    var clientID: String! {get set}
    var scopes: [Any]! {get set}
}

@objc protocol FirebaseAppHandler {
    var options: FirebaseOptions! {get}
}


extension GIDSignIn : GoogleSignInHandler {}
extension FirebaseApp : FirebaseAppHandler {}

class StateController : NSObject {
    let locationMonitorService: LocationMonitorService
    let notificationService: NotificationService
    var googleSignInHandler: GoogleSignInHandler?
    var firebaseApp: FirebaseAppHandler?
    
    weak var delegate: UserControllerDelegate?
    enum Constant {
        static let googleFirebaseScope = "https://www.googleapis.com/auth/firebase.messaging"
    }
    init(locationMonitorService: LocationMonitorService, notificationService: NotificationService,
         googleSignInHandler: GoogleSignInHandler?, firebaseApp: FirebaseAppHandler?) {
        self.locationMonitorService = locationMonitorService
        self.notificationService = notificationService
        self.googleSignInHandler = googleSignInHandler
        self.firebaseApp = firebaseApp
    }
    
    var user: KebneUser? {
        if let currentGoogleUser = GIDSignIn.sharedInstance()?.currentUser {
            return KebneUser(name: currentGoogleUser.profile.givenName, email: currentGoogleUser.profile.email)
        }
        return nil
    }
    
    func setup() {
        UNUserNotificationCenter.current().delegate = self
        guard let firebaseApp = firebaseApp else {return}
        
        googleSignInHandler?.clientID = firebaseApp.options.clientID
        
        var scopes = [Any]()
        if let currentScopes = googleSignInHandler?.scopes {
            scopes.append(contentsOf: currentScopes)
        }
        scopes.append(Constant.googleFirebaseScope)
        googleSignInHandler?.scopes = scopes
    }
    
    func observeRegionBoundaryCrossing() {
        locationMonitorService.registerRegion(observer: self)
    }
    
    func signOut() {
        GIDSignIn.sharedInstance()?.signOut()
    }
    
    //MARK: Handle notifications
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

extension StateController : OfficeRegionObserver {
    func regionStateDidChange(toEntered: Bool) {
        guard let user = user else {return}
        notificationService.regionBoundaryCrossedBy(user: user, didEnter: toEntered)
    }
}

extension StateController : UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let user = user else {
            completionHandler()
            return
        }
        notificationService.handleIncomingNotification(response: response, userName: user.name)
        completionHandler()
    }
    
    
}


