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

class StoreCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ListTableViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var stores: [NSManagedObject]?

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
        if let image = (info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as? UIImage {
            backgroundImage.image = image
            
            let imageData:NSData = UIImageJPEGRepresentation(image, 0.5)! as NSData
            UserDefaults.standard.set(imageData, forKey: "savedBackgroundImage")
        }
        
        picker.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Shopping Lists"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Store")
        do {
            stores = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Failed to load stored data. Error: \(error)")
        }
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
            
            let store = stores![indexPath.item]
            storeCell.storeName.text = store.value(forKey: "storeName") as? String // Force unwrap because guaranteed to be populated
            
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
        }
    }
    
}

