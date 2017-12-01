//
//  AddListTableCellDelegate.swift
//  GeoShopping
//
//  Created by Mischa Nee on 11/28/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import Foundation

protocol AddListTableCellDelegate: class {
    func didSelectToBeAdded(with textToAdd: String)
}
