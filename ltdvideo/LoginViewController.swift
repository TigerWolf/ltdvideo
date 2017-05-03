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
    private var wasRestored = false
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let label = UILabel(frame: CGRect(x:20, y:100, width:300, height:40))
		//        label.text = "Loading..."
		self.view.addSubview(label)
		
		let gSignin = GIDSignInButton(frame: CGRect(x:20, y:100, width:self.view.frame.width-40, height:40))
		self.view.addSubview(gSignin)
    }
	
    override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let user = user {
                print("User is signed in.")
				if !self.wasRestored {
					self.openUpload()
				}
            } else {
                print("User is signed out.")
                GIDSignIn.sharedInstance().uiDelegate = self
//                GIDSignIn.sharedInstance().signIn() // This is handled by button
            }
        }
        
        if FIRAuth.auth()?.currentUser != nil {
            
        }else{

        }
        

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func openUpload(){
        NSLog("opening upload controller")
		performSegue(withIdentifier:"segUpload", sender:self)
    }
    
    func showMessagePrompt(_ message: String) {
        // Display alert
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func firebaseLogin(_ credential: FIRAuthCredential) {
        NSLog("login is happening - upload view controller will try opening")
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
                    self.openUpload()
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
                    self.openUpload()
                    // [END signin_credential]
                    // Merge prevUser and currentUser accounts and data
                    // ...
                
            }
        }
        
    }
    
    func showSpinner(){
        KRProgressHUD.show()
    }

    
    override func encodeRestorableState(with coder: NSCoder) {
        
        // TODO: maybe encode the child view controller or tokens here
        NSLog("encoding loginview")
        super.encodeRestorableState(with: coder)

    }
    
    override func decodeRestorableState(with coder: NSCoder) {
		self.wasRestored = true
        NSLog("decoding loginview:")
        super.decodeRestorableState(with: coder)
    }
    
    override func applicationFinishedRestoringState() {
        NSLog("Finished restoring LoginViewController")
    }

}

//extension LoginViewController: UIViewControllerRestoration {
//    
//    static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
//        
//        let vc = LoginViewController()
////        if let navControllerCoded = coder.decodeObject(forKey: "navController") as? UINavigationController {
////            vc.navController = navControllerCoded
////        }
////        if let uploadControllerCoded = coder.decodeObject(forKey: "uploadController") as? UploadViewController {
////            vc.uploadController = uploadControllerCoded
////        }
//        NSLog("inside login vc \(vc.uploadController)")
//        return vc
//    }
//}
