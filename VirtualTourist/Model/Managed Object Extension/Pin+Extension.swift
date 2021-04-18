//
//  Pin+Extension.swift
//  VirtualTourist
//
//  Created by Anirudh Sohil on 03/04/21.
//

import Foundation
import CoreData

extension Pin {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
