//
//  RecipeTableViewCell.swift
//  GeoShop
//
//  Created by Mischa Nee on 12/3/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import UIKit

class RecipeTableViewCell: UITableViewCell {

    @IBOutlet weak var recipeImage: UIImageView!
    @IBOutlet weak var recipeName: UILabel!
    @IBOutlet weak var recipeItemsNeeded: UILabel!
    @IBOutlet weak var recipePrepTime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
