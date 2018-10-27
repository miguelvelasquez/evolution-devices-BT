//
//  ControllerModuleManager.swift
//  Bluefruit Connect
//
//  Created by Antonio García on 12/02/16.
//  Copyright © 2016 Adafruit. All rights reserved.
//

import Foundation
import CoreLocation
import MSWeakTimer

// TODO: add support for OSX
#if os(OSX)
#else
import CoreMotion
#endif

protocol ControllerModuleManagerDelegate: class {
    func onControllerUartIsReady(error: Error?)
    func onUarRX()
}

class ControllerModuleManager: NSObject {
    
    enum ControllerType: Int {
        case accelerometer
        case gyroscope
    }
    static let numSensors = 5
    
    static private let prefixes = ["!Q", "!A", "!G", "!M", "!L"]     // same order that ControllerType
    
    // Params
    weak var delegate: ControllerModuleManagerDelegate?
    var isUartRxCacheEnabled = false {
        didSet {
            if isUartRxCacheEnabled {
                uartManager.delegate = self
            } else {
                uartManager.delegate = nil
            }
        }
    }
    
    // Data
    fileprivate var isSensorEnabled = [Bool](repeating: false, count: ControllerModuleManager.numSensors)
    
    #if os(OSX)
    #else
    private let coreMotionManager = CMMotionManager()
    #endif
    private let locationManager = CLLocationManager()
    fileprivate var lastKnownLocation: CLLocation?
    
    fileprivate var blePeripheral: BlePeripheral
    private var pollTimer: MSWeakTimer?
    private var timerHandler: (() -> Void)?
    
    fileprivate let uartManager: UartDataManager
    fileprivate var textCachedBuffer: String = ""
    
    private var pollInterval: TimeInterval = 1        // in seconds
    
    init(blePeripheral: BlePeripheral, delegate: ControllerModuleManagerDelegate) {
        self.blePeripheral = blePeripheral
        self.delegate = delegate
        uartManager = UartDataManager(delegate: nil, isRxCacheEnabled: false)
        super.init()
    }
    
    deinit {
        locationManager.delegate = nil
    }
    
    
    // MARK: - Send Data
    func sendCrcData(_ data: Data) {
        var crcData = data
        crcData.appendCrc()
        
        uartManager.send(blePeripheral: blePeripheral, data: crcData)
    }
    
    // MARK: - Uart Data Cache
    func uartTextBuffer() -> String {
        return textCachedBuffer
    }
    
    func uartRxCacheReset() {
        uartManager.clearRxCache(peripheralIdentifier: blePeripheral.identifier)
        textCachedBuffer.removeAll()
    }

}


// MARK: - UartDataManagerDelegate
extension ControllerModuleManager: UartDataManagerDelegate {
    func onUartRx(data: Data, peripheralIdentifier: UUID) {
        if let dataString = stringFromData(data, useHexMode: false) {
            //DLog("rx: \(dataString)")
            textCachedBuffer.append(dataString)
            DispatchQueue.main.async {
                self.delegate?.onUarRX()
            }
        }
        uartManager.removeRxCacheFirst(n: data.count, peripheralIdentifier: peripheralIdentifier)
    }
}
