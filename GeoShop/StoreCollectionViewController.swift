//
//  SecondViewController.swift
//  GeoShopping
//
//  Created by Mischa Nee on 11/20/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import UIKit
import CoreData
import MapKit
import MobileCoreServices

class StoreCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ListTableViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIViewControllerPreviewingDelegate {
    
    var stores: [NSManagedObject]? {
        get {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Store")
            do {
                return try managedContext.fetch(fetchRequest)
            } catch let error as NSError {
                print("Failed to load stored data. Error: \(error)")
            }
            return nil
        }
    }

    @IBOutlet weak var storeCollectionView: UICollectionView! {
        didSet {
            storeCollectionView.dataSource = self
            storeCollectionView.delegate = self
            storeCollectionView.alwaysBounceVertical = true
        }
    }
    
    @IBOutlet weak var backgroundImage: UIImageView! {
        didSet {
            if let data = UserDefaults.standard.object(forKey: "savedBackgroundImage") as? NSData {
                backgroundImage.image = UIImage(data: data as Data)
            }
        }
    }
    
    @IBOutlet weak var cameraButton: UIBarButtonItem! {
        didSet {
            cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        }
    }
    
    // TODO: Fix aspect ratio, image stretching
    @IBAction func selectBackground(_ sender: UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeImage as String]
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image =  info[UIImagePickerControllerOriginalImage] as? UIImage {
            backgroundImage.image = image
            
            // UserDefaults help from https://www.youtube.com/watch?v=ggptRs89DNk
            let imageData:NSData = UIImageJPEGRepresentation(image, 0.5)! as NSData
            UserDefaults.standard.set(imageData, forKey: "savedBackgroundImage")
        }
        
        picker.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Shopping Lists"
        registerForPreviewing(with: self, sourceView: storeCollectionView)
    }
    
    var flowLayout: UICollectionViewFlowLayout? {
        return storeCollectionView?.collectionViewLayout as? UICollectionViewFlowLayout
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        storeCollectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let numItems = stores?.count { return numItems }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = storeCollectionView.dequeueReusableCell(withReuseIdentifier: "StoreCollectionViewCell", for: indexPath)
        if let storeCell = cell as? StoreCollectionViewCell {
            // TODO: Fix to ensure title fits
            
            let store = stores![indexPath.item] // Force unwrap because guaranteed to be populated
            storeCell.storeName.text = store.value(forKey: "storeName") as? String
            
            // TODO: Fix to get proper count after adding and pressing back
            let numItems = (store.value(forKey: "storeItemList") as? [String])?.count
            storeCell.itemsNeededText.text = "\(numItems ?? 0) Items Needed"
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectStoreList(_:)))
            storeCell.addGestureRecognizer(tap)
            DispatchQueue.global(qos: .userInitiated).async {
                if let urlString = (store.value(forKey: "urlTitle") as? String), let url = URL(string: urlString) {
                    if let data = try? Data(contentsOf: url) {
                        if let image = UIImage(data: data){
                            DispatchQueue.main.async {
                                storeCell.storeImage.image = image
                            }
                        }
                    }
                }
            }
            
        }
        return cell
    }
    
    @objc func selectStoreList(_ sender: UITapGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.ended, let storeCell = sender.view as? StoreCollectionViewCell {
            if let indexPath = storeCollectionView.indexPath(for: storeCell) {
                performSegue(withIdentifier: "ShowStoreList", sender: stores![indexPath.item])
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowStoreList" {
            if let listVC = segue.destination.contents as? ListTableViewController {
                listVC.itemsInList = (sender as? NSManagedObject)?.value(forKey: "storeItemList") as? [String]
                listVC.title = (sender as? NSManagedObject)?.value(forKey: "storeName") as? String
                listVC.delegate = self
                listVC.storeIndexInCollection = stores?.index(of: (sender as? NSManagedObject)!)
            }
        } else if segue.identifier == "DisplayMap" {
            if let mapVC = segue.destination.contents as? MapViewController {
                // TODO: Add in already made stores
            }
        }
    }
    
    // List Table Delegate Methods
    func itemAddedToBeSaved(withTitle itemName: String, in storeIndex: Int) {
        if let storeToUpdate = stores?[storeIndex] {
            if var currentItems = storeToUpdate.value(forKey: "storeItemList") as? [String] {
                currentItems.append(itemName)
                storeToUpdate.setValue(currentItems, forKey: "storeItemList")
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let managedContext = appDelegate.persistentContainer.viewContext
                do {
                    try managedContext.save()
                } catch let error as NSError {
                    print("Failed to save added item. Error: \(error)")
                }
            }
            storeCollectionView.reloadData()
        }
    }
    
    func itemDeletedToBeSaved(at itemIndex: Int, in storeIndex: Int) {
        if let storeObject = stores?[storeIndex] {
            if var updatedItems = (storeObject.value(forKey: "storeItemList") as? [String]) {
                updatedItems.remove(at: itemIndex)
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let managedContext = appDelegate.persistentContainer.viewContext
                storeObject.setValue(updatedItems, forKey: "storeItemList")
                
                do {
                    try managedContext.save()
                } catch let error {
                    print("Failed to delete item in store list from core data. Error: \(error)")
                }
                storeCollectionView.reloadData()
            }
        }
    }
    
    func storeDeleted(_ storeIndex: Int) {
        if let storeObject = stores?[storeIndex] {
            storeObject.removeFromCore()
        }
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        let managedContext = appDelegate.persistentContainer.viewContext
//        managedContext.delete((stores?.remove(at: storeIndex))!)
//        do {
//            try managedContext.save()
//        } catch let error as NSError{
//            print("Failed to save delete. Error: \(error)")
//        }
        storeCollectionView.reloadData()
    }
    
    // Peeking with help from https://krakendev.io/peek-pop/
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = storeCollectionView.indexPathForItem(at: location), let cell = stores?[indexPath.item] {
            let previewVC = storyboard?.instantiateViewController(withIdentifier: "ListTableVC")
            if let listVC = previewVC as? ListTableViewController {
                listVC.itemsInList = cell.value(forKey: "storeItemList") as? [String]
                listVC.title = cell.value(forKey: "storeName") as? String
                listVC.delegate = self
                listVC.storeIndexInCollection = indexPath.item
                return listVC
            }
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: nil)
    }


}

