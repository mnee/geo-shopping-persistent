//
//  RecipeTableViewController.swift
//  GeoShop
//
//  Created by Mischa Nee on 12/3/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import UIKit
import CoreData

class RecipeTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, RecipePopoverViewControllerDelegate {
    
    
    var recipes: [NSManagedObject]?
    var recipeID: NSManagedObject?
    
    @IBOutlet weak var recipeTable: UITableView! {
        didSet {
            recipeTable.dataSource = self
            recipeTable.delegate = self
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recipes?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = recipeTable.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath)
        if let recipeCell = cell as? RecipeTableViewCell {
            let recipe = recipes![indexPath.item]
            recipeCell.recipeName.text = recipe.value(forKey: "recipeName") as? String
            if let numItems = (recipe.value(forKey: "ingredients") as? [String])?.count {
                recipeCell.recipeItemsNeeded.text = "\(numItems) items needed"
            }
            recipeCell.recipePrepTime.text = recipe.value(forKey: "prepTime") as? String
            
            let imageURL = recipe.value(forKey: "imageURL")
            if (imageURL as? String) == "Default" {
                recipeCell.recipeImage.image = UIImage(named: "RecipeDefault")?.resizeImage(targetSize: CGSize(width: recipeCell.recipeImage.bounds.width, height: recipeCell.recipeImage.bounds.height))
            } else {
                do {
                    let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
                    let fileURL = documentDirectory.appendingPathComponent(imageURL as! String)
                    let imageData = try Data(contentsOf: fileURL)
                    recipeCell.recipeImage.image = UIImage(data: imageData)?.resizeImage(targetSize: CGSize(width: recipeCell.recipeImage.bounds.width, height: recipeCell.recipeImage.bounds.height))
                } catch {
                    print("Failed to save recipe image. Error: \(error)")
                }
            }
        
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectRecipe(_:)))
            recipeCell.addGestureRecognizer(tap)
        }
        return cell
    }
    
    @objc func selectRecipe(_ sender: UITapGestureRecognizer) {
        // TODO: Segue to a recipe viewer VC
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchRecipeCoreData()
    }
    
    func fetchRecipeCoreData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestRecipes = NSFetchRequest<NSManagedObject>(entityName: "Recipe")
        let fetchRequestRecipeID = NSFetchRequest<NSManagedObject>(entityName: "RecipeID")
        do {
            recipes = try managedContext.fetch(fetchRequestRecipes)
            let recipeIDEntity = try managedContext.fetch(fetchRequestRecipeID)
            if recipeIDEntity.count > 0 {
                recipeID = recipeIDEntity[0]
            } else {
                let entity = NSEntityDescription.entity(forEntityName: "RecipeID", in: managedContext)!
                let startRecipeID = NSManagedObject(entity: entity, insertInto: managedContext)
                startRecipeID.setValue(0, forKey: "currentID")
                self.recipeID = startRecipeID
                
                try managedContext.save()
            }
        } catch let error as NSError {
            print("Failed to load recipes from Core Data. Error: \(error)")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RecipePopover" {
            if let recipePopVC = segue.destination as? RecipePopoverViewController {
                if recipeID != nil {
                    if let currentRecipeID = recipeID?.value(forKey: "currentID") as? Int {
                        recipePopVC.recipeID = currentRecipeID
                        recipeID?.setValue(currentRecipeID+1, forKey: "currentID")
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        let managedContext = appDelegate.persistentContainer.viewContext
                        do {
                            try managedContext.save()
                        } catch let error {
                            print("Failed to update recipeID. Error: \(error)")
                        }
                    }
                } else {
                    recipePopVC.recipeID = 0
                }
                recipePopVC.delegate = self
            }
        }
    
    }
    
    func didUpdateRecipes() {
        fetchRecipeCoreData()
        recipeTable.reloadData()
    }
    

}
