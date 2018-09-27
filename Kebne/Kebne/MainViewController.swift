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

    @IBAction func didTapSignOut(_ sender: Any) {
        userController.signOut()
        delegate?.didTapSignOut()
    }
    
    func updateView() {
        if let user = userController.user {
            titleLabel.text = "Hej, \(user.name)"
        }
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
