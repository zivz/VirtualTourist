//
//  VirtualTouristPhoto.swift
//  VirtualTourist
//
//  Created by Ziv Zalzstein on 13/08/2018.
//  Copyright © 2018 Ziv. All rights reserved.
//

import Foundation

struct VTPhoto {
    
    // MARK: Properties
    
    let id: String?
    let secret: String?
    let server: String?
    let farm: Int?
  
    // MARK: Initializers
    
    //construct a VirtualTourist Photo from a dictionary
    
    init(dictionary: [String:AnyObject]) {
        
        id = dictionary[VirtualTouristClient.FlickrResponseKeys.Id] as? String
        secret = dictionary[VirtualTouristClient.FlickrResponseKeys.Secret] as? String
        server = dictionary[VirtualTouristClient.FlickrResponseKeys.Sefver] as? String
        farm = dictionary[VirtualTouristClient.FlickrResponseKeys.Farm] as? Int
     
    }
    
    static func photoFromResults(_ results: [[String:AnyObject]]) -> [VTPhoto] {
        
        var photos = [VTPhoto]()
        
        //iterate through array of dictionaries, each Student is a dictionary
        for result in results {
            photos.append(VTPhoto(dictionary: result))
        }
        return photos
    }
    
    
}

