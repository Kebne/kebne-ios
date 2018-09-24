//
//  ViewController.swift
//  Kebne
//
//  Created by Emil Lundgren on 2018-09-21.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import UIKit

protocol MainViewControllerDelegate : class {
    func signInUser()
}

class MainViewController: UIViewController {
    
    var userController: UserController!
    weak var delegate: MainViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if userController.user == nil {
            delegate?.signInUser()
        }
    }


}

