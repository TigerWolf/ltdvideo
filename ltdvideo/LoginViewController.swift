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
import KRProgressHUD

class LoginViewController: UIViewController, GIDSignInUIDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
    
        let label = UILabel(frame: CGRect(x:20, y:100, width:300, height:40))
        label.text = "Loading..."
        self.view.addSubview(label)
        
        if FIRAuth.auth()?.currentUser != nil {
            self.openUpload()
        }else{
            GIDSignIn.sharedInstance().uiDelegate = self
            GIDSignIn.sharedInstance().signIn()
        }
        

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func openUpload(){


        let uploadController =  UploadViewController()
        let nav1 = UINavigationController()
        nav1.viewControllers = [uploadController]
//        self.navigationController?.pushViewController(uploadController, animated: true)
//        self.present(uploadController, animated: true)
        self.present(nav1, animated: true, completion: nil)
    }
    
    func showMessagePrompt(_ message: String) {
        // Display alert
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func firebaseLogin(_ credential: FIRAuthCredential) {
        showSpinner()
        if let user = FIRAuth.auth()?.currentUser {
            // [START link_credential]
            user.link(with: credential) { (user, error) in
                // [START_EXCLUDE]
                KRProgressHUD.dismiss()
                    if let error = error {
                        self.showMessagePrompt(error.localizedDescription)
                        
                        return
                    }
//                    self.tableView.reloadData()
                
                // [END_EXCLUDE]
            }
            // [END link_credential]
        } else {
            // [START signin_credential]
            FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                // [START_EXCLUDE]
                KRProgressHUD.dismiss()
                    // [END_EXCLUDE]
                    if let error = error {
                        // [START_EXCLUDE]
                        self.showMessagePrompt(error.localizedDescription)
                        
                        // [END_EXCLUDE]
                        return
                    }
                    // [END signin_credential]
                    // Merge prevUser and currentUser accounts and data
                    // ...
                
            }
        }
        
    }
    
    func showSpinner(){
        KRProgressHUD.show()
    }

    
    
}
