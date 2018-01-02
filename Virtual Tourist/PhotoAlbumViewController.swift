//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Dylan Simerly on 4/18/17.
//  Copyright © 2017 dylansimerly. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var toolButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    
    let flickrClient = FlickrClient.sharedInstance
    let stack = CoreDataManager.sharedInstance
 
    var pin: Pin!
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    var insertIndexCache: [NSIndexPath]!
    var deleteIndexCache: [NSIndexPath]!
    
    var selectedPhotos = [NSIndexPath]() {
        didSet {
            toolButton.title = selectedPhotos.isEmpty ? "New Collection" : "Remove Selected Pictures"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.navigationBar.topItem!.backBarButtonItem = UIBarButtonItem(title: "OK",style:.plain,target: nil,action: nil)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        mapView.delegate = self
        mapView.addAnnotation(Parse.toMKAnnotation(self.pin))
        mapView.camera.centerCoordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        mapView.camera.altitude = 10000
        
        initializeFlowLayout()
        if fetchPhotos().isEmpty{
            searchNSavePhotos()
        }
    }
    
    func initializeFlowLayout() {
        
        collectionView?.contentMode = UIViewContentMode.scaleAspectFit
        collectionView?.backgroundColor = UIColor.white
        
        let space : CGFloat = 2.0
        let dimension = (UIDevice.current.orientation.isPortrait) ?  (self.view.frame.width - (2 * space)) / 3.0 : (self.view.frame.height - (2 * space)) / 3.0
        collectionViewFlowLayout.minimumInteritemSpacing = space
        collectionViewFlowLayout.minimumLineSpacing = space
        collectionViewFlowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }

    @IBAction func toolButtonPressed(_ sender: Any) {
        
        if selectedPhotos.isEmpty{
            deleteAllPhotos()
            searchNSavePhotos()
        } else {
            deleteSelectedPhotos()
        }
    }

    func searchNSavePhotos() {
        
        flickrClient.searchPhotos(latitude: pin.latitude, longitude: pin.longitude){ (photoURLs, error) in
            
            guard photoURLs != nil else {
                return
            }
            
            DispatchQueue.main.async {
                    for url in photoURLs! {
                        let photo = Photos(context: self.stack.context)
                        photo.pin = self.pin
                        photo.url = url
                    }
                    self.stack.save()
            }
        }
    }
    
    func deleteAllPhotos() {
        for pic in fetchedResultsController.fetchedObjects as! [Photos] {
            stack.context.delete(pic)
        }
        stack.save()
    }

    func deleteSelectedPhotos() {
        
        var picsToDelete = [Photos]()
        for indexPath in selectedPhotos {
            picsToDelete.append(fetchedResultsController.object(at: indexPath as IndexPath) as! Photos)
        }
        for pic in picsToDelete {
            stack.context.delete(pic)
        }
        stack.save()
        selectedPhotos = []
    }
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        return pinView
    }
}

extension PhotoAlbumViewController:UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath as IndexPath) as! PhotoCell
        
        if let index = selectedPhotos.index(of: indexPath as NSIndexPath) {
            selectedPhotos.remove(at: index)
        } else {
            selectedPhotos.append(indexPath as NSIndexPath)
        }
        configureCellSection(cell: cell, indexPath: indexPath as NSIndexPath)
    }

    func configureCellSection(cell: PhotoCell, indexPath: NSIndexPath) {
        
        if let _ = selectedPhotos.index(of: indexPath) {
            cell.alpha = 0.5
        } else {
            cell.alpha = 1.0
        }
    }
}

extension PhotoAlbumViewController:UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return fetchedResultsController.sections![section].numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        let pic = fetchedResultsController.object(at: indexPath) as! Photos
        
        if pic.image == nil {
            cell.activityIndicator.startAnimating()
            
            flickrClient.downloadPhotos(photoURL: pic.url!){ (image, error)  in

                guard let imageData = image,
                    let downloadedImage = UIImage(data: imageData as Data) else {
                        return
                }
                DispatchQueue.main.async {
                    
                    pic.image = imageData as Data
                        self.stack.save()
                        
                        if let updateCell = self.collectionView.cellForItem(at: indexPath) as? PhotoCell {
                            updateCell.imageView.image = downloadedImage
                            updateCell.activityIndicator.stopAnimating()
                        }
                }
                cell.imageView.image = UIImage(data: imageData as Data)
                self.configureCellSection(cell: cell, indexPath: indexPath as NSIndexPath)
            }
        } else {
            // Display From Core Data
            cell.imageView.image = UIImage(data: pic.image! as Data)
        }
        return cell
    
    }
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func fetchPhotos() -> [Photos] {
        
        var photos = [Photos]()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photos")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", pin)
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            if let results = fetchedResultsController.fetchedObjects as? [Photos] {
                photos = results
            }
        } catch {
            print("Error while trying to fetch photos.")
        }
        return photos
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        insertIndexCache = [NSIndexPath]()
        deleteIndexCache = [NSIndexPath]()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView.performBatchUpdates( {
                self.collectionView.insertItems(at: self.insertIndexCache as [IndexPath])
                self.collectionView.deleteItems(at: self.deleteIndexCache as [IndexPath])
        }, completion: nil)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:   insertIndexCache.append(newIndexPath! as NSIndexPath)
            case .delete:   deleteIndexCache.append(indexPath! as NSIndexPath)
            default: break
        }
    }
}


