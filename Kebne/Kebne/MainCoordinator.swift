//
//  MainCoordinator.swift
//  Kebne
//
//  Created by Emil Lundgren on 2018-09-24.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import Foundation
import UIKit
import GoogleSignIn



extension UIStoryboard {
    
    static var main : UIStoryboard {
        return UIStoryboard(name: "Main", bundle: nil)
    }
    
    static var mainViewController : MainViewController {
        return UIStoryboard.main.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
    }
    
    static var signInViewController : SignInViewController {
        return UIStoryboard.main.instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
    }
}

protocol Coordinator {
    var rootViewController: UINavigationController {get}
    func start()
}

class MainCoordinator : NSObject, Coordinator {
    
    var rootViewController: UINavigationController
    var userController: UserController!
    
    
    init(rootViewController: UINavigationController, userController: UserController) {
        self.rootViewController = rootViewController
        self.userController = userController
    }
    
    func start() {
        let mainViewController = UIStoryboard.mainViewController
        mainViewController.delegate = self
        mainViewController.userController = userController
        
        rootViewController.pushViewController(mainViewController, animated: false)
    }
 
}

extension MainCoordinator : MainViewControllerDelegate {
    func didTapSignOut() {
        showSignIn(animated: true)
    }
    
    func signInUser() {
        showSignIn(animated: false)
    }
    
    func showSignIn(animated: Bool) {

        let signInViewController = UIStoryboard.signInViewController
        signInViewController.delegate = self
        if let topViewController = rootViewController.viewControllers.last {
            topViewController.present(signInViewController, animated: animated, completion: nil)
        }
        
    }

}

extension MainCoordinator : SignInViewControllerDelegate {
    func didFinishSignin() {
        if let topVc = rootViewController.topViewController {
            topVc.dismiss(animated: true, completion: nil)
        }
    }
}



