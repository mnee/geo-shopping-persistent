//
//  FirstViewController.swift
//  GeoShopping
//
//  Created by Mischa Nee on 11/20/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData
import UserNotifications
import AudioToolbox

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var selectedStores: [MKAnnotation] = []

    var locationManager = CLLocationManager()
    var userLocation: CLLocation?
    
    let defaultCenter = CLLocationCoordinate2D(latitude: 37.4419, longitude: -122.1430)
    let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            mapView.showsUserLocation = true
        }
        
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
    }
    
    // Bool to avoid constantly resetting location and cause glitches when user scrolls or interacts with map
    var haveSetLocation = true
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if haveSetLocation {
            userLocation = locations[0]
            mapView.region = mapView.regionThatFits(MKCoordinateRegion(center: userLocation!.coordinate, span: defaultSpan))
            haveSetLocation = false
        }
    }

    /* Citation: https://www.youtube.com/watch?v=GYzNsVFyDrU
     * Helped with search bar functionality
     */
    @IBAction func searchForStore(_ sender: UIBarButtonItem) {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        present(searchController, animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        self.view.addSubview(activityIndicator)
        
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        
        let searchRequest = MKLocalSearchRequest()
        searchRequest.naturalLanguageQuery = searchBar.text
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        
        activeSearch.start { (response, error) in
            activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            
            if response == nil {
                print("ERROR: Search failed")
            } else {
                // If valid places found, note can be multiple
                if let items = response?.mapItems {
                    for item in items {
                        let annotation = MKPointAnnotation()
                        annotation.title = item.name
                        annotation.coordinate = item.placemark.coordinate
                        self.mapView.addAnnotation(annotation)
                    }
                    self.mapView.setRegion(MKCoordinateRegionMake(CLLocationCoordinate2D(latitude: (response?.boundingRegion.center.latitude)!, longitude: (response?.boundingRegion.center.longitude)!), MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)), animated: true)
                    
                    self.addStoreButton.isHidden = false
                }
            }
        }
    }
    
    @IBOutlet weak var addStoreButton: UIButton! {
        didSet {
            addStoreButton.isHidden = true
        }
    }
    @IBOutlet weak var doneButton: UIButton!
    
    @IBAction func addStoreClicked(_ sender: UIButton) {
        if mapView.selectedAnnotations.count == 0 { return } // Guards against error when button clicked with no annotations selected
        let storeAnnotation = mapView.selectedAnnotations[0]
        
        // Citation: For getting the managed context helped by https://www.youtube.com/watch?v=TW_jcvVvPwI
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Store", in: managedContext)!
        let store = NSManagedObject(entity: entity, insertInto: managedContext)
        
        store.setValue(storeAnnotation.title!!, forKey: "storeName")
        store.setValue("https://maps.googleapis.com/maps/api/streetview?size=400x400&location=\(storeAnnotation.coordinate.latitude),\(storeAnnotation.coordinate.longitude)&key=AIzaSyAmX40dcbk2dP5oSkQCrMriWc3QNRt-KOc", forKey: "urlTitle")
        store.setValue([], forKey: "storeItemList")
        
        do {
            try managedContext.save()
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        } catch let error as NSError {
            print("Failed to save data. Error: \(error)")
        }
        selectedStores.append(mapView.selectedAnnotations[0])
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(selectedStores)
        
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
            content.title = "Take a quick detour"
            content.body = "You're passing near \(storeAnnotation.title!!) now!"
            content.sound = UNNotificationSound.default()
            
            let region = CLCircularRegion(center: storeAnnotation.coordinate, radius: 500.0, identifier: storeAnnotation.title!!)
            region.notifyOnEntry = true
            region.notifyOnExit = false
            let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
            
            let request = UNNotificationRequest(identifier: "\(storeAnnotation.title!!) location notif ", content: content, trigger: trigger)
            
            unCenter.add(request) { (error: Error?) in
                if error != nil {
                    print("Failed to set notification. Error: \(error!)")
                }
            }
        }
    }
    
}

extension UIViewController {
    var contents: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController ?? self
        } else if let tabcon = self as? UITabBarController {
            if let storeVC = tabcon.customizableViewControllers?.first {
                if let navcon = storeVC as? UINavigationController {
                    return navcon.visibleViewController ?? self
                }
            }
        }
        return self
    }
}
