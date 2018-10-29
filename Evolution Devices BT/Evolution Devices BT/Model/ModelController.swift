//
//  ModelController.swift
//  Evolution Devices BT
//
//  Created by Miguel A Velasquez on 10/27/18.
//  Copyright © 2018 Miguel A Velasquez. All rights reserved.
//

import Foundation

class ModelController {
    var appState = State(
        connected: false,
        leftConnected: false,
        rightConnected: false,
        device: nil,
        leftDevice: nil,
        rightDevice: nil
    )
}
