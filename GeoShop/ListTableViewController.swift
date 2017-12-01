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
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    var itemsInList: [String]?
    
    weak var delegate: ListTableViewControllerDelegate?
    var storeIndexInCollection: Int?
    
    @IBOutlet weak var listTable: UITableView! {
        didSet {
            listTable.delegate = self
            listTable.dataSource = self
        }
    }
    
    @IBAction func sendText(_ sender: UIBarButtonItem) {
        if (MFMessageComposeViewController.canSendText()) {
            let messageVC = MFMessageComposeViewController()
            
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
            messageVC.messageComposeDelegate = self
            
            self.present(messageVC, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsInList!.count+1
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
    
    func didSelectToBeAdded(with textToAdd: String) {
        itemsInList?.append(textToAdd)
        listTable.reloadData()
        delegate?.itemAddedToBeSaved(withTitle: textToAdd, in: storeIndexInCollection ?? 0)
    }

    // MARK: - Table view data source

    
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
