//
//  NotificationServiceTests.swift
//  KebneTests
//
//  Created by Emil Lundgren on 2018-09-27.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import XCTest
@testable import Kebne

class NotificationServiceTests: XCTestCase {
    
    var sut: NotificationService!
    var mockNetworkService: MockNetworkService!
    var mockMessaging: MockMessaging!

    override func setUp() {
        mockNetworkService = MockNetworkService()
        mockMessaging = MockMessaging()
        sut = NotificationService(networkService: mockNetworkService, messaging: mockMessaging)
    }

    override func tearDown() {
        sut = nil
    }

    
    func testThatItDecodesNotificationMessagesCorrectly() {

       let notification = KebneNotification(title: "testTitle", body: "testBody", topic: "testTopic", userEmail: "test@test.se", category: .other, userName: "Testuser")
        let notificationData: [AnyHashable:Any] = ["aps":["alert":["body":"testBody","title":"testTitle"],"category":KebneNotification.Category.other.rawValue],
                                                   "email":"test@test.se".emailWithoutIllegalCharacters]
  
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: notificationData, options: [])
            do {
                let decodedJson = try JSONDecoder().decode(KebneNotification.self, from: jsonData)
                XCTAssertEqual(notification.body, decodedJson.body)
                XCTAssertEqual(notification.title, decodedJson.title)
                XCTAssertEqual(notification.userEmail, decodedJson.userEmail)
            } catch let e {
                XCTFail("Couldn't decode data back to KebneNotification: \(e)")
            }
        } catch let e {
            XCTFail("Couldn't serialize test notification data: \(e)")
        }
    }
    
    
    func testThatItCreatesBoundaryCrossCloudMessage() {
        
        mockNetworkService.receivedData = nil
        sut.regionBoundaryCrossedBy(user: fakeUser, didEnter: true)
        
        XCTAssertNotNil(mockNetworkService.receivedData)
    }
    
    func testNotificationIsCorrectWhenDidEnter() {
        
        mockNetworkService.receivedData = nil
        sut.regionBoundaryCrossedBy(user: fakeUser, didEnter: true)
        
        guard let data = mockNetworkService.receivedData,
            let string = String(data: data, encoding: .utf8) else {
                XCTFail("Network service didn't revice correct data")
                return
        }
        
        XCTAssertTrue(string.contains(BoundaryCrossing.didEnter.notificationTitle))
        
    }
    
    func testNotificationIsCorrectWhenDidExit() {
        
        mockNetworkService.receivedData = nil
        sut.regionBoundaryCrossedBy(user: fakeUser, didEnter: false)
        
        guard let data = mockNetworkService.receivedData,
            let string = String(data: data, encoding: .utf8) else {
                XCTFail("Network service didn't revice correct data")
                return
        }
        
        XCTAssertTrue(string.contains(BoundaryCrossing.didExit.notificationTitle))
        
    }
    
    func testThatItCreatesNotificationResponse() {
        mockNetworkService.receivedData = nil
        let kebneNotification = KebneNotification(localizedTitle: "title", localizedBody: "body", topic: "topic", userEmail: "test@test.se", category: .other, userName: "Emil")
        sut.respondTo(notification: kebneNotification, userName: "LocalUser", greeting: "Hey")
        
        XCTAssertNotNil(mockNetworkService.receivedData)
    }
    
    func testThatItSubscribesToCorrectTopics() {
        mockMessaging.clearSubscriptions()
        sut.subscribeToFirebaseMessaging(user: fakeUser)
        
        XCTAssertTrue(mockMessaging.subscribedTopics.contains(BoundaryCrossing.didExitTopic))
        XCTAssertTrue(mockMessaging.subscribedTopics.contains(BoundaryCrossing.didExitTopic))
        XCTAssertTrue(mockMessaging.subscribedTopics.contains(fakeUser.email.emailWithoutIllegalCharacters))
    }
    
    
    var fakeUser: KebneUser {
        return KebneUser(name: "user", email: "user@email.com")
    }

}

class MockNetworkService : NetworkServiceProtocol {
    
    var receivedData: Data?
    
    func sendGoogleCloudMessage(data: Data) {
        receivedData = data
    }
}

class MockMessaging : FirebaseMessaging {
    
    var subscribedTopics = [String]()
    
    func subscribe(toTopic: String) {
        subscribedTopics.append(toTopic)
    }
    
    func clearSubscriptions() {
        subscribedTopics.removeAll()
    }
}
