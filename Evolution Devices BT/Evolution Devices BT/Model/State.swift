//
//  State.swift
//  Evolution Devices BT
//
//  Created by Miguel A Velasquez on 10/28/18.
//  Copyright © 2018 Miguel A Velasquez. All rights reserved.
//

import Foundation

struct State {
    var connected: Bool
    var leftConnected: Bool
    var rightConnected: Bool
    var device: BlePeripheral?
    var leftDevice: BlePeripheral?
    var rightDevice: BlePeripheral?
    
    func isConnected() -> Bool {
        return self.connected
    }
    
    func isLeftConnected() -> Bool {
        return self.leftConnected
    }
    
    func isRightConnected() -> Bool {
        return self.rightConnected
    }
    
    mutating func setConnected(peripheral: BlePeripheral) {
        self.connected = true
        self.device = peripheral
    }
    
    mutating func setLeftConnected(peripheral: BlePeripheral) {
        self.leftConnected = true
        self.leftDevice = peripheral
    }
    
    mutating func setRightConnected(peripheral: BlePeripheral) {
        self.rightConnected = true
        self.rightDevice = peripheral
    }
    
    mutating func setDisconnected(peripheral: BlePeripheral) {
        self.connected = false
        self.device = nil
    }
    
    mutating func setLeftDisconnected(peripheral: BlePeripheral) {
        self.leftConnected = false
        self.leftDevice = nil
    }
    
    mutating func setRightDisconnected(peripheral: BlePeripheral) {
        self.rightConnected = false
        self.rightDevice = nil
    }
}

