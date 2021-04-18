//
//  PhotoItem.swift
//  VirtualTourist
//
//  Created by Anirudh Sohil on 03/04/21.
//

import UIKit
import CoreData

class PhotoItem: UICollectionViewCell {
   
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var checkmark: UIImageView!
    static let reuseIdentifier = "PhotoItem"
    
    func setPhotoImageView(imageView: UIImage, sizeFit: Bool) {
        photoImageView.image = imageView
        checkmark.isHidden = true
        if sizeFit == true {
            photoImageView.sizeToFit()
        }
    }
}
