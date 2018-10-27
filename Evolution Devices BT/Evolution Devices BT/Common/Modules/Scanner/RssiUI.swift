//
//  RssiUI.swift
//  Evolution Devices BT
//
//  Created by Miguel A Velasquez on 8/3/18.
//  Copyright © 2018 Miguel A Velasquez. All rights reserved.
//


#if os(OSX)
import AppKit
public typealias Image = NSImage
#else
import UIKit
public typealias Image = UIImage

#endif

class RssiUI {
    static func signalImage(for rssi: Int?) -> Image {
        
        let rssiValue = rssi ?? 127
        
        var index: Int
        
        if rssiValue == 127 {     // value of 127 reserved for RSSI not available
            index = 0
        } else if rssiValue <= -84 {
            index = 0
        } else if rssiValue <= -72 {
            index = 1
        } else if rssiValue <= -60 {
            index = 2
        } else if rssiValue <= -48 {
            index = 3
        } else {
            index = 4
        }
        
        return Image(named: "signalstrength\(index)")!
    }
}

