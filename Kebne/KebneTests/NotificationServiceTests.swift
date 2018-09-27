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

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    
    func testThatItDecodesNotificationMessagesCorrectly() {
        
        let testTopic = "testTopic"
        let testTitle = "testTitle"
        let testBody = "testBody"
        let notification = KebneNotification(topic: testTopic, title: testTitle, body: testBody)
  
        
        guard let data = try? JSONEncoder().encode(notification) else {
            XCTFail("Notification couldn't be encoded to JSON")
            return
        }
        
        guard let decodedJson = try? JSONDecoder().decode(KebneNotification.self, from: data) else {
            XCTFail("Couldn't decode data back to KebneNotification")
            return
        }
       
        
        XCTAssertEqual(notification.body, decodedJson.body)
        XCTAssertEqual(notification.title, decodedJson.title)
        XCTAssertEqual(notification.topic, decodedJson.topic)
    }
    

}
