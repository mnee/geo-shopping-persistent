//
//  RecipeViewController.swift
//  GeoShop
//
//  Created by Mischa Nee on 12/4/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import UIKit
import CoreData
import SafariServices

class RecipeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, RecipePopoverViewControllerDelegate, UIPrintInteractionControllerDelegate, SFSafariViewControllerDelegate {
    
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
    var recipeIndexInList: Int?
    var websiteURL: String?
    
    var delegate: RecipeViewControllerDelegate?
    
    @IBAction func viewWebsite(_ sender: Any) {
        if websiteURL != nil {
            if let url = URL(string: websiteURL!) {
                let safariVC = SFSafariViewController(url: url)
                safariVC.delegate = self
                present(safariVC, animated: true, completion: nil)
            }
        }
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        get {
            let print = UIPreviewAction(title: "Print", style: .default) { (action, vc) in
                self.executeAirPrint()
            }
            let ingreds = UIPreviewActionGroup(title: "Add Ingredients", style: .default, actions: getIngredientActions())
            
            let delete = UIPreviewAction(title: "Delete", style: .destructive) { (action, vc) in
                self.delegate?.deleteRecipe(at: self.recipeIndexInList!)
            }
            return [print, ingreds, delete]
        }
    }
    
    func getIngredientActions() -> [UIPreviewAction] {
        var actions: [UIPreviewAction] = []
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Store")
        do {
            let fetchedObjects = try managedContext.fetch(fetchRequest)
            for storeObject in fetchedObjects {
                if let storeName = storeObject.value(forKey: "storeName") as? String {
                    let ingredientAction = UIPreviewAction(title: "to \(storeName)", style: .default) { (action, vc)  in
                        if let currentItems = storeObject.value(forKey: "storeItemList") as? [String] {
                            if self.ingredients != nil {
                                storeObject.setValue(currentItems + self.ingredients!, forKey: "storeItemList")
                                do {
                                    try managedContext.save()
                                } catch let error {
                                    print("Failed to save ingredients of recipe to store. Error: \(error)")
                                }
                            }
                        }
                    }
                    actions.append(ingredientAction)
                }
            }
        } catch let error {
            print("Failed to load stores for preview actions. Error: \(error)")
        }
        
        return actions
    }
    
    // Airprint help from: https://www.youtube.com/watch?v=NAmj9v-CBGg
    func executeAirPrint() {
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "Printing recipe"
        printInfo.outputType = .general
        printController.printInfo = printInfo
        printController.delegate = self
        UIGraphicsBeginImageContext(view.bounds.size)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        if let screenshot = UIGraphicsGetImageFromCurrentImageContext() {
            printController.printingItem = screenshot
        } else {
            printController.printingItem = recipeImageBackground!
        }
        
        printController.present(animated: true) { (_, isPrinted, error) in
            if error == nil {
                if isPrinted {
                    print("Successfully printed")
                } else {
                    print("Failed to print")
                }
            }
        }
    }
    
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
                recipePopVC.title = ""
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
                    recipePopVC.website = websiteURL
                    recipePopVC.image = recipeImageBackground
                } else {
                    recipePopVC.recipeID = 0
                }
                recipePopVC.delegate = self
            }
        } else if segue.identifier == "SelectDateForMeal" {
            if let dateSelectionVC = segue.destination as? DateSelectionViewController {
                dateSelectionVC.recipeName = recipeNameText
                dateSelectionVC.itemNeeded = ingredients?[0]
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
                
                recipeNameText = recipe.value(forKey: "recipeName") as? String
                recipeName.text = recipeNameText
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
                websiteURL = (recipe.value(forKey: "websiteURL") as! String)
                instructionsText = (recipe.value(forKey: "prepInstructions") as! String)
                instructions.text = instructionsText
                prepTimeText = "Prep Time: \(recipe.value(forKey: "prepTime") as! Int) minutes"
                prepTime.text = prepTimeText
            }
        } catch let error {
            print("Failed to fetch. Error: \(error)")
        }
        
    }
}

