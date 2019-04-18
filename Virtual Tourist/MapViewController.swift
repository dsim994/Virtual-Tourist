//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Dylan Simerly on 4/18/17.
//  Copyright © 2017 dylansimerly. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    let stack = CoreDataManager.sharedInstance
    var centerCoordinate: CLLocationCoordinate2D?
    var centerCoordinateLongitude: CLLocationDegrees?
    var centerCoordinateLatitude: CLLocationDegrees?
    var pins = [Pin]()
    var selectedPin: Pin? = nil
    var editingPins = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        addGestureRecognizer()
        loadPinsFromDatabase()
        deleteLabel.isHidden = true
    }
    
    func addGestureRecognizer() {
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(self.addPinToMap(gestureRecognizer:)))
        lpgr.minimumPressDuration = 0.5   // half-second hold for  pin creation
        lpgr.delegate = self
        self.mapView.addGestureRecognizer(lpgr)
    }
    
    @objc func addPinToMap(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == UIGestureRecognizer.State.began {
            
            let point = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            let latitude = coordinate.latitude
            let longitude = coordinate.longitude
            print ("Coordinates of the Pin [LAT LONG] : \(latitude) \(longitude)")
            
            let pin = Pin(context: stack.context)
            pin.latitude = latitude
            pin.longitude = longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            stack.save()
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            // Force Initialize pinView.
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        } else {
            pinView!.annotation = annotation
        }
        
        pinView!.pinTintColor = UIColor.red
        pinView?.animatesDrop = true
        pinView?.isDraggable = true
        return pinView
    }
    
    func loadPinsFromDatabase() {
        var pins = [Pin]()
        var annotations = [MKAnnotation]()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        do {
            let results = try stack.context.fetch(fetchRequest)
            if let results = results as? [Pin] {
                pins = results
                print("Number of Pins : \(pins.count)")
            }
        } catch {
            print("Couldn't find any Pins")
        }
        
        for (_,item) in pins.enumerated() {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(item.latitude),longitude: CLLocationDegrees(item.longitude))
            annotations.append(annotation)
        }
        mapView.addAnnotations(annotations)
    }
    
    @IBAction func editPressed(_ sender: Any) {
        
        if !editingPins {
            editingPins = true
            deleteLabel.isHidden = false
            navigationItem.rightBarButtonItem?.title = "Done"
        } else if editingPins {
            navigationItem.rightBarButtonItem?.title = "Edit"
            editingPins = false
            deleteLabel.isHidden = true
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let annotation = view.annotation
        
        if !editingPins {
            mapView.selectAnnotation(annotation!, animated: false)
            performSegue(withIdentifier: "showAlbum", sender: annotation )
            mapView.deselectAnnotation(annotation, animated: true)
        } else {
            mapView.removeAnnotation(view.annotation!)
            for pin in pins {
                stack.context.delete(pin)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showAlbum" {
            var pin: Pin!
            do {
                let pinAnnotation = sender as! MKAnnotation
                
                let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
                let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [pinAnnotation.coordinate.latitude, pinAnnotation.coordinate.longitude])
                fetchRequest.predicate = predicate
                let pins = try stack.context.fetch(fetchRequest)
                
                pin = pins[0]
            }
                
            catch let error as NSError {
                print("failed to get pin by object id")
                print(error.localizedDescription)
                return
            }
            
            let photosVC = segue.destination as! PhotoAlbumViewController
            photosVC.pin = Parse.toPin(sender as! MKAnnotation, pin)
        }
    }
}





