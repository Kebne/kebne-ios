//
//  LocationMonitorServiceTests.swift
//  KebneTests
//
//  Created by Emil Lundgren on 2018-09-26.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import XCTest
import CoreLocation
@testable import Kebne

class LocationMonitorServiceTests: XCTestCase {
    
    var sut: LocationMonitorService!
    var mockLocationManager: MockLocationManager!

    override func setUp() {
        super.setUp()
        mockLocationManager = MockLocationManager()
        sut = LocationMonitorService(locationManager: mockLocationManager)
    }

    override func tearDown() {
        mockLocationManager = nil
        sut = nil
        super.tearDown()
    }

    
    func testCallbackOnIncorrectLocationAuth() {
        MockLocationManager.authStatus = .denied
        var canMonitor = true
        
        sut.startmonitorForKebneOfficeRegion(callback: {(canMonitorRegions) in
            canMonitor = canMonitorRegions
        }, alocationManager: MockLocationManager.self)

        XCTAssertFalse(canMonitor)
    }
    
    func testCallsRequestAuthOnAuthStatusNotDetermined() {
        MockLocationManager.authStatus = .notDetermined
        mockLocationManager.didRequestAuthorization = false
        
        sut.startmonitorForKebneOfficeRegion(callback: {(response) in })
        
        XCTAssertTrue(mockLocationManager.didRequestAuthorization)
    }
    
    func testCallbackOnMonitoringError() {
        MockLocationManager.authStatus = .authorizedAlways
        mockLocationManager.errorOnRegionMonitoring = true
        var successfullyMonitoring = true

        sut.startmonitorForKebneOfficeRegion(callback: {(monitoringSuccess) in
            successfullyMonitoring = monitoringSuccess
   
        }, alocationManager: MockLocationManager.self)
        

        XCTAssertFalse(successfullyMonitoring)
    }
    
    func testStartMonitorCallbackSuccess() {
        MockLocationManager.authStatus = .authorizedAlways
        mockLocationManager.errorOnRegionMonitoring = false
        var successfullyMonitoring = false
     
        sut.startmonitorForKebneOfficeRegion(callback: {(monitoringSuccess) in
            successfullyMonitoring = monitoringSuccess

        }, alocationManager: MockLocationManager.self)

        XCTAssertTrue(successfullyMonitoring)
    }
    
    func testThatMonitoringStartsAfterSuccessfullAuth() {
        
        MockLocationManager.authStatus = .notDetermined
        mockLocationManager.errorOnRegionMonitoring = false
        var startedMonitoring = false
        
        sut.startmonitorForKebneOfficeRegion(callback: {(didStartMonitor) in
            startedMonitoring = didStartMonitor
        }, alocationManager: MockLocationManager.self)
        
        MockLocationManager.authStatus = .authorizedAlways
        mockLocationManager.triggerAuthChangeDelegateCallback()
        XCTAssertTrue(startedMonitoring)
    }
    
    func testThatMonitoringFailsAfterUnsuccessfullAuth() {
        
        MockLocationManager.authStatus = .notDetermined
        mockLocationManager.errorOnRegionMonitoring = false
        var startedMonitoring = false
        
        sut.startmonitorForKebneOfficeRegion(callback: {(didStartMonitor) in
            startedMonitoring = didStartMonitor
        }, alocationManager: MockLocationManager.self)
        
        MockLocationManager.authStatus = .denied
        mockLocationManager.triggerAuthChangeDelegateCallback()
        XCTAssertFalse(startedMonitoring)
    }
    
    func testObserverCallbackWhenStartingMonitoringInOfficeRegion() {
        MockLocationManager.authStatus = .authorizedAlways
        let mockObserver = MockRegionObserver()
        mockObserver.isInRegion = false
        mockLocationManager.shouldSendInOfficeRegionCoordinates = true
        sut.registerRegion(observer: mockObserver)
        
        sut.startmonitorForKebneOfficeRegion(callback: {(isMonitoring) in }, alocationManager: MockLocationManager.self)
        
        XCTAssertTrue(mockObserver.isInRegion)
    }

}


class MockLocationManager : LocationManager {
    
    enum TestError : Error {
        case failure
    }
    
    static var authStatus: CLAuthorizationStatus = .notDetermined
    static var regionMonitoringAvailable = true
    var errorOnRegionMonitoring = false
    var locationManager: CLLocationManager = CLLocationManager()
    var didRequestAuthorization = false
    var shouldSendInOfficeRegionCoordinates = false
    
    static func authorizationStatus() -> CLAuthorizationStatus {
        return authStatus
    }
    
    static func isMonitoringAvailable(for regionClass: AnyClass) -> Bool {
        return regionMonitoringAvailable
    }
    
    func startMonitoring(for region: CLRegion) {
        if let delegate = delegate {
            if errorOnRegionMonitoring {
                delegate.locationManager!(locationManager, monitoringDidFailFor: region, withError: TestError.failure)
            } else {
                monitoredRegions.insert(region)
                delegate.locationManager!(locationManager, didStartMonitoringFor: region)
            }
        }
    }
    
    func stopMonitoring(for region: CLRegion) {
        
    }
    
    func requestAlwaysAuthorization() {
        didRequestAuthorization = true
    }
    
    func triggerAuthChangeDelegateCallback() {
        delegate?.locationManager!(locationManager, didChangeAuthorization: MockLocationManager.authorizationStatus())
    }
    
    func requestLocation() {
        if shouldSendInOfficeRegionCoordinates {
            delegate?.locationManager!(locationManager, didUpdateLocations: [CLLocation(latitude: CLLocationCoordinate2D.oxtorgsgatan8Coordinate.latitude, longitude: CLLocationCoordinate2D.oxtorgsgatan8Coordinate.longitude)])
        } else {
            delegate?.locationManager!(locationManager, didUpdateLocations: [CLLocation(latitude: 0.0, longitude: 0.0)])
        }
        
    }
    
    var monitoredRegions: Set<CLRegion> = Set<CLRegion>()
    
    var delegate: CLLocationManagerDelegate?
}

class MockRegionObserver : OfficeRegionObserver {
    
    var isInRegion = true
    
    func regionStateDidChange(toEntered: Bool) {
        isInRegion = toEntered
    }
    
    
}
