//
//  ListTableViewControllerDelegate.swift
//  GeoShop
//
//  Created by Mischa Nee on 11/30/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import Foundation
import MessageUI

protocol ListTableViewControllerDelegate: class {
    func itemAddedToBeSaved(withTitle itemName: String, in storeIndex: Int)
    func storeDeleted(_ storeIndex: Int)
    func itemDeletedToBeSaved(at itemIndex: Int, in storeIndex: Int)
}
