//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Dylan Simerly on 4/18/17.
//  Copyright © 2017 dylansimerly. All rights reserved.
//

import Foundation
import CoreData

class FlickrClient {
    
    var session = URLSession.shared
    static let sharedInstance = FlickrClient()
    
    func getMethodURL(using parameters: [String:AnyObject]) -> URL {
        var components = URLComponents()
        components.scheme = Constants.APIScheme
        components.host = Constants.APIHost
        components.path = Constants.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }
    
    private func makeBoundaryBoxString(lat latitude: Double,  long longitude: Double) -> String {
        let minimumLon = max(longitude - Constants.BBoxLimits.Width, Constants.BBoxLimits.LonRange.0)
        let maximumLon = min(longitude + Constants.BBoxLimits.Width, Constants.BBoxLimits.LonRange.0)

        let minimumLat = max(latitude - Constants.BBoxLimits.Height, Constants.BBoxLimits.LatRange.0)
        let maximumLat = min(latitude + Constants.BBoxLimits.Height, Constants.BBoxLimits.LatRange.0)

        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    func makeTaskCall (req request:URLRequest , completionHandlerForTaskCall : @escaping (_ result : AnyObject? , _ error: NSError?) -> Void) {
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: request) { (data, response, error) in
       
            if error == nil{
                
                Parse.parseJSONToAnyObject(response: data! as NSData, completionHandler: completionHandlerForTaskCall)
            } else {
                
                completionHandlerForTaskCall(nil,error! as NSError?)
            }
        }
        task.resume()
    }
    
    func searchPhotos(latitude: Double, longitude: Double, completionHandlerForSearchPhotos: @escaping (_ photoURLS: [String]?, _ error: NSError?) -> Void) {
        
        let methodParameters: [String: AnyObject] =
            [
                Request.ParamKey.Method:Request.ParamVal.Method as AnyObject,
                Request.ParamKey.APIKey:Request.ParamVal.APIKey as AnyObject,
                Request.ParamKey.BoundingBox:self.makeBoundaryBoxString(lat: latitude, long: longitude) as AnyObject,
                Request.ParamKey.Extras:Request.ParamVal.MediumURL as AnyObject,
                Request.ParamKey.Format:Request.ParamVal.Format as AnyObject,
                Request.ParamKey.NoJSONCallback:Request.ParamVal.DisableJSONCallback as AnyObject,
                Request.ParamKey.PerPage:Request.ParamVal.PhotosPerPage as AnyObject,
                Request.ParamKey.Page:"\(arc4random_uniform(200))" as AnyObject
        ]
        
        let requestURL = URLRequest(url: getMethodURL(using: methodParameters));
        print(requestURL)
        makeTaskCall(req: requestURL){ (data, error) in
            
            if error == nil {
                guard let stat = data?[Response.Key.Status] as? String, stat == "ok" else {
                    print("Flickr API returned an error. See error code and message in \(String(describing: data))")
                    completionHandlerForSearchPhotos(nil, NSError(domain: Error.Domain.SearchMethod, code: 5001, userInfo: [NSLocalizedDescriptionKey:Error.Message.Error_Occurred]))
                    return
                }
                
                if let photosDictionary = data?[Response.Key.PhotosDictionary] as? [String:AnyObject],
                    let photosArray = photosDictionary[Response.Key.Photo] as? [[String:AnyObject]] {
                    var photoURLS = [String]()
                    
                    for photo in photosArray {
                        if let photoURL = photo[Response.Key.MediumURL] as? String {
                            photoURLS.append(photoURL)
                        }
                    }
                    completionHandlerForSearchPhotos(photoURLS, nil)
                } else {
                    completionHandlerForSearchPhotos(nil, NSError(domain: Error.Domain.SearchMethod, code: 5002, userInfo: [NSLocalizedDescriptionKey: Error.Message.Invalid_Response]))
                }
            } else {
                completionHandlerForSearchPhotos(nil,error)
            }
        }
    }
    
    func downloadPhotos(photoURL:String, completionHandlerForDownloadPhotos: @escaping (_ image: NSData?, _ error: NSError?) -> Void) {
        
        let url = NSURL(string: photoURL)
        let request = URLRequest(url: url! as URL)
        
        let task = session.dataTask(with: request){ data, response, error in
            
            guard let data = data else{
                completionHandlerForDownloadPhotos(nil, NSError(domain: Error.Domain.DownloadMethod, code: 6001, userInfo: [NSLocalizedDescriptionKey: Error.Message.Download_Not_Possible]))
                return
            }
            completionHandlerForDownloadPhotos(data as NSData, nil)
        }
        task.resume()
    }
}

extension FlickrClient {
    
    struct Constants {
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest/"
        static let PhotoLimit = 20
        
        struct BBoxLimits{
            static let Width = 1.0
            static let Height = 1.0
            static let LatRange = (-90.0, 90.0)
            static let LonRange = (-180.0, 180.0)
        }
    }
    
    struct Request {
        
        struct ParamKey {
            static let Method = "method"
            static let APIKey = "api_key"
            static let Extras = "extras"
            static let BoundingBox = "bbox"
            static let Format = "format"
            static let NoJSONCallback = "nojsoncallback"
            static let Page = "page"
            static let PerPage = "per_page"
            static let Longitude = "lon"
            static let Latitude = "lat"
        }
        
        struct ParamVal {
            static let Method = "flickr.photos.getRecent"
            static let APIKey = "3ebf81db20b42c27ede4d40b32be2374"
            static let MediumURL = "url_m"
            static let Format = "json"
            static let DisableJSONCallback = "1"
            static let PhotosPerPage = "10"
        }
    }
    
    struct Response {
        struct Key {
            static let Status = "stat"
            static let PhotosDictionary = "photos"
            static let Photo = "photo"
            static let MediumURL = "url_m"
            static let Title = "title"
            static let Pages = "pages"
            static let Total = "total"
        }
    }
    
    struct Error {
        
        struct Domain {
            static let SearchMethod="VT.SEARCH_PHOTOS"
            static let DownloadMethod="VT.DOWNLOAD_PHOTOS"
        }
        
        struct Message {
            static let Error_Occurred = "Error occurrred in API response."
            static let Invalid_Response = "API response is not parsable for necessary information."
            static let Download_Not_Possible = "Unable to download pic."
        }
    }
}






