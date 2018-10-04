//
//  SignInViewController.swift
//  Kebne
//
//  Created by Emil Lundgren on 2018-09-24.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import UIKit
import GoogleSignIn

protocol SignInViewControllerDelegate : class {
    func didFinishSignin()
}


class SignInViewController: UIViewController, GIDSignInUIDelegate {

    weak var delegate: SignInViewControllerDelegate?
    @IBOutlet weak var signInButton: GIDSignInButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance()?.uiDelegate = self
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GIDSignIn.sharedInstance()?.delegate = self
    }
    
}

extension SignInViewController : GIDSignInDelegate {
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error == nil {
            animateHide(views: [signInButton], isHidden: true, completion: {[weak self] in
                self?.delegate?.didFinishSignin()
                
            })
        }
    }
}

