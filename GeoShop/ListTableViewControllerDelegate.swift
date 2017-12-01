//
//  ListTableViewControllerDelegate.swift
//  GeoShop
//
//  Created by Mischa Nee on 11/30/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import Foundation

protocol ListTableViewControllerDelegate: class {
    func itemAddedToBeSaved(withTitle itemName: String, in storeIndex: Int)
}
