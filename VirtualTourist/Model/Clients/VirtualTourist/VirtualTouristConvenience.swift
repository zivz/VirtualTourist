//
//  VirtualTouristConvenience.swift
//  VirtualTourist
//
//  Created by Ziv Zalzstein on 13/08/2018.
//  Copyright © 2018 Ziv. All rights reserved.
//

import UIKit

extension VirtualTouristClient {
    
    //MARK: GET Convenience Methods
    
    func getImagesByPin(page: Int32 = 1, lat: Double, lon: Double, completionHandlerForGetImages: @escaping (_ totalPages: Int32, _ result: [VTPhoto]?, _ errorString: String?) -> Void) {
        
        let methodParameters = [FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
                                FlickrParameterKeys.APIKey: FlickrParameterValues.APIKey,
                                FlickrParameterKeys.Lat: lat,
                                FlickrParameterKeys.Lon: lon,
                                FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
                                FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback,
                                FlickrParameterKeys.PerPage: 21,
                                FlickrParameterKeys.Page: page] as [String : AnyObject]
        
        let _ = taskForGETMethod(Constants.Flickr.APIHost, Constants.Flickr.APIPath, parameters: methodParameters) { (results, error) in
            
            if let error = error {
                print(error)
                completionHandlerForGetImages(0, nil, error.localizedDescription)
            } else {
                guard let stat = results?[FlickrResponseKeys.Status] as? String, stat == FlickrResponseValues.OKStatus else {
                    completionHandlerForGetImages(0, nil, "Flickr API returned an error. See error code and message in \(String(describing: results))")
                    print("Flickr Returned Error")
                    return
                }
                
                guard let photosDictionary = results?[FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    print("Cannot find key Photos")
                    completionHandlerForGetImages(0, nil, "Cannot find key photos in results")
                    return
                }
                
                guard let photosArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                    print("Cannot find key Photo")
                    completionHandlerForGetImages(0, nil, "Cannot find key photo in results")
                    return
                }
                
                if photosArray.count == 0 {
                    completionHandlerForGetImages(0, nil, "No Photos Found. Search Again")
                    return
                } else {
                    let photos = VTPhoto.photoFromResults(photosArray)
                    completionHandlerForGetImages(photosDictionary["pages"] as! Int32, photos, nil)
                }
            }
            
        }
    }
    
    func getPhotoFromResults(photo: VTPhoto?, completionHandlerForGetPhoto: @escaping (_ data: NSData?, _ errorString: String?) -> Void) {
        
        guard let vtPhoto = photo else {
            return
        }
        
        guard let farmId = vtPhoto.farm, let server = vtPhoto.server, let photoId = vtPhoto.id, let secret = vtPhoto.secret else {
            return
        }
        
        let apiHost = "farm\(farmId).staticflickr.com"
        let apiPath = "/\(server)/\(photoId)_\(secret).jpg"
        
        let methodParameters = [String:AnyObject]()
        
        let _ = taskForGETMethod(apiHost, apiPath, parameters: methodParameters) { (result, error) in
            
            if let error = error {
                completionHandlerForGetPhoto(nil, error.localizedDescription)
            } else {
                guard let result = result else {
                    print ("result is nil")
                    return
                }
                print("arrived to completion handler for getPhoto")
                completionHandlerForGetPhoto(result as? NSData, nil)
            }
            
        }
    }
    
    
}
