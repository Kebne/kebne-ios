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

class UserController : NSObject {
    var locationMonitorService: LocationMonitorService
    var notificationService: NotificationService
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
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        
        var scopes = [Any]()
        if let currentScopes = GIDSignIn.sharedInstance()?.scopes {
            scopes.append(contentsOf: currentScopes)
        }
        scopes.append(Constant.googleFirebaseScope)
        GIDSignIn.sharedInstance()?.scopes = scopes
        
    }
    
    func observeRegionBoundaryCrossing() {
        locationMonitorService.registerRegion(observer: self)
    }
    
    func signOut() {
        GIDSignIn.sharedInstance()?.signOut()
    }
    
}

extension UserController : OfficeRegionObserver {
    func regionStateDidChange(toEntered: Bool) {
        guard let user = user else {return}
        notificationService.regionBoundaryCrossedBy(user: user, didEnter: toEntered)
    }
    
    
}




