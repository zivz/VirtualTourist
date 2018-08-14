//
//  PinDetailViewController.swift
//  VirtualTourist
//
//  Created by Ziv Zalzstein on 12/08/2018.
//  Copyright © 2018 Ziv. All rights reserved.
//

import UIKit


class PinDetailViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    
    //MARK: -Properties
    var photos: [VTPhoto] = [VTPhoto]()
    
    //MARK: -Outlets
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateData()
    }
    
    func updateData(){
        VirtualTouristClient.sharedInstance().getImagesByPin() {  (results, error) in
            
            guard error == nil else {
                return
            }
            
            guard let results = results else {
                return
            }
            
            performUIUpdatesOnMain {
                self.collectionView.reloadData()
                self.photos = results
            }
            
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let space: CGFloat = 4.0
        flowLayout.scrollDirection = .vertical
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        
        let cellsPerRow: CGFloat = 3.0
        //let cellsPerColumn: CGFloat = 7.0
        
        let widthAvailableForCellsInRow = (collectionView.frame.size.width) - (cellsPerRow - 1.0) * space
        //let widthAvailableForCellsInColumn = (collectionView.frame.size.height) - (cellsPerColumn - 1.0) * space
        
        flowLayout.itemSize = CGSize(width: widthAvailableForCellsInRow / cellsPerRow, height: widthAvailableForCellsInRow / cellsPerRow)
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "pinDetailCollectionCell", for: indexPath) as! PhotoCollectionViewCell
        
        cell.flickrImageView.backgroundColor = UIColor.clear
        cell.activityIndicator.startAnimating()
        cell.activityIndicator.alpha = 1.0
        
        let imageDictionary = self.photos[indexPath.row]
        
        VirtualTouristClient.sharedInstance().getPhotoFromResults(photo: imageDictionary) { (data, error) in
            
            guard error == nil else {
                return
            }
          
            guard let imageData = data else {
                return
            }
            
            performUIUpdatesOnMain {
                cell.flickrImageView?.contentMode = .scaleAspectFill
                cell.flickrImageView?.image = UIImage(data: imageData as Data)
                cell.activityIndicator.stopAnimating()
                cell.activityIndicator.alpha = 0.0
            }
            
        }
        
        return cell
    }
    
    /*override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
        // Grab the DetailVC from Storyboard
        let detailController = self.storyboard!.instantiateViewController(withIdentifier: "MemeDetailViewController") as! MemeDetailViewController
        
        //Populate view controller with data from the selected item
        detailController.meme = memes[(indexPath as NSIndexPath).row]
        
        // Hide the status bar
        statusBarShouldBeHidden = true
        UIView.animate(withDuration: 0.25) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
        // Present the view controller using navigation
        navigationController!.pushViewController(detailController, animated: true)
}*/
}
