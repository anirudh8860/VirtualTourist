//
//  FlickrResponse.swift
//  VirtualTourist
//
//  Created by Anirudh Sohil on 03/04/21.
//

import Foundation

struct FlickrResponse: Codable {
    let photos: PinPhotos
    let stat: String
}
