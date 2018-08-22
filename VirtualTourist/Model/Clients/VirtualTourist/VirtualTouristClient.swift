//
//  VirtualTouristClient.swift
//  VirtualTourist
//
//  Created by Ziv Zalzstein on 13/08/2018.
//  Copyright © 2018 Ziv. All rights reserved.
//

import Foundation

// MARK: -VirtualTouristClient: NSObject

class VirtualTouristClient : NSObject {
    
    // MARK: Properties
    
    //shared session
    var session = URLSession.shared
    
    //MARK: Initizalizers
    
    override init() {
        super.init()
    }
    
    func taskForGETMethod(_ apiHost: String, _ apiPath: String, parameters: [String:AnyObject], completionHandlerForGET: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        // if needed add _ method: String
        
        /*2/3. Build the URL, Configure the request */
        let request = NSMutableURLRequest(url: flickrURLFromParameters(parameters, apiHost, apiPath))
        // if needed add withPathExtension: method
        
        print(request)
        
        /*4. Make the request */
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error!)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No Data was returned by the request!")
                return
            }
            
            //I don't want to convert the data to JSON when fetching an image
            if apiHost == Constants.Flickr.APIHost {
                self.convertDataWithCompletionHandler(data,        completionHandlerForConvertData: completionHandlerForGET)
            } else {
                completionHandlerForGET(data as AnyObject, nil)
            }
        }
        
        /*7. Start the request */
        task.resume()
        
        return task
    }
    
    //MARK : Helpers
    
    // subsitute the key for the value that is contained within the path
    func substitueKeyInPath(_ path: String, key: String, value: String) -> String? {
        if path.range(of: "{\(key)}") != nil {
            return path.replacingOccurrences(of: "{\(key)}", with: value)
        } else {
            return nil
        }
    }
    
    // given the JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain:"convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        completionHandlerForConvertData(parsedResult, nil)
    }
    
    // create a URL From Parameters
    private func flickrURLFromParameters(_ parameters: [String:AnyObject], _ apiHost: String, _ apiPath: String) -> URL {
        
        // in case needed withPathExtension: String? = nil
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = apiHost
        components.path = apiPath
        //+ (withPathExtension ?? "") - in case we'll use method.
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> VirtualTouristClient {
        struct Singleton {
            static var sharedInstance = VirtualTouristClient()
        }
        return Singleton.sharedInstance
    }
    
}


