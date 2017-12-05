//
//  RecipeTableViewController.swift
//  GeoShop
//
//  Created by Mischa Nee on 12/3/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import UIKit
import CoreData

class RecipeTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, RecipePopoverViewControllerDelegate, UIViewControllerPreviewingDelegate {
    
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
            recipeCell.recipePrepTime.text = "\(recipe.value(forKey: "prepTime") as! Int) minutes"
            
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
                    print("Failed to load recipe image. Error: \(error)")
                }
            }
        
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectRecipe(_:)))
            recipeCell.addGestureRecognizer(tap)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let recipeObject = recipes?.remove(at: indexPath.item) {
                recipeObject.removeFromCore()
                recipeTable.reloadData()
            }
        }
    }
    
    @objc func selectRecipe(_ sender: UITapGestureRecognizer) {
        // TODO: Segue to a recipe viewer VC
        if sender.state == UIGestureRecognizerState.ended, let recipeCell = sender.view as? RecipeTableViewCell {
            if let indexPath = recipeTable.indexPath(for: recipeCell) {
                performSegue(withIdentifier: "showDetail", sender: recipes![indexPath.item])
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recipeTable.estimatedRowHeight = 150.0
        recipeTable.rowHeight = UITableViewAutomaticDimension
        registerForPreviewing(with: self, sourceView: recipeTable)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Recipes"
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
        } else if segue.identifier == "showDetail" {
            if let recipeFocusVC = segue.destination as? RecipeViewController {
                if let recipeData = sender as? NSManagedObject {
                    recipeFocusVC.ingredients = recipeData.value(forKey: "ingredients") as? [String]
                    recipeFocusVC.instructionsText = (recipeData.value(forKey: "prepInstructions") as! String)
                    recipeFocusVC.prepTimeText = "Prep Time: \(recipeData.value(forKey: "prepTime") as! Int) minutes"
                    recipeFocusVC.recipeNameText = recipeData.value(forKey: "recipeName") as? String
                    
                    if let imageURL = recipeData.value(forKey: "imageURL") as? String {
                        recipeFocusVC.recipeID = Int(imageURL.dropFirst(6)) // Ex. pulls 7 off Recipe7
                        
                        do {
                            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
                            let fileURL = documentDirectory.appendingPathComponent(imageURL)
                            let imageData = try Data(contentsOf: fileURL)
                            recipeFocusVC.recipeImageBackground = UIImage(data: imageData)
                        } catch {
                            print("Failed to load recipe image. Error: \(error)")
                        }
                    }
                }
            }
        }
    
    }
    
    func didUpdateRecipes() {
        fetchRecipeCoreData()
        recipeTable.reloadData()
    }

    // 3D Touch
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = recipeTable.indexPathForRow(at: location), let recipeData = recipes?[indexPath.item] {
            let previewVC = storyboard?.instantiateViewController(withIdentifier: "RecipeView")
            if let recipeFocusVC = previewVC as? RecipeViewController {
                recipeFocusVC.ingredients = recipeData.value(forKey: "ingredients") as? [String]
                recipeFocusVC.instructionsText = (recipeData.value(forKey: "prepInstructions") as! String)
                recipeFocusVC.prepTimeText = "Prep Time: \(recipeData.value(forKey: "prepTime") as! Int) minutes"
                recipeFocusVC.recipeNameText = recipeData.value(forKey: "recipeName") as? String
                
                if let imageURL = recipeData.value(forKey: "imageURL") as? String {
                    recipeFocusVC.recipeID = Int(imageURL.dropFirst(6)) // Ex. pulls 7 off Recipe7
                    
                    do {
                        let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
                        let fileURL = documentDirectory.appendingPathComponent(imageURL)
                        let imageData = try Data(contentsOf: fileURL)
                        recipeFocusVC.recipeImageBackground = UIImage(data: imageData)
                    } catch {
                        print("Failed to load recipe image. Error: \(error)")
                    }
                }
                return recipeFocusVC
            }
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: nil)
    }

}

extension NSManagedObject {
    func removeFromCore() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        managedContext.delete(self)
        do {
            try managedContext.save()
        } catch let error {
            print("Failed to delete recipe. Error: \(error)")
        }
    }
}
