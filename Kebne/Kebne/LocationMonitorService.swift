//
//  LocationMonitorService.swift
//  Kebne
//
//  Created by Emil Lundgren on 2018-09-25.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationManager : class {
    static func authorizationStatus() -> CLAuthorizationStatus
    static func isMonitoringAvailable(for regionClass: AnyClass) -> Bool
    func startMonitoring(for region: CLRegion)
    func stopMonitoring(for region: CLRegion)
    func requestAlwaysAuthorization()
    var monitoredRegions: Set<CLRegion> { get }
    var delegate: CLLocationManagerDelegate? {get set}
}


extension CLLocationManager : LocationManager {}

protocol OfficeRegionObserver : class {
    func regionStateDidChange(toEntered: Bool)
}



extension CLRegion {
    
    static var kebneOfficeRegion : CLCircularRegion {
        return CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), radius: 50, identifier:LocationMonitorService.Constant.kebneOfficeRegionIdentifier)
    }
}

class LocationMonitorService : NSObject {
    
    typealias StartRegionMonitorCallback = (Bool)->()
    fileprivate enum Constant {
        static let kebneOfficeRegionIdentifier = "com.kebneapp.kebneOfficeRegionIdentifier"
    }
    
    private var observers = [OfficeRegionObserver]()
    private var locationManager: LocationManager
    fileprivate var startMonitoringCallback: StartRegionMonitorCallback?
    
    required init(locationManager: LocationManager) {
        self.locationManager = locationManager
        super.init()
        self.locationManager.delegate = self
    }
    
    func canMonitorForRegions() -> Bool {
        return CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.classForCoder())
    }
    
    func startmonitorForKebneOfficeRegion(callback: @escaping (Bool) -> (), alocationManager: LocationManager.Type = CLLocationManager.self) {
        startMonitoringCallback = callback
        switch alocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            return
        case .denied, .restricted:
            callback(false)
            return
        default:
            break
        }
        
        
        startMonitoring()
    }
    
 
    
    private func startMonitoring() {
        
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
        print("Did start monitoring for regions.")
        if let callback = startMonitoringCallback {
            callback(true)
        }
        startMonitoringCallback = nil
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Error: \(error) monitoring for regions.")
        if let callback = startMonitoringCallback {
            callback(false)
        }
        startMonitoringCallback = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            startMonitoring()
        } else if let callback = startMonitoringCallback {
            callback(false)
            startMonitoringCallback = nil
        }
        
        
    }
}
