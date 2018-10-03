//
//  IntegrationTests.swift
//  KebneTests
//
//  Created by Emil Lundgren on 2018-09-28.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import XCTest
import Firebase
@testable import Kebne

class IntegrationTests: XCTestCase {

    var userController: UserController!
    var mockLocationManager: MockLocationManager!
    var mockNotificationService: MockNotificationService!
    var fakeLocationMonitorService: MockLocationMonitorService!
    var userControllerDelegate: Coordinator!
    
    override func setUp() {
        super.setUp()
        mockLocationManager = MockLocationManager()
        fakeLocationMonitorService = MockLocationMonitorService(locationManager: mockLocationManager)
        mockNotificationService = MockNotificationService(networkService: MockNetworkService())
        userController = TestUserController(locationMonitorService: fakeLocationMonitorService, notificationService: mockNotificationService)
        userController.observeRegionBoundaryCrossing()
        userControllerDelegate = Coordinator()
        userController.delegate = userControllerDelegate
        
    }

    override func tearDown() {
        mockLocationManager = nil
        mockNotificationService = nil
        userController = nil
        fakeLocationMonitorService = nil
        super.tearDown()
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
    
    
    func testThatUserControllerDelegateReceivesBoundaryCrossingNotification() {
        
        userControllerDelegate.didCallHandleNotification = false
        userController.appDidReceiveRemoteNotification(withUserInfo: mockBoundaryCrossingNotificationUserInfo)
        
        XCTAssertTrue(userControllerDelegate.didCallHandleNotification)
    }
    
    func testThatUserControllerDelegateReceivesOtherNotification() {
        
        userControllerDelegate.didCallHandleNotification = false
        userController.appDidReceiveRemoteNotification(withUserInfo: mockOtherNotificationUserInfo)
        
        XCTAssertTrue(userControllerDelegate.didCallHandleNotification)
    }
    
    func testMainViewControllerSwitchRequestsNotificationAuthAndLocationMonitoring() {
        
        let viewControllerFactory = ViewControllerFactoryClass(storyboard: UIStoryboard.main)
        let mainViewController = viewControllerFactory.mainViewController
        mockNotificationService.didRequestAuthForNotifications = false
        fakeLocationMonitorService.didStartMonitoring = false
        mainViewController.userController = userController
        
        let uiSwitch = UISwitch(frame: CGRect.zero)
        uiSwitch.isOn = true
        mainViewController.monitorSwitchDidSwitch(uiSwitch)
        
        XCTAssertTrue(mockNotificationService.didRequestAuthForNotifications && fakeLocationMonitorService.didStartMonitoring)
        
    }
    
    var mockBoundaryCrossingNotificationUserInfo: [AnyHashable: Any] {
        return ["aps":["alert":["body":"testBody","title":"testTitle"],"category":KebneNotification.Category.boundaryCrossing.rawValue],
                "email":"test@test.se".emailWithoutIllegalCharacters]
    }
    
    var mockOtherNotificationUserInfo: [AnyHashable: Any] {
        return ["aps":["alert":["body":"testBody","title":"testTitle"],"category":KebneNotification.Category.other.rawValue],
                "email":"test@test.se".emailWithoutIllegalCharacters]
    }

}

class TestUserController : UserController {
    
    override var user: KebneUser? {
        return KebneUser(name: "testUser", email: "testEmail")
    }

}

class MockNotificationService : NotificationService {

    var userDidEnter: Bool?
    var didRequestAuthForNotifications = false
    
    override func regionBoundaryCrossedBy(user: KebneUser, didEnter: Bool) {
        userDidEnter = didEnter
    }
    
    override func requestAuthForNotifications(completion: @escaping (Bool) -> (), user: KebneUser) {
        didRequestAuthForNotifications = true
        completion(true)
    }
}

class MockLocationMonitorService : LocationMonitorService {
    var didStartMonitoring = false
    override func startMonitorForKebneOfficeRegion(callback: @escaping (Bool) -> (), alocationManager: LocationManager.Type) {
        callback(true)
        didStartMonitoring = true
    }
    
}

class Coordinator : UserControllerDelegate {
    var didCallHandleNotification = false
    
    func handleBoundaryCrossNotificationWith(title: String, body: String, responseHandler: @escaping (String?) -> ()) {
        didCallHandleNotification = true
        responseHandler("Callback")
    }
    
    func didReceiveNotificationWith(title: String, body: String) {
        didCallHandleNotification = true
    }
}
