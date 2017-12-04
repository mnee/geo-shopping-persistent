//
//  RecipePopoverViewController.swift
//  GeoShop
//
//  Created by Mischa Nee on 12/3/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices

class RecipePopoverViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var recipeImage: UIImageView! {
        didSet {
            recipeImage.image = UIImage(named: "RecipeDefault")?.resizeImage(targetSize: CGSize(width: recipeImage.bounds.width, height: recipeImage.bounds.height))
        }
    }
    var imageSet: Bool = false
    var recipeID: Int?
    
    weak var delegate: RecipePopoverViewControllerDelegate?
    
    @IBOutlet weak var recipeNameTF: UITextField!
    @IBOutlet weak var prepTimeTF: UITextField!
    @IBOutlet weak var ingredientsTF: UITextField!
    @IBOutlet weak var instructionsTF: UITextField!
    
    @IBAction func cancelPopover(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveRecipe(_ sender: UIButton) {
        if let recipeName = recipeNameTF.text,
            let prepTime = prepTimeTF.text,
            let ingredients = ingredientsTF.text,
            let instructions = instructionsTF.text {
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.persistentContainer.viewContext
            let entity = NSEntityDescription.entity(forEntityName: "Recipe", in: managedContext)!
            let recipe = NSManagedObject(entity: entity, insertInto: managedContext)
            
            recipe.setValue(recipeName, forKey: "recipeName")
            recipe.setValue(instructions, forKey: "prepInstructions")
            recipe.setValue(Int(prepTime), forKey: "prepTime")
            recipe.setValue(ingredients.components(separatedBy: ", "), forKey: "ingredients")
            recipe.setValue(imageSet ? "Recipe\(recipeID!)" : "Default", forKey: "imageURL")
            
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Failed to save data. Error: \(error)")
            }
            delegate?.didUpdateRecipes()
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBOutlet weak var selectImageButton: UIButton! {
        didSet {
            selectImageButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        }
    }
    @IBAction func selectNewImage(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeImage as String]
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image =  info[UIImagePickerControllerOriginalImage] as? UIImage {
            recipeImage.image = image
            
            let imageData = UIImageJPEGRepresentation(image, 0.5)
            do {
                let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
                let fileURL = documentDirectory.appendingPathComponent("Recipe\(recipeID!)")
                try imageData?.write(to: fileURL)
                imageSet = true
            } catch {
                print("Failed to save recipe image. Error: \(error)")
            }
        }
        
        picker.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.cornerRadius = 10.0
        view.layer.masksToBounds = true
        // Do any additional setup after loading the view.
    }

}
