//
//  MainCoordinator.swift
//  Kebne
//
//  Created by Emil Lundgren on 2018-09-24.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import Foundation
import UIKit



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

class MainCoordinator : Coordinator {
    
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
    func signInUser() {
        let signInViewController = UIStoryboard.signInViewController
        signInViewController.delegate = self
        if let topViewController = rootViewController.viewControllers.last {
            topViewController.present(signInViewController, animated: false, completion: nil)
        }
    }
}

extension MainCoordinator : SignInViewControllerDelegate {
    func didSignInUser() {
        
    }
    
    func errorSigningInUser() {
        
    }
}
