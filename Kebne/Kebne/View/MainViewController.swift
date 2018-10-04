//
//  ViewController.swift
//  Kebne
//
//  Created by Emil Lundgren on 2018-09-21.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import UIKit
import GoogleSignIn
import Firebase

protocol MainViewControllerDelegate : class {
    func didTapSignOut()
    func signInUser()
    func regionMonitoringNotAvailable()
    func userDeclinedNotifications()
}

class MainViewController: UIViewController {
    
    enum Strings {
        static let inOfficeMsg = NSLocalizedString("mainView.locationLabel.inOfficeMsg", comment: "")
        static let notInOfficeMsg = NSLocalizedString("mainView.locationLabel.notInOfficeMsg", comment: "")
        static let greetingMsg = NSLocalizedString("mainView.titleLabel.greeting", comment: "")
    }
    
    var userController: UserController!
    weak var delegate: MainViewControllerDelegate?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var informationLabel: UILabel!
    @IBOutlet weak var regionMonitorSwitch: UISwitch!
    @IBOutlet weak var locationLabel: UILabel!
    
    var hideableViews = [UIView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideableViews = [titleLabel, signOutButton, informationLabel, regionMonitorSwitch, locationLabel]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateView()
        userController.locationMonitorService.registerRegion(observer: self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        userController.locationMonitorService.removeRegion(observer: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.signInSilently()
   
    }

    //MARK: Action
    @IBAction func didTapSignOut(_ sender: Any) {
        userController.signOut()
        userController.locationMonitorService.stopMonitorForKebneOfficeRegion()
        regionMonitorSwitch.isOn = false
        regionMonitorSwitch.isEnabled = false
        signOutButton.isEnabled = false
        animateHide(views: hideableViews, isHidden: true, completion: {[weak self]() in
            guard let self = self else {return}
            self.signOutButton.isEnabled = true
            self.delegate?.didTapSignOut()
        })
    }
    
    @IBAction func monitorSwitchDidSwitch(_ sender: UISwitch) {
        if sender.isOn {
            userController.locationMonitorService.startMonitorForKebneOfficeRegion(callback: {[weak self](startedMonitoring) in
                guard let self = self else {return}
                if startedMonitoring {
                    self.requestAuthForNotifications()
                } else {
                    self.regionMonitorSwitch.setOn(false, animated: true)
                    self.delegate?.regionMonitoringNotAvailable()
                }
            })
        } else {
            userController.locationMonitorService.stopMonitorForKebneOfficeRegion()
            updateLocationLabel()
        }
    }
    
    private func requestAuthForNotifications() {
        guard let user = userController.user else {return}
        userController.notificationService.requestAuthForNotifications(completion: {[weak self](granted) in
            if !granted {
                self?.delegate?.userDeclinedNotifications()
            }
        }, user: user)
    }
    
    
    @IBAction func didPressSendNotification() {
        if let user = userController.user {
            userController.notificationService.regionBoundaryCrossedBy(user: user, didEnter: true)
        }
    }
    
    
    //MARK: Update UI
    func updateView() {

        if let user = userController.user {
            hide(views: hideableViews, isHidden: false)
            locationLabel.text = ""
            regionMonitorSwitch.isEnabled = userController.locationMonitorService.canMonitorForRegions()
            regionMonitorSwitch.isOn = userController.locationMonitorService.isMonitoringForKebneOfficeRegion
            titleLabel.text = "\(Strings.greetingMsg), \(user.name)!"
        } else {
            hide(views: hideableViews, isHidden: true)
        }
    }
    
    func updateLocationLabel() {
        var text = ""
        if userController.locationMonitorService.isMonitoringForKebneOfficeRegion && userController.locationMonitorService.isInRegion {
            text = Strings.inOfficeMsg
        } else if userController.locationMonitorService.isMonitoringForKebneOfficeRegion && !userController.locationMonitorService.isInRegion {
            text = Strings.notInOfficeMsg
        }
        locationLabel.text = text
    }
    
}


extension MainViewController : GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard user != nil else {
            delegate?.didTapSignOut()
            return
        }
        if error == nil {
            let credential = GoogleAuthProvider.credential(withIDToken: user.authentication.idToken,
                                                           accessToken: user.authentication.accessToken)
            
            Auth.auth().signInAndRetrieveData(with: credential) {[weak self](authResult, error) in
                guard authResult != nil, error == nil, let user = self?.userController.user else {return}
                self?.userController.notificationService.subscribeToFirebaseMessaging(user: user)
               self?.updateView()
            }
            
        }
    }
}

extension MainViewController : OfficeRegionObserver {
    func regionStateDidChange(toEntered: Bool) {
        updateLocationLabel()
    }
}

extension UIViewController {
    func animateHide(views: [UIView], isHidden: Bool, completion: @escaping()->()) {
        let opacity: Float = isHidden ? 0.0 : 1.0
        UIView.animate(withDuration: 1.0, animations: {() in
            for view in views {
                view.layer.opacity = opacity
            }
        }, completion: {[weak self](finished) in
            guard let self = self else {return}
            self.hide(views: views, isHidden: isHidden)
            for view in views {
                view.layer.opacity = 1.0
            }
            completion()
        })
    }
    
    func hide(views: [UIView], isHidden: Bool) {
        for view in views {
            view.isHidden = isHidden
        }
    }
}


