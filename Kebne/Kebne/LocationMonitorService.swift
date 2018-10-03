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
    func requestLocation()
}


extension CLLocationManager : LocationManager {}

protocol OfficeRegionObserver : AnyObject {
    func regionStateDidChange(toEntered: Bool)
}

class ObserverWrapper {
    weak var value: OfficeRegionObserver?
    init(_ value: OfficeRegionObserver) {
        self.value = value
    }
}

extension CLLocationCoordinate2D {
    static var oxtorgsgatan8Coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: 59.335286, longitude: 18.066011)
    }
}

extension CLRegion {
    static var kebneOfficeRegion : CLCircularRegion {
        return CLCircularRegion(center: CLLocationCoordinate2D.oxtorgsgatan8Coordinate, radius: 100, identifier:LocationMonitorService.Constant.kebneOfficeRegionIdentifier)
    }
}

class LocationMonitorService : NSObject {
    
    typealias StartRegionMonitorCallback = (Bool)->()
    fileprivate enum Constant {
        static let kebneOfficeRegionIdentifier = "com.kebneapp.kebneOfficeRegionIdentifier"
    }
    
 
    private var observers = [ObserverWrapper]()
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
    
    
    /// Starts core location region monitoring for a geo region in which Kebne office is contained.
    /// Will request authorisation of location services if needed.
    ///
    /// - Parameters:
    ///   - callback: If authorisation of location services fails or an error occurs, this will be invoked with a value of false.
    ///               If authorisation is ok, core location will callback that monitoring started and callback will be invoked with true.
    ///   - alocationManager: For testing purpouses the ability to use a mocked type.
    func startMonitorForKebneOfficeRegion(callback: @escaping (Bool) -> (), alocationManager: LocationManager.Type = CLLocationManager.self) {
        startMonitoringCallback = callback
        switch alocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            return
        case .denied, .restricted, .authorizedWhenInUse:
            callback(false)
            return
        default:
            startMonitoring()
        }
    }
    
 
    
    private func startMonitoring() {
        locationManager.startMonitoring(for: CLRegion.kebneOfficeRegion)
    }
    
    func stopMonitorForKebneOfficeRegion() {
        locationManager.stopMonitoring(for: CLRegion.kebneOfficeRegion)
    }
    
    var isMonitoringForKebneOfficeRegion: Bool {
        return locationManager.monitoredRegions.contains(where: {$0.identifier == Constant.kebneOfficeRegionIdentifier})
    }
    
    private(set) var isInRegion: Bool = false {
        didSet {
            notifyObservers()
        }
    }
    
    private func notifyObservers() {
        print("Notify observers region boundary change to: \(isInRegion)")
        observers.filter({$0.value != nil}).forEach({$0.value!.regionStateDidChange(toEntered: isInRegion)})
    }
    
    func registerRegion(observer: OfficeRegionObserver) {
        guard observers.firstIndex(where: {$0.value === observer}) == nil else {return}
        observers.append(ObserverWrapper(observer))
    }
    
    func removeRegion(observer: OfficeRegionObserver) {
        if let index = observers.firstIndex(where: {$0.value === observer}) {
            observers.remove(at: index)
        }
    }
    
    private func checkIsInRegion() {
        locationManager.requestLocation()
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
        checkIsInRegion()
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
        if status == .authorizedAlways, startMonitoringCallback != nil {
            startMonitoring()
        } else if let callback = startMonitoringCallback {
            callback(false)
            startMonitoringCallback = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isInRegion = locations.contains(where: {CLRegion.kebneOfficeRegion.contains($0.coordinate)})
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
}
