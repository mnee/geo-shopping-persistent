//
//  RecipeSplitViewController.swift
//  GeoShop
//
//  Created by Mischa Nee on 12/3/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import UIKit

class RecipeSplitViewController: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}
