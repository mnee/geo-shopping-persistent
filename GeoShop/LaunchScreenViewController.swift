//
//  LaunchScreenViewController.swift
//  GeoShop
//
//  Created by Mischa Nee on 12/5/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import UIKit
import LocalAuthentication

class LaunchScreenViewController: UIViewController {
    

    @IBOutlet weak var backgroundImage: UIImageView!
    
    // Segue set from continue button to StoreCollectionVC in storyboard
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var logo: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundImage.alpha = 0.5
        continueButton.alpha = 0.5
        logo.alpha = 0.5
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animate(withDuration: 2.0, animations: {
            self.backgroundImage.alpha = 1.0
            self.continueButton.alpha = 1.0
            self.logo.alpha = 1.0
            self.logo.center.y += 400.0
            self.continueButton.center.y -= 400.0
        }, completion: { finished in
            if finished {
                let myContext = LAContext()
                let myLocalizedReasonString = "To log you into your account"
                
                var authError: NSError?
                if #available(iOS 8.0, macOS 10.12.1, *) {
                    if myContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                        myContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: myLocalizedReasonString) { success, evaluateError in
                            if success {
                                self.performSegue(withIdentifier: "unlockApp", sender: nil)
                            }
                        }
                    }
                }
            }
        })
        
    }
}
