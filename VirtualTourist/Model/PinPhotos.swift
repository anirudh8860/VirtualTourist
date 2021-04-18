//
//  PinPhotos.swift
//  VirtualTourist
//
//  Created by Anirudh Sohil on 03/04/21.
//

import Foundation

struct PinPhotos: Codable {
    let page, pages, perpage: Int
    let total: String
    let photo: [PhotoStruct]
}
