//
//  LocationMonitorService.swift
//  Kebne
//
//  Created by Emil Lundgren on 2018-09-25.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import Foundation
import CoreLocation

protocol OfficeRegionObserver : class {
    func regionStateDidChange(toEntered: Bool)
}

protocol LocationMonitorServiceProtocol {
    typealias StartRegionMonitorCallback = (Bool)->()
    func startmonitorForKebneOfficeRegion(callback: @escaping StartRegionMonitorCallback)
    func stopmonitorForKebneOfficeRegion()
    var isMonitoringForKebneOfficeRegion: Bool {get}
    var isInRegion: Bool {get}
    func canMonitorForRegions() ->Bool
    func registerRegion(observer: OfficeRegionObserver)
    init(locationManager: CLLocationManager)
}

extension CLRegion {
    
    static var kebneOfficeRegion : CLCircularRegion {
        return CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), radius: 50, identifier:LocationMonitorService.Constant.kebneOfficeRegionIdentifier)
    }
}

class LocationMonitorService : NSObject, LocationMonitorServiceProtocol {
    
    fileprivate enum Constant {
        static let kebneOfficeRegionIdentifier = "com.kebneapp.kebneOfficeRegionIdentifier"
    }
    
    private var observers = [OfficeRegionObserver]()
    private var locationManager: CLLocationManager
    fileprivate var startMonitoringCallback: StartRegionMonitorCallback?
    
    required init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
        super.init()
    }
    
    func canMonitorForRegions() -> Bool {
        return CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.classForCoder())
    }
    
    func startmonitorForKebneOfficeRegion(callback: @escaping (Bool) -> ()) {
        guard CLLocationManager.authorizationStatus() == .authorizedAlways else {
            callback(false)
            return
        }
        startMonitoringCallback = callback
        locationManager.startMonitoring(for: CLRegion.kebneOfficeRegion)
    }
    
    func stopmonitorForKebneOfficeRegion() {
        locationManager.stopMonitoring(for: CLRegion.kebneOfficeRegion)
    }
    
    var isMonitoringForKebneOfficeRegion: Bool {
        return locationManager.monitoredRegions.contains(where: {$0.identifier == Constant.kebneOfficeRegionIdentifier})
    }
    
    private(set) var isInRegion: Bool = false {
        didSet {
            for observer in observers {
                observer.regionStateDidChange(toEntered: isInRegion)
            }
        }
    }
    
    func registerRegion(observer: OfficeRegionObserver) {
        observers.append(observer)
    }

}


extension LocationMonitorService : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        isInRegion = true
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        isInRegion = false
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if let callback = startMonitoringCallback {
            callback(true)
        }
        startMonitoringCallback = nil
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        if let callback = startMonitoringCallback {
            callback(false)
        }
        startMonitoringCallback = nil
    }
    
    
  
}
