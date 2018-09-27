//
//  ViewController.swift
//  Kebne
//
//  Created by Emil Lundgren on 2018-09-21.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import UIKit
import GoogleSignIn

protocol MainViewControllerDelegate : class {
    func didTapSignOut()
    func signInUser()
    func regionMonitoringNotAvailable()
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
        userController.locationMonitorService.stopmonitorForKebneOfficeRegion()
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
            userController.locationMonitorService.startmonitorForKebneOfficeRegion(callback: {[weak self](startedMonitoring) in
                guard let self = self else {return}
                if !startedMonitoring {
                    self.regionMonitorSwitch.setOn(false, animated: true)
                    self.delegate?.regionMonitoringNotAvailable()
                }
            })
        } else {
            userController.locationMonitorService.stopmonitorForKebneOfficeRegion()
            updateLocationLabel()
        }
    }
    
    
    //MARK: Update UI
    func updateView() {

        if let user = userController.user {
            hide(views: hideableViews, isHidden: false)
            updateLocationLabel()
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
        if error == nil {
            updateView()
        } else {
            delegate?.signInUser()
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


