//
//  SignInViewController.swift
//  Kebne
//
//  Created by Emil Lundgren on 2018-09-24.
//  Copyright © 2018 Emil Lundgren. All rights reserved.
//

import UIKit

protocol SignInViewControllerDelegate : class {
    func didSignInUser()
    func errorSigningInUser()
}

class SignInViewController: UIViewController {
    
    weak var delegate: SignInViewControllerDelegate?
    var userController: UserController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    
    @IBAction func didTapSignInButton() {
        //TODO - call google API...	
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
