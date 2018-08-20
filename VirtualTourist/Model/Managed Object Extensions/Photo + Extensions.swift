//
//  Photo + Extensions.swift
//  VirtualTourist
//
//  Created by Ziv Zalzstein on 19/08/2018.
//  Copyright © 2018 Ziv. All rights reserved.
//

import Foundation
import CoreData

extension Photo {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
