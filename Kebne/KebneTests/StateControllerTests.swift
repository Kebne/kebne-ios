//
//  StateControllerTests.swift
//  KebneTests
//
//  Created by Emil Lundgren on 2018-10-05.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import XCTest
@testable import Kebne
import Firebase

class StateControllerTests: XCTestCase {
    
    var sut: StateController!
    var mockSignIn: MockGoogleSignIn!
    var mockFirebaseApp: MockFirebaseApp!
    

    override func setUp() {
        mockSignIn = MockGoogleSignIn()
        mockFirebaseApp = MockFirebaseApp()
        
        sut = StateController(locationMonitorService: LocationMonitorService(locationManager: MockLocationManager()),
                              notificationService: NotificationService(networkService: MockNetworkService(),
                                                                       messaging: MockMessaging()),
                              googleSignInHandler: mockSignIn, firebaseApp: mockFirebaseApp)
        
    }

    override func tearDown() {
        mockSignIn = nil
        mockFirebaseApp = nil
        sut = nil
    }

    func testSetupSetsGoogleClientIDAndCorrectScopes() {
        
        let fakeclientid = "fakeclientid"
        let fakeFirebaseOptions = FirebaseOptions(googleAppID: "fakeid", gcmSenderID: "fakesenderid")
        fakeFirebaseOptions.clientID = fakeclientid
        mockFirebaseApp.options = fakeFirebaseOptions
        let correctScope = StateController.Constant.googleFirebaseScope
        
        sut.setup()
        
        XCTAssertEqual(mockSignIn.clientID, fakeclientid)
        XCTAssertTrue(mockSignIn.scopes.filter({$0 is String}).contains(where: {($0 as! String) == correctScope}))
    }

}


class MockGoogleSignIn : GoogleSignInHandler {
    var clientID: String! = ""
    var scopes: [Any]! = [Any]()
}

class MockFirebaseApp : FirebaseAppHandler {
    var options: FirebaseOptions!
}


