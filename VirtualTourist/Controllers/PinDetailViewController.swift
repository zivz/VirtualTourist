//
//  PinDetailViewController.swift
//  VirtualTourist
//
//  Created by Ziv Zalzstein on 12/08/2018.
//  Copyright © 2018 Ziv. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PinDetailViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, MKMapViewDelegate {
    
    //MARK: -Outlets
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    //MARK: -Properties
    var photoURLs: [VTPhoto] = [VTPhoto]()
    var pin: Pin!
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    let regionRadius: CLLocationDistance = 25000
    var blockOp: [BlockOperation] = []
    
    //MARK: -FRC Setup
    
    fileprivate func setupFetchedResultsController() {
        
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin)-photos")
        fetchedResultsController.delegate = self
        
        performFetch()
    }
    
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    //MARK: -Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.allowsMultipleSelection = true
        setupFetchedResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        collectionView.restore()
        collectionButton.setTitle("New Collection", for: .normal)
        if let indexPaths = collectionView.indexPathsForSelectedItems {
            for index in indexPaths {
                collectionView.deselectItem(at: index, animated: true)
            }
            collectionView.reloadItems(at: indexPaths)
        }
        reloadMapPin()
        updateData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    //MARK: -UI Setup for cells in CollectionView
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.flowLayout.invalidateLayout()
            self.setItemSize()
        }
    }
    
    fileprivate func setItemSize() {
        let space: CGFloat = 4.0
        flowLayout.scrollDirection = .vertical
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        
        let cellsPerRow: CGFloat = 3.0
        
        let widthAvailableForCellsInRow = (collectionView.frame.size.width) - (cellsPerRow - 1.0) * space
        
        flowLayout.itemSize = CGSize(width: widthAvailableForCellsInRow / cellsPerRow, height: widthAvailableForCellsInRow / cellsPerRow)
    }
    
    func updateData(){
        
        if let count = fetchedResultsController.fetchedObjects?.count, count > 0 {
            collectionView.reloadData()
            return
        }
        
        //Otherwise go and bring me the photos
        self.pin.page = 1
        getPhotosFromAPI()
        
    }
    
    func getPhotosFromAPI() {
        
        VirtualTouristClient.sharedInstance().getImagesByPin(page: pin.page, lat: pin.lat, lon: pin.lon) {  (totalPages, results, error) in
            
            guard error == nil else {
                return
            }
            
            guard let results = results else {
                return
            }
            
            performUIUpdatesOnMain {
                self.photoURLs = results
                if self.photoURLs.isEmpty {
                    self.collectionView.setEmptyMessage("No photos for this pin.")
                } else {
                    self.collectionView.restore()
                }
                if self.pin.page == 1 {
                    self.pin.pages = totalPages
                }
                self.getImagesFromDictionary()
            }
            
        }
    }
    
    func getImagesFromDictionary() {
        
        for imageDictionary in self.photoURLs {
            VirtualTouristClient.sharedInstance().getPhotoFromResults(photo: imageDictionary) { (data, error) in
                
                guard error == nil else {
                    print ("ERROR in getting photos")
                    return
                }
                
                guard let imageData = data else {
                    return
                }
                
                performUIUpdatesOnMain {
                    self.addPhoto(data: imageData as Data)
                }
            }
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    fileprivate func setUI(_ cell: PhotoCollectionViewCell, enabled: Bool) {
        
        if enabled {
            cell.layer.cornerRadius = 0
            cell.flickrImageView.backgroundColor = UIColor.clear
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.alpha = 0.0
        } else {
            cell.flickrImageView.backgroundColor = UIColor.darkGray
            cell.layer.cornerRadius = 8
            cell.layer.masksToBounds = true
            cell.activityIndicator.startAnimating()
            cell.activityIndicator.alpha = 1.0
        }
    }
    
    func configureCell(_ cell: PhotoCollectionViewCell, atIndexPath indexPath: IndexPath)  {
        
        //Fetch Record
        let photo = fetchedResultsController.object(at: indexPath)
        
        cell.flickrImageView?.contentMode = .scaleToFill
        cell.flickrImageView?.image = UIImage(data: photo.pinImage!)
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let reuseCellId = "pinDetailCollectionCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseCellId, for: indexPath) as! PhotoCollectionViewCell
        
        setUI(cell, enabled: false)
        
        configureCell(cell, atIndexPath: indexPath)
        
        setUI(cell, enabled: true)
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let selectedItems = collectionView.indexPathsForSelectedItems?.count ?? 0
        
        //Once I've selected the first cell I'm changing the text
        if selectedItems == 1 {
            collectionButton.setTitle("Remove Selected Pictures", for: .normal)
        }
        
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.alpha = 0.25
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        //nothing is selected
        if collectionView.indexPathsForSelectedItems?.count == 0 {
            collectionButton.setTitle("New Collection", for: .normal)
        }
        
        let cell = collectionView.cellForItem(at: indexPath)
        
        cell?.alpha = 1.0
    }
    
    //MARK: -New Collection/Remove Images
    
    @IBAction func collectionViewButtonTapped(_ sender: Any) {
        
        if collectionButton.titleLabel!.text == "New Collection" {
            handleNewCollection()
        } else {
            handleRemoveSelectedPhotos()
        }
    }
    
    func handleNewCollection() {
        pin.page += 1
        if pin.page > pin.pages {
            pin.page = 1
        }
        
        if let newFetch = self.fetchedResultsController.fetchedObjects {
            for object in newFetch {
                dataController.viewContext.delete(object)
            }
            
            try? dataController.viewContext.save()
        }
        
        performUIUpdatesOnMain {
            self.photoURLs.removeAll()
            self.getPhotosFromAPI()
        }
        
    }
    
    func handleRemoveSelectedPhotos() {
        guard let indexPaths = collectionView.indexPathsForSelectedItems else { return }
        print ("number of items to delete is \(indexPaths.count)")
        for indexPath in indexPaths {
            removePhoto(at: indexPath)
        }
        
        try? dataController.viewContext.save()
        
        performUIUpdatesOnMain {
            self.collectionButton.setTitle("New Collection", for: .normal)
        }
    }
    
    //MARK: -Photo Object Helpers
    
    func addPhoto(data: Data) {
        let photo = Photo(context: dataController.viewContext)
        photo.creationDate = Date()
        photo.pinImage = data
        photo.pin = pin
        try? dataController.viewContext.save()
    }
    
    func removePhoto(at indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
    }
    
    //MARK:- Map Helpers
    
    func reloadMapPin(){
        
        let annotation = MKPointAnnotation()
        
        guard let pin = pin else { return }
        annotation.coordinate.latitude = pin.lat
        annotation.coordinate.longitude = pin.lon
        
        //Finally We place the annotation in the map
        self.mapView.addAnnotation(annotation)
        centerMapOnLocation(coordinate: annotation.coordinate)
        
    }
    
    func centerMapOnLocation(coordinate: CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.tintColor = .red
            
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
}

//MARK: -FRC Delegate
extension PinDetailViewController: NSFetchedResultsControllerDelegate{
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOp.removeAll(keepingCapacity: false)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        switch type {
        case .insert:
            print ("INSERT")
            blockOp.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertSections(NSIndexSet(index: sectionIndex) as IndexSet)
                    }
                })
            )
        case .delete:
            print ("DELETE")
            blockOp.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet)
                    }
                })
            )
        default:
            print ("DEFAULT")
            blockOp.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadSections(NSIndexSet(index: sectionIndex) as IndexSet)
                    }
                })
            )
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            print ("insert")
            blockOp.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItems(at: [newIndexPath!])
                    }
                })
            )
        case .delete:
            print ("delete")
            blockOp.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItems(at: [indexPath!])
                    }
                })
            )
        case .update:
            blockOp.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        let cell = this.collectionView.cellForItem(at: indexPath!) as! PhotoCollectionViewCell
                        this.configureCell(cell, atIndexPath: indexPath!)
                    }
                })
            )
        case .move:
            blockOp.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
                    }
                })
            )
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView.performBatchUpdates({ () -> Void in
            for blockOperation in self.blockOp {
                blockOperation.start()
            }
        }, completion: { (finished) -> Void in
            self.blockOp.removeAll(keepingCapacity: false)
        })
    }
}

//MARK: -Extension for empty Message setup
extension UICollectionView {
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width:self.bounds.width, height: self.bounds.height))
        messageLabel.text = message
        messageLabel.textColor = UIColor.black
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 16.0)
        messageLabel.sizeToFit()
        self.backgroundView = messageLabel
    }
    
    func restore() {
        self.backgroundView = nil
    }
}
