//
//  RecipeViewController.swift
//  GeoShop
//
//  Created by Mischa Nee on 12/4/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import UIKit

class RecipeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var recipeName: UILabel! { didSet { recipeName.text = recipeNameText } }
    @IBOutlet weak var recipeImage: UIImageView! {
        didSet {
            recipeImage.image = recipeImageBackground?.resizeImage(targetSize: CGSize(width: recipeImage.bounds.width, height: recipeImage.bounds.height))
            
        }
        
    }
    @IBOutlet weak var ingredientsTable: UITableView! {
        didSet {
            ingredientsTable.dataSource = self
            ingredientsTable.delegate = self
            ingredientsTable.separatorStyle = .none
        }
    }
    @IBOutlet weak var instructions: UITextView! { didSet { instructions.text = instructionsText ?? "" } }
    @IBOutlet weak var prepTime: UILabel! { didSet { prepTime.text = prepTimeText } }
    
    var recipeNameText: String?
    var recipeImageBackground: UIImage?
    var ingredients: [String]?
    var instructionsText: String?
    var prepTimeText: String?
    
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
