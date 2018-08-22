//
//  VirtualTouristMapViewController.swift
//  VirtualTourist
//
//  Created by Ziv Zalzstein on 11/08/2018.
//  Copyright © 2018 Ziv. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class VirtualTouristMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    //MARK: -Properties
    var selectedAnnotation: MKPointAnnotation?
    var topBarHeight: CGFloat = 0
    var pins: [Pin] = []
    var selectedPin: Pin!
    
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var dataController: DataController!
    var operationQueue: [BlockOperation]!
    
    //MARK: -Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletePinsLabel: UILabel!
    @IBOutlet var longPressGesture: UILongPressGestureRecognizer!
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        
        fetchedResultsController.delegate = self
    }
    
    //MARK: -Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        if let region = getPersistedRegion() {
            mapView.setRegion(region, animated: true)
        }
        setupFetchedResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        reloadPins()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.setTopBarHeight()
        }
    }
    
    //MARK: -UI Configuration
    fileprivate func setTopBarHeight() {
        self.topBarHeight = UIApplication.shared.statusBarFrame.size.height +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }
    
    func configureUI(){
        setTopBarHeight()
        setNavigationBar()
        deletePinsLabel.backgroundColor = UIColor.red
        deletePinsLabel.isHidden = true
    }
    
    func setNavigationBar(){
        
        self.navigationItem.title = "Virtual Tourist"
        configureEditButton()
        
    }
    
    //MARK: -Buttons configuration
    fileprivate func configureEditButton() {
        let editButton = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.plain, target: self, action: #selector(edit))
        
        self.navigationItem.rightBarButtonItem = editButton
    }
    
    fileprivate func configureDoneButton() {
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(done))
        
        self.navigationItem.rightBarButtonItem = doneButton
        
    }
    
    @objc func edit() {
        setView(view: deletePinsLabel, hidden: false)
        longPressGesture.isEnabled = false
        configureDoneButton()
    }
    
    @objc func done() {
        setView(view: deletePinsLabel, hidden: true)
        longPressGesture.isEnabled = true
        configureEditButton()
    }
    
    //MARK: -Gesture
    @IBAction func userDidLongPressMap(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.recognized {
            let touchPoint = sender.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            addPin(annotation)
        }
    }
    
    //MARK:- Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let backButton = UIBarButtonItem(title: "OK", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
        
        self.navigationItem.backBarButtonItem = backButton
        
        if segue.identifier == "showPinDetailSegue" {
            if let pinDetailVC = segue.destination as? PinDetailViewController {
                pinDetailVC.dataController = dataController
                if let selectedAnnotation = selectedAnnotation {
                    
                    for pin in (fetchedResultsController.fetchedObjects)! {
                        if selectedAnnotation.coordinate.latitude == pin.lat, selectedAnnotation.coordinate.longitude == pin.lon {
                            pinDetailVC.pin = pin
                        }
                    }
                    
                }
            }
        }
    }
    
    //MARK: - Helpers
    func setView(view: UIView, hidden: Bool) {
        UIView.transition(with: view, duration: 0.3, options: .showHideTransitionViews, animations: {
            view.isHidden = hidden
            for constraint in view.constraints {
                if constraint.identifier == "pinLabelHeightConstraint" {
                    constraint.constant = hidden ? 0 : self.topBarHeight
                    view.layoutIfNeeded()
                }
            }
            for constraint in self.view.constraints {
                if constraint.identifier == "mapViewTopConstrain" {
                    constraint.constant = hidden ? 0 : -self.topBarHeight
                    self.mapView.layoutIfNeeded()
                }
            }
        })
    }
    
    func reloadPins(){
        
        //clearing previous data
        mapView.removeAnnotations(mapView.annotations)
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
        // Populate the map view
        guard let pins = fetchedResultsController.fetchedObjects else {
            return
        }
        
        var annotations = [MKPointAnnotation]()
        
        for pin in pins {
            
            var coordinate = CLLocationCoordinate2D()
            let annotation = MKPointAnnotation()
            
            let lat = CLLocationDegrees(pin.lat)
            let long = CLLocationDegrees(pin.lon)
            
            //The lat and long are used to create a CLLocationCorrdinates2D instance
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            annotation.coordinate = coordinate
            //Finally We place the annotation in an array of annotations
            annotations.append(annotation)
        }
        
        performUIUpdatesOnMain {
            self.mapView.addAnnotations(annotations)
        }
        
        self.pins = pins
        
    }
    
    func addPin(_ annotation: MKPointAnnotation) {
        
        let pin = Pin(context: dataController.viewContext)
        pin.lat = annotation.coordinate.latitude
        pin.lon = annotation.coordinate.longitude
        pin.creationDate = Date()
        try? dataController.viewContext.save()
    }
    
    func removePin(_ annotation: MKPointAnnotation) {
        
        for pin in (fetchedResultsController.fetchedObjects)! {
            if annotation.coordinate.latitude == pin.lat, annotation.coordinate.longitude == pin.lon {
                dataController.viewContext.delete(pin)
                try? dataController.viewContext.save()
            }
        }
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            
            pinView?.animatesDrop = true
            
        } else {
            pinView?.annotation = annotation
            pinView?.animatesDrop = true
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        selectedAnnotation = view.annotation as? MKPointAnnotation
        let mode = navigationItem.rightBarButtonItem?.title
        
        if mode == "Edit" {
            performSegue(withIdentifier: "showPinDetailSegue", sender: nil)
        } else if mode == "Done" {
            removePin(selectedAnnotation!)
            self.mapView.removeAnnotation(selectedAnnotation!)
        }
        
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // save the map center and zoom level as soon as the map region has changed
        
        let defaults = UserDefaults.standard
        defaults.set(mapView.centerCoordinate.latitude, forKey: "lat")
        defaults.set(mapView.centerCoordinate.longitude, forKey: "lon")
        defaults.set(mapView.region.span.latitudeDelta, forKey: "latDelta")
        defaults.set(mapView.region.span.longitudeDelta, forKey: "lonDelta")
        
    }
    
    func getPersistedRegion() -> MKCoordinateRegion? {
        let defaults = UserDefaults.standard
        
        var region: MKCoordinateRegion?
        
        if let lat = defaults.object(forKey: "lat") as? Double,
            let lon = defaults.object(forKey: "lon") as? Double,
            let latDelta = defaults.object(forKey: "latDelta") as? Double,
            let lonDelta = defaults.object(forKey: "lonDelta") as? Double {
            
            let center: CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat,lon)
            let span: MKCoordinateSpan = MKCoordinateSpanMake(latDelta,lonDelta)
            region = MKCoordinateRegionMake(center,span)
        }
        return region
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        let pin = anObject as! Pin
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: pin.lat, longitude: pin.lon)
        
        switch type{
        case .insert:
            mapView.addAnnotation(pointAnnotation)
        case .delete:
            mapView.removeAnnotation(pointAnnotation)
        default:
            break
        }
    }
    
    
}


