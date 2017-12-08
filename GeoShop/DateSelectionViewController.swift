//
//  DateSelectionViewController.swift
//  GeoShop
//
//  Created by Mischa Nee on 12/6/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import UIKit
import EventKit

class DateSelectionViewController: UIViewController {

    var recipeName: String?
    @IBOutlet weak var dateView: UIView! {
        didSet {
            dateView.layer.cornerRadius = 5.0
            dateView.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var datePicker: UIDatePicker!
    
    // With some help from https://www.youtube.com/watch?v=sSFzcvvs4Oc
    @IBAction func confirmDate(_ sender: UIButton) {
        let date = datePicker.date
        
        // Breakfast: [6 - 10]
        // Lunch: [11 - 15]
        // Dinner: [16 - 23]
        // Meal (Default): [0 - 5]
        var meal = ""
        let hour = Calendar.current.dateComponents([.hour], from: date)
        switch hour.hour! {
        case 6,7,8,9,10:
            meal = "Breakfast"
        case 11,12,13,14,15:
            meal = "Lunch"
        case 16,17,18,19,20,21,22,23:
            meal = "Dinner"
        default:
            meal = "Meal"
        }
        
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: .event) { (granted, error) in
            if granted && error == nil {
                let event = EKEvent(eventStore: eventStore)
                event.title = "\(meal) - \(self.recipeName!)"
                event.startDate = date
                event.endDate = date.addingTimeInterval(3600)
                event.notes = "Event created by GeoShop"
                event.calendar = eventStore.defaultCalendarForNewEvents
                do {
                    try eventStore.save(event, span: .thisEvent)
                } catch let error {
                    print("Failed to save meal in calendar. Error: \(error)")
                }
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
