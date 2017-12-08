//
//  DateSelectionViewController.swift
//  GeoShop
//
//  Created by Mischa Nee on 12/6/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import UIKit
import EventKit
import UserNotifications

class DateSelectionViewController: UIViewController {

    var recipeName: String?
    var itemNeeded: String?
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
        addNotification(on: date)
        dismiss(animated: true, completion: nil)
    }
    
    func addNotification(on date: Date) {
        let unCenter = UNUserNotificationCenter.current()
        
        var userNotifsAllowed = true
        unCenter.getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                unCenter.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                    userNotifsAllowed = granted
                }
            }
        }
        
        if userNotifsAllowed {
            let content = UNMutableNotificationContent()
            content.title = "You're making \(recipeName!) tomorrow!"
            content.body = "Did you remember to pick up \(itemNeeded ?? "everything")?"
            content.sound = UNNotificationSound.default()
            
            let interval = date.timeIntervalSinceNow - 86400
            if interval <= 0 { return } // Do not schedule notif if less than a day away
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        
            let request = UNNotificationRequest(identifier: date.description, content: content, trigger: trigger)
            
            unCenter.add(request) { (error: Error?) in
                if error != nil {
                    print("Failed to set notification. Error: \(error!)")
                }
            }
        }
    }
}
