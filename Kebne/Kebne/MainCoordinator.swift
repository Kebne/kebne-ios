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
    func createSimpleAlert(withTitle title: String, message: String) ->UIAlertController
}

class ViewControllerFactoryClass : ViewControllerFactory {
    func createSimpleAlert(withTitle title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        return alertController
    }
    
    
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
    
    enum Strings {
        static let regionsNotAvAlertTitle = NSLocalizedString("alert.title.regionMonitoringUnavailable", comment: "")
        static let regionsNotAvAlertMsg = NSLocalizedString("alert.message.regionMonitoringUnavailable", comment: "")
        static let notificationsDeclinedAlertTitle = NSLocalizedString("alert.title.userDeclinedNotifications", comment: "")
        static let notificationsDeclinedAlertMsg = NSLocalizedString("alert.message.userDeclinedNotifications", comment: "")
    }
    
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
    func userDeclinedNotifications() {
        showAlertWith(title: Strings.notificationsDeclinedAlertTitle, message: Strings.notificationsDeclinedAlertMsg)
    }
    
    func regionMonitoringNotAvailable() {
        showAlertWith(title: Strings.regionsNotAvAlertTitle, message: Strings.regionsNotAvAlertMsg)
    }
    
    func didTapSignOut() {
        showSignIn(animated: false)
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
    
    func showAlertWith(title: String, message: String) {
        if let topViewController = rootViewController.topViewController {
            let alert = viewControllerFactory.createSimpleAlert(withTitle: title, message: message)
            topViewController.present(alert, animated: true, completion: nil)
        }
    }
  
}

extension MainCoordinator : SignInViewControllerDelegate {
    func didFinishSignin() {
        if let topVc = rootViewController.topViewController {
            topVc.dismiss(animated: false, completion: nil)
        }
    }
}



