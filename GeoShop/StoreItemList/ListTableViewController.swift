//
//  ListTableViewController.swift
//  GeoShopping
//
//  Created by Mischa Nee on 11/22/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import UIKit
import MessageUI

class ListTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddListTableCellDelegate, MFMessageComposeViewControllerDelegate {
    
    var itemsInList: [String]?
    
    weak var delegate: ListTableViewControllerDelegate?
    var storeIndexInCollection: Int?
    
    // MARK: Table View Functions
    @IBOutlet weak var listTable: UITableView! {
        didSet {
            listTable.delegate = self
            listTable.dataSource = self
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsInList!.count+1 // +1 for add cell first
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.item == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewListItem", for: indexPath)
            if let newListCell = cell as? AddListTableCell {
                newListCell.delegate = self
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TableListItem", for: indexPath)
            if let tableListCell = cell as? ListTableViewCell {
                tableListCell.itemName.text = itemsInList![indexPath.item-1]
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.item != 0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if itemsInList?.remove(at: indexPath.item-1) != nil {
                delegate?.itemDeletedToBeSaved(at: indexPath.item - 1, in: storeIndexInCollection ?? 0)
                listTable.reloadData()
            }
        }
    }
    
    // MARK: MessageUI Functions
    @IBAction func sendText(_ sender: UIBarButtonItem) {
        if let messageVC = getTextMessageVC() {
            self.present(messageVC, animated: true, completion: nil)
        }
    }
    
    func getTextMessageVC() -> MFMessageComposeViewController? {
        if MFMessageComposeViewController.canSendText() {
            let messageVC = MFMessageComposeViewController()
            messageVC.messageComposeDelegate = self
            
            var messageBody = "We need "
            if itemsInList != nil {
                for itemIndex in itemsInList!.indices {
                    let item = itemsInList![itemIndex]
                    if itemIndex < itemsInList!.count - 1 {
                        messageBody += item + ", "
                    } else {
                        messageBody += "and " + item
                    }
                }
                
                messageVC.body = messageBody + " from \(self.title ?? "the store")."
            }
            messageVC.recipients = []
            return messageVC
        }
        return nil
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: AddListTableCellDelegate function
    func didSelectToBeAdded(with textToAdd: String) {
        itemsInList?.append(textToAdd)
        listTable.reloadData()
        delegate?.itemAddedToBeSaved(withTitle: textToAdd, in: storeIndexInCollection ?? 0)
    }
    
    // MARK: ActionItems
    override var previewActionItems: [UIPreviewActionItem] {
        get {
            let delete = UIPreviewAction(title: "Delete", style: .destructive) { (action, vc) in
                self.delegate?.storeDeleted(self.storeIndexInCollection!)
            }
            return [delete]
        }
    }

}
