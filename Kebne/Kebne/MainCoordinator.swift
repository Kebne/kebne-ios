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

enum KebneAppStrings {
    static let regionsNotAvAlertTitle = NSLocalizedString("alert.title.regionMonitoringUnavailable", comment: "")
    static let regionsNotAvAlertMsg = NSLocalizedString("alert.message.regionMonitoringUnavailable", comment: "")
    static let notificationsDeclinedAlertTitle = NSLocalizedString("alert.title.userDeclinedNotifications", comment: "")
    static let notificationsDeclinedAlertMsg = NSLocalizedString("alert.message.userDeclinedNotifications", comment: "")
    static let boundaryCrossingNotificationPlaceholder = NSLocalizedString("alert.placeholder.boundarycrossingnotification", comment: "")
    static let boundaryCrossingNotificationOkTitle = NSLocalizedString("alert.okbuttontitle.boundarycrossingnotification", comment: "")
    static let boundaryCrossingNotificationCancelTitle = NSLocalizedString("alert.cancelbuttontitle.boundarycrossingnotification", comment: "")
}

protocol ViewControllerFactory {

    var mainViewController: MainViewController {get}
    var signinViewController: SignInViewController {get}
    func createSimpleAlert(withTitle title: String, message: String) -> UIAlertController
    func createTextFieldAlert(withTitle title: String, message: String,okTitle: String, cancelTitle: String, placeholder: String, completionHandler: @escaping (String?)->()) ->UIAlertController
}

class ViewControllerFactoryClass : ViewControllerFactory {
    func createSimpleAlert(withTitle title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        return alertController
    }
    
    func createTextFieldAlert(withTitle title: String, message: String,okTitle: String, cancelTitle: String, placeholder: String, completionHandler: @escaping (String?)->()) ->UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = placeholder
        }
        let okAction = UIAlertAction(title: okTitle, style: .cancel, handler: {(action) in
            completionHandler(alertController.textFields?.first?.text)
        })
        let cancelAction = UIAlertAction(title: cancelTitle, style: .default, handler: {(action) in
            completionHandler(nil)
        })
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
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

    var rootViewController: UINavigationController
    var userController: StateController
    var viewControllerFactory: ViewControllerFactory
    
    init(rootViewController: UINavigationController, userController: StateController, viewControllerFactory: ViewControllerFactory) {
        self.rootViewController = rootViewController
        self.userController = userController
        self.viewControllerFactory = viewControllerFactory
        
    }
    
    func start() {
        let mainViewController = viewControllerFactory.mainViewController
        mainViewController.delegate = self
        mainViewController.userController = userController
        userController.delegate = self
        rootViewController.pushViewController(mainViewController, animated: false)
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

extension MainCoordinator : MainViewControllerDelegate {
    func userDeclinedNotifications() {
        showAlertWith(title: KebneAppStrings.notificationsDeclinedAlertTitle, message: KebneAppStrings.notificationsDeclinedAlertMsg)
    }
    
    func regionMonitoringNotAvailable() {
        showAlertWith(title: KebneAppStrings.regionsNotAvAlertTitle, message: KebneAppStrings.regionsNotAvAlertMsg)
    }
    
    func didTapSignOut() {
        showSignIn(animated: false)
    }
    
    func signInUser() {
        showSignIn(animated: false)
    }

}

extension MainCoordinator : UserControllerDelegate {
    func handleBoundaryCrossNotificationWith(title: String, body: String, responseHandler: @escaping (String?) -> ()) {
        if let topViewController = rootViewController.topViewController {
            let alert = viewControllerFactory.createTextFieldAlert(withTitle: title, message: body,okTitle: KebneAppStrings.boundaryCrossingNotificationOkTitle, cancelTitle: KebneAppStrings.boundaryCrossingNotificationCancelTitle,
                                                                   placeholder: KebneAppStrings.boundaryCrossingNotificationPlaceholder, completionHandler: responseHandler)
            topViewController.present(alert, animated: true, completion: nil)
        }
    }
    
    func didReceiveNotificationWith(title: String, body: String) {
        showAlertWith(title: title, message: body)
    }
}

extension MainCoordinator : SignInViewControllerDelegate {
    func didFinishSignin() {
        if let topVc = rootViewController.topViewController {
            topVc.dismiss(animated: false, completion: nil)
        }
    }
}



