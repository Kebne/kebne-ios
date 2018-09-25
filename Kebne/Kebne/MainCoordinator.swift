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

protocol ViewControllerFactory {

    var mainViewController: MainViewController {get}
    var signinViewController: SignInViewController {get}
}

class ViewControllerFactoryClass : ViewControllerFactory {
    var storyboard: UIStoryboard
    
    init(storyboard: UIStoryboard) {
        self.storyboard = storyboard
    }
    
    var mainViewController: MainViewController {
        return storyboard.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
    }
    
    var signinViewController: SignInViewController {
        return storyboard.instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
    }
    
    
}

extension UIStoryboard {
    
    static var main : UIStoryboard {
        return UIStoryboard(name: "Main", bundle: nil)
    }

}

protocol Coordinator {
    var rootViewController: UINavigationController {get}
    func start()
}

class MainCoordinator : NSObject, Coordinator {
    
    var rootViewController: UINavigationController
    var userController: UserController
    var viewControllerFactory: ViewControllerFactory
    
    
    init(rootViewController: UINavigationController, userController: UserController, viewControllerFactory: ViewControllerFactory) {
        self.rootViewController = rootViewController
        self.userController = userController
        self.viewControllerFactory = viewControllerFactory
    }
    
    func start() {
        let mainViewController = viewControllerFactory.mainViewController
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

        let signInViewController = viewControllerFactory.signinViewController
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



