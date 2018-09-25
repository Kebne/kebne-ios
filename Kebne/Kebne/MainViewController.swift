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
}

class MainViewController: UIViewController {
    
    var userController: UserController!
    weak var delegate: MainViewControllerDelegate?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var informationLabel: UILabel!
    @IBOutlet weak var regionMonitorSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.signInSilently()
       
    }

    //MARK: Action
    @IBAction func didTapSignOut(_ sender: Any) {
        userController.signOut()
        delegate?.didTapSignOut()
    }
    
    @IBAction func monitorSwitchDidSwitch(_ sender: UISwitch) {
        if sender.isOn {
            
        } else {
            
        }
    }
    
    
    //MARK: Update UI
    func updateView() {

        if let user = userController.user {
            regionMonitorSwitch.isEnabled =  userController.locationMonitorService.canMonitorForRegions()
            makeUI(hidden: false)
            titleLabel.text = "Hej, \(user.name)!"
        } else {
            makeUI(hidden: true)
        }
    }
    
    func makeUI(hidden: Bool) {
        titleLabel.isHidden = hidden
        signOutButton.isHidden = hidden
        informationLabel.isHidden = hidden
        regionMonitorSwitch.isHidden = hidden
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
