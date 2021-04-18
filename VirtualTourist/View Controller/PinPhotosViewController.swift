//
//  PinPhotosViewController.swift
//  VirtualTourist
//
//  Created by Anirudh Sohil on 03/04/21.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PinPhotosViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var delete: UIBarButtonItem!
    @IBOutlet weak var newCollection: UIButton!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var pin: Pin!
    var dataController: DataController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        newCollection.isEnabled = true
        guard let pin = pin else {
            showAlert(title: "Can't load photo album", message: "Try Again!!")
            fatalError("No pin")
        }
        setUpCollectionView()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpMapView()
        setupFetchedResultsController()
        downloadPhotoData()
        newCollection.isEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        if let pin = pin {
            let predicate = NSPredicate(format: "pin == %@", pin)
            fetchRequest.predicate = predicate
        
            print("\(pin.latitude) \(pin.longitude)")
        }
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        print(fetchedResultsController.fetchedObjects?.count ?? 0)

        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func showAlert(title: String, message: String){
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }
    
    @IBAction func newCollection(_ sender: Any) {
        guard let imageObject = fetchedResultsController.fetchedObjects else { return }
        newCollection.isEnabled = false
        for image in imageObject {
            dataController.viewContext.delete(image)
           do {
               try dataController.viewContext.save()
           } catch {
                print("Unable to delete images")
            }
        }
        downloadPhotoData()
        newCollection.isEnabled = false
    }

    
    
    func downloadPhotoData() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        print("\(String(describing: fetchedResultsController.fetchedObjects?.count))")
        guard (fetchedResultsController.fetchedObjects?.isEmpty)! else {
            activityIndicator.isHidden = true
            activityIndicator.stopAnimating()
            print("image metadata is already present. no need to re download")
            return
        }

        let pagesCount = Int(self.pin.pages)
        FlickrClient.getPhotos(latitude: pin.latitude,longitude: pin.longitude, totalPageAmount: pagesCount) {
            (photos, totalPages, error) in
            if photos.count > 0 {
                DispatchQueue.main.async {
                    if (pagesCount == 0) {
                        self.pin.pages = Int32(Int(totalPages))
                    }
                    for photo in photos {
                        let newPhoto = Photo(context: self.dataController.viewContext)
                        newPhoto.imageUrl = URL(string: photo.url_m)
                        newPhoto.imageData = nil
                        newPhoto.pin = self.pin
                        newPhoto.imageID = UUID().uuidString
                        do {
                            try self.dataController.viewContext.save()
                        } catch {
                            print("Unable to save the photo")
                        }
                    }
                }
            }
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
            self.newCollection.isEnabled = true
        }
    }

    
    @IBAction func deleteImage(_ sender: Any) {
        removeSelectedImages()
    }
    
    private func removeSelectedImages() {
        var imageIds: [String] = []
           
        if let selectedImagesIndexPaths = collectionView.indexPathsForSelectedItems {
            for indexPath in selectedImagesIndexPaths {
                let selectedImageToRemove = fetchedResultsController.object(at: indexPath)
                   
                if let imageId = selectedImageToRemove.imageID {
                    imageIds.append(imageId)
                }
            }
               
            for imageId in imageIds {
                if let selectedImages = fetchedResultsController.fetchedObjects {
                    for image in selectedImages {
                        if image.imageID == imageId {
                            dataController.viewContext.delete(image)
                        }
                        do {
                            try dataController.viewContext.save()
                        } catch {
                            print("Unable to remove the photo")
                        }
                    }
                }
            }
        }
    }
}

extension PinPhotosViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = fetchedResultsController.sections?[section].numberOfObjects ?? 0
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoItem.reuseIdentifier, for: indexPath as IndexPath) as! PhotoItem
        let photoData = self.fetchedResultsController.object(at: indexPath)
        cell.photoImageView.image = #imageLiteral(resourceName: "image-placeholder")
        if photoData.imageData == nil {
            DispatchQueue.global(qos: .background).async {
                 if let imageData = try? Data(contentsOf: photoData.imageUrl!) {
                    DispatchQueue.main.async {
                        photoData.imageData = imageData
                        do {
                            try self.dataController.viewContext.save()
                        } catch {
                            print("error in saving image data")
                        }
                        let image = UIImage(data: imageData)!
                        cell.setPhotoImageView(imageView: image, sizeFit: true)
                    }
                }
        
            }
            
        } else {
            if let imageData = photoData.imageData {
                let image = UIImage(data: imageData)!
                cell.setPhotoImageView(imageView: image, sizeFit: false)
            }
            
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoItem
        cell.checkmark.isHidden = false
        cell.isSelected = true
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoItem
        cell.checkmark.isHidden = true
        cell.isSelected = false
    }
    
    func setUpCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
        configureFlowLayout()
    }

    func configureFlowLayout() {
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
             let space: CGFloat = 3.0
             let dimension = (view.frame.size.width - (2 * space)) / 3.0
             flowLayout.minimumInteritemSpacing = space
             flowLayout.minimumLineSpacing = space
             flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        }
    }
}

extension PinPhotosViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any,
                    at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath:  IndexPath?) {
        switch type {
            case .insert:
                self.collectionView.insertItems(at: [newIndexPath!])
            case .delete:
                self.collectionView.deleteItems(at: [indexPath!])
            case .update:
                self.collectionView.reloadItems(at: [indexPath!])
            default:
                break
        }
    }
}

extension PinPhotosViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
           let reuseId = "pin"
           var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
       

           if pinView == nil {
               pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
               pinView!.canShowCallout = false
               pinView!.pinTintColor = .red
            
           } else {
               pinView!.annotation = annotation
           }
           
           pinView?.isSelected = true
           pinView?.isUserInteractionEnabled = false
           return pinView
       }
    
    func setUpMapView() {
        mapView.delegate = self
        let span = MKCoordinateSpan(latitudeDelta:  0.015, longitudeDelta: 0.015)
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
        mapView.addAnnotation(AnnotationPin(pin: pin))
    }
    
}
