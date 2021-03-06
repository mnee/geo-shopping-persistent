//
//  AddListTableCell.swift
//  GeoShopping
//
//  Created by Mischa Nee on 11/28/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import UIKit

class AddListTableCell: UITableViewCell {

    weak var delegate: AddListTableCellDelegate?
    
    @IBOutlet weak var textField: UITextField! {
        didSet {
            textField.placeholder = "Add an item..."
            textField.text = ""
        }
    }
    
    @IBAction func addItemFromButton(_ sender: UIButton) {
        if let text = textField.text, text != "" {
            delegate?.didSelectToBeAdded(with: text)
            textField.placeholder = "Add an item..."
            textField.text = ""
        }
    }

}
