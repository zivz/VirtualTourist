//
//  GCDBlackBox.swift
//  VirtualTourist
//
//  Created by Ziv Zalzstein on 13/08/2018.
//  Copyright © 2018 Ziv. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
