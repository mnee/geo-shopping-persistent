//
//  RecipeViewController.swift
//  GeoShop
//
//  Created by Mischa Nee on 12/4/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import UIKit
import CoreData

class RecipeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, RecipePopoverViewControllerDelegate {

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
    var recipeID: Int?
    
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditRecipe" {
            if let recipePopVC = segue.destination as? RecipePopoverViewController {
                if recipeID != nil {
                    recipePopVC.recipeID = recipeID
                    recipePopVC.recipeName = recipeNameText
                    recipePopVC.prepTime = prepTimeText
                    var ingredientsText = ""
                    for item in ingredients! {
                        ingredientsText.append("\(item), ")
                    }
                    ingredientsText.removeLast(2)   // Extra ", "
                    recipePopVC.ingredients = ingredientsText
                    recipePopVC.instructions = instructionsText
                    recipePopVC.image = recipeImageBackground
                } else {
                    recipePopVC.recipeID = 0
                }
                recipePopVC.delegate = self
            }
        }
    }
    
    func didUpdateRecipes() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Recipe")
        fetchRequest.predicate = NSPredicate(format: "imageURL == %@", "Recipe\(recipeID!)")
        do {
            let fetchedObjects = try managedContext.fetch(fetchRequest)
            if fetchedObjects.count > 0 {
                let recipe = fetchedObjects[0]
                
                recipeName.text = recipe.value(forKey: "recipeName") as? String
                if let imageURL = recipe.value(forKey: "imageURL") as? String {
                    do {
                        let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
                        let fileURL = documentDirectory.appendingPathComponent(imageURL)
                        let imageData = try Data(contentsOf: fileURL)
                        recipeImage.image = UIImage(data: imageData)?.resizeImage(targetSize: CGSize(width: recipeImage.bounds.width, height: recipeImage.bounds.height))
                    } catch {
                        print("Failed to load recipe image. Error: \(error)")
                    }
                }
            
                ingredients = recipe.value(forKey: "ingredients") as? [String]
                ingredientsTable.reloadData()
                instructions.text = recipe.value(forKey: "prepInstructions") as! String
                prepTime.text = recipe.value(forKey: "prepTime") as? String
            }
        } catch let error {
            print("Failed to fetch. Error: \(error)")
        }
        
    }
}
