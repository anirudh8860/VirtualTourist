//
//  AnnotationPin.swift
//  VirtualTourist
//
//  Created by Anirudh Sohil on 03/04/21.
//

import Foundation
import MapKit


class AnnotationPin: MKPointAnnotation {
    var pin: Pin

    init(pin: Pin){
        self.pin = pin
        super.init()
        self.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
    }
}
