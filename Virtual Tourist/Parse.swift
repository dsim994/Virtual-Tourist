//
//  Parse.swift
//  Virtual Tourist
//
//  Created by Dylan Simerly on 4/18/17.
//  Copyright © 2017 dylansimerly. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class Parse {

    static func toNSData(requestBody : [String:AnyObject]? = nil) -> NSData {
        var jsonData:NSData! = nil
        do {
            jsonData = try JSONSerialization.data(withJSONObject: requestBody!, options: JSONSerialization.WritingOptions.prettyPrinted) as NSData?
        } catch let error as NSError {
            print(error)
        }
        parseJSONToAnyObject(response: jsonData) { (result, error) in
        }
        return jsonData
    }
    
    static func parseJSONToAnyObject(response: NSData, completionHandler: (_ result:AnyObject?, _ error:NSError?)-> Void) {
        var parsedResponse:Any! = nil
        do {
            parsedResponse = try JSONSerialization.jsonObject(with: response as Data, options: JSONSerialization.ReadingOptions.allowFragments)
            completionHandler(parsedResponse as AnyObject, nil)
        } catch let error as NSError {
            completionHandler(nil, error)
        }
    }
    
    static func toMKAnnotation(_ from: Pin) -> MKPointAnnotation
    {
        let toAnnotation = MKPointAnnotation()
        toAnnotation.coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(from.latitude), CLLocationDegrees(from.longitude))
        return toAnnotation
    }
    
    static func toPin (_ from:MKAnnotation, _ to:Pin) -> Pin {
        to.latitude = from.coordinate.latitude
        to.longitude = from.coordinate.longitude
        return to
    }
}






