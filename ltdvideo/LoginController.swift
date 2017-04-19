//
//  LoginController.swift
//  ltdvideo
//
//  Created by Kieran Andrews on 19/4/17.
//  Copyright © 2017 Kieran Andrews. All rights reserved.
//

import Foundation
import Firebase
import GoogleSignIn
import UIKit
import PKHUD

class LoginController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showMessagePrompt(message: String) {
        // Display alert
    }
    
    func firebaseLogin(_ credential: FIRAuthCredential) {
        showSpinner()
        if let user = FIRAuth.auth()?.currentUser {
            // [START link_credential]
            user.link(with: credential) { (user, error) in
                // [START_EXCLUDE]
                self.hideSpinner({
                    if let error = error {
                        self.showMessagePrompt(error.localizedDescription)
                        PKHUD.sharedHUD.hide()
                        return
                    }
                    self.tableView.reloadData()
                })
                // [END_EXCLUDE]
            }
            // [END link_credential]
        } else {
            // [START signin_credential]
            FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                // [START_EXCLUDE]
                self.hideSpinner({
                    // [END_EXCLUDE]
                    if let error = error {
                        // [START_EXCLUDE]
                        self.showMessagePrompt(error.localizedDescription)
                        PKHUD.sharedHUD.hide()
                        // [END_EXCLUDE]
                        return
                    }
                    // [END signin_credential]
                    // Merge prevUser and currentUser accounts and data
                    // ...
                })
            }
        }
        
    }
    
    func showSpinner(){
        HUD.show(.progress)
    }

    
    
}
