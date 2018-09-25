//
//  UserControler.swift
//  Kebne
//
//  Created by Emil Lundgren on 2018-09-24.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import Foundation
import GoogleSignIn

class UserController : NSObject {
    var locationMonitorService: LocationMonitorServiceProtocol
    init(locationMonitorService: LocationMonitorServiceProtocol) {
        self.locationMonitorService = locationMonitorService
    }
    
    var user: User? {
        if let currentGoogleUser = GIDSignIn.sharedInstance()?.currentUser {
            return User(name: currentGoogleUser.profile.givenName, email: currentGoogleUser.profile.email)
        }
        return nil
    }
    
    func setup() {
        GIDSignIn.sharedInstance().clientID = Environment.googleSigninClientID
        
    }
    
    func signOut() {
        GIDSignIn.sharedInstance()?.signOut()
    }
    
}




