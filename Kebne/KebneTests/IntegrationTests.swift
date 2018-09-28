//
//  IntegrationTests.swift
//  KebneTests
//
//  Created by Emil Lundgren on 2018-09-28.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import XCTest
@testable import Kebne

class IntegrationTests: XCTestCase {

    var userController: UserController!
    var mockLocationManager: MockLocationManager!
    var mockNotificationService: MockNotificationService!
    var fakeLocationMonitorService: LocationMonitorService!
    
    override func setUp() {
        super.setUp()
        mockLocationManager = MockLocationManager()
        fakeLocationMonitorService = LocationMonitorService(locationManager: mockLocationManager)
        mockNotificationService = MockNotificationService()
        userController = TestUserController(locationMonitorService: fakeLocationMonitorService, notificationService: mockNotificationService)
        userController.observeRegionBoundaryCrossing()
        
    }

    override func tearDown() {
        mockLocationManager = nil
        mockNotificationService = nil
        userController = nil
        fakeLocationMonitorService = nil
    }

    func testThatNotificationServiceReceivesBoundaryCrossingChanges() {
        
        var shouldReceiveUserDidEnter: Bool?
        var shouldReceiveUserDidExit: Bool?
        
        mockLocationManager.triggerDidEnterRegion(true)
        shouldReceiveUserDidEnter = mockNotificationService.userDidEnter
        mockNotificationService.userDidEnter = nil
        
        mockLocationManager.triggerDidEnterRegion(false)
        shouldReceiveUserDidExit = mockNotificationService.userDidEnter
        
        guard let enter = shouldReceiveUserDidEnter else {
            XCTFail("Notification service didn't receive callback when region was entered")
            return
        }
        
        guard let exit = shouldReceiveUserDidExit else {
            XCTFail("Notification service didn't receive callback when region was exited")
            return
        }
        
        XCTAssertTrue(enter)
        XCTAssertFalse(exit)
        
    }
    
    
    

}

class TestUserController : UserController {
    
    override var user: User? {
        return User(name: "testUser", email: "testEmail")
    }

}

class MockNotificationService : NotificationService {

    var userDidEnter: Bool?
    
    override func regionBoundaryCrossedBy(user: User, didEnter: Bool) {
        userDidEnter = didEnter
    }
}
