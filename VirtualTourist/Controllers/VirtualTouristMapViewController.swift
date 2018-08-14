//
//  VirtualTouristMapViewController.swift
//  VirtualTourist
//
//  Created by Ziv Zalzstein on 11/08/2018.
//  Copyright © 2018 Ziv. All rights reserved.
//

import UIKit
import MapKit

class VirtualTouristMapViewController: UIViewController, MKMapViewDelegate {
    
    //MARK: -Properties
    var selectedAnnotation: MKPointAnnotation?
    var topBarHeight: CGFloat = 0

    //MARK: -Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var deletePinsLabel: UILabel!
    
    @IBOutlet var longPressGesture: UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTopBarHeight()
        configureUI()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.setTopBarHeight()
        }
    }
    
    fileprivate func setTopBarHeight() {
        self.topBarHeight = UIApplication.shared.statusBarFrame.size.height +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
        print(self.topBarHeight)
    }
    
    @IBAction func userDidLongPressMap(_ sender: UILongPressGestureRecognizer) {
        let touchPoint = sender.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        mapView.addAnnotation(annotation)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        selectedAnnotation = view.annotation as? MKPointAnnotation
        print(selectedAnnotation!.coordinate)
        
        let mode = navigationItem.rightBarButtonItem?.title
        
        if mode == "Edit" {
        
        let storyboard = UIStoryboard (name: "Main", bundle: nil)
        let annotationDetailVC = storyboard.instantiateViewController(withIdentifier: "AnnotationDetailViewController")
        navigationController?.pushViewController(annotationDetailVC, animated: true)
            
        } else if mode == "Done" {
            print("removing pin in selected annotation")
            mapView.removeAnnotation(selectedAnnotation!)
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            /*pinView!.canShowCallout = true
            pinView!.tintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)*/
        } else {
            pinView!.annotation = annotation
        }
        print("returning pinView")
        return pinView
    }
    
    func configureUI(){
        setNavigationBar()
        deletePinsLabel.backgroundColor = UIColor.red
        deletePinsLabel.isHidden = true
    }
    
    func setNavigationBar(){
        
        self.navigationItem.title = "Virtual Tourist"
        
        configureEditButton()
        
        let backButton = UIBarButtonItem(title: " OK", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
        
        self.navigationItem.backBarButtonItem = backButton
    }
    
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
    
    

    

    
    /*override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUIEnabled(false)
        updateData()
    }*/
    
    /*func setUIEnabled(_ enabled: Bool) {
        if (enabled) {
            self.activityIndicator.alpha = 0.0
            self.activityIndicator.stopAnimating()
            self.mapView.alpha = 1.0
        } else {
            self.activityIndicator.alpha = 1.0
            self.activityIndicator.startAnimating()
            self.mapView.alpha = 0.5
        }
    }*/
    
    
    /*func updateData(){
        
        //clearing previous data
        self.mapView.removeAnnotations(self.mapView.annotations)
        //The Location array is an array of dictionary objects that hold the students info
        let locations = OTMClient.sharedInstance().students
        
        if locations.count == 0 {
            setUIEnabled(true)
            return
        }
        
        var annotations = [MKPointAnnotation]()
        
        for dictionary in locations {
            
            var coordinate = CLLocationCoordinate2D()
            let annotation = MKPointAnnotation()
            
            if let latitude = dictionary.latitude, let longitude = dictionary.longitude {
                let lat = CLLocationDegrees(latitude)
                let long = CLLocationDegrees(longitude)
                
                //The lat and long are used to create a CLLocationCorrdinates2D instance
                coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                
                if let first = dictionary.firstName, let last = dictionary.lastName, let mediaURL = dictionary.mediaURL {
                    annotation.coordinate = coordinate
                    annotation.title = "\(first) \(last)"
                    annotation.subtitle = mediaURL
                }
            }
            
            //Finally We place the annotation in an array of annotations
            annotations.append(annotation)
        }
        
        performUIUpdatesOnMain {
            self.mapView.addAnnotations(annotations)
            self.setUIEnabled(true)
        }
        
    }*/
    
    // MARK: MKMapViewDelegate
    
    /*func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.tintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            pinView!.annotation = annotation
        }
        print("returning pinView")
        return pinView
    }*/
    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    /*func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            let app = UIApplication.shared
            if let toOpen = URL(string: (view.annotation?.subtitle!)!) {
                app.open(toOpen, options: [:])
            }
        }
    }*/
}
