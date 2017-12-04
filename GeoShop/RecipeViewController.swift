//
//  RecipeViewController.swift
//  GeoShop
//
//  Created by Mischa Nee on 12/4/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import UIKit

class RecipeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var recipeName: UILabel!
    @IBOutlet weak var recipeImage: UIImageView!
    @IBOutlet weak var ingredientsTable: UITableView! {
        didSet {
            ingredientsTable.dataSource = self
            ingredientsTable.delegate = self
        }
    }
    @IBOutlet weak var instructions: UITextView!
    @IBOutlet weak var prepTime: UILabel!
    
    var ingredients: [String]?
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ingredients?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ingredientsTable.dequeueReusableCell(withIdentifier: "IngredientTableCell", for: indexPath)
        if let ingredientCell = cell as? IngredientsTableViewCell {
            ingredientCell.ingredientName.text = "• \(ingredients![indexPath.item])"
        }
        return cell
    }
}
