//
//  Constants.swift
//  VirtualTourist
//
//  Created by Ziv Zalzstein on 13/08/2018.
//  Copyright © 2018 Ziv. All rights reserved.
//

import Foundation

// MARK: - Constants

extension VirtualTouristClient {

    struct Constants {
    
        // MARK: Flickr
        struct Flickr {
            static let APIScheme = "https"
            static let APIHost = "api.flickr.com"
            static let APIPath = "/services/rest"
        }
        
        struct Image {
            static let APIScheme = "https"
            static let APIHost = "farm{farm_id}.staticflickr.com"
            static let APIPath = "/{server}/{photo_id}_{secret}.jpg"
        }
    }
    
    struct Methods {
        
    }
    
    
    // MARK: Flickr Parameter Keys
    struct FlickrParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let Lat = "lat"
        static let Lon = "lon"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let PerPage = "per_page"
        static let Page = "page"
    }
    
    // MARK: Flickr Parameter Values
    struct FlickrParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "8038e961007d991a4ce44e433497fb92"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
    }
    
    // MARK: Flickr Response Keys
    struct FlickrResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Pages = "pages"
        static let PerPage = "perpage"
        static let Id = "id"
        static let Secret = "secret"
        static let Sefver = "server"
        static let Farm = "farm"
        static let Total = "total"
    }
    
    // MARK: Flickr Response Values
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }
    
    struct URLKeys {
        static let FarmID = "farm_id"
        static let Server = "server"
        static let PhotoId = "photo_id"
        static let PhotoSecret = "secret"
        
    }
    
}

