//
//  PeripheralList.swift
//  Evolution Devices BT
//
//  Created by Miguel A Velasquez on 8/3/18.
//  Copyright © 2018 Miguel A Velasquez. All rights reserved.
//

import Foundation

class PeripheralList {
    // Constants
    static let kMinRssiValue = 0
    static let kMaxRssiValue = 100
    static let kDefaultRssiValue = PeripheralList.kMaxRssiValue
    
    var isOnlyUartEnabled = true
    var isUnnamedEnabled = false

    
    private var isFilterDirty = true
    
    private var peripherals = [BlePeripheral]()
    private var cachedFilteredPeripherals: [BlePeripheral] = []
    
    
    func setDefaultFilters() {
        isUnnamedEnabled = false
        isOnlyUartEnabled = true
        Preferences.scanFilterIsUnnamedEnabled = isUnnamedEnabled
        Preferences.scanFilterIsOnlyWithUartEnabled = isOnlyUartEnabled
    }
    

    func numPeripheralsFiltered() -> Int {
        let filteredCount = filteredPeripherals(forceUpdate: false).count
        return BleManager.shared.peripherals().count - filteredCount
    }
    
    func filteredPeripherals(forceUpdate: Bool) -> [BlePeripheral] {
        if isFilterDirty || forceUpdate {
            cachedFilteredPeripherals = calculateFilteredPeripherals()
            isFilterDirty = false
        }
        return cachedFilteredPeripherals
    }
    
    func clear() {
        peripherals = [BlePeripheral]()
    }
    
    
    private func calculateFilteredPeripherals() -> [BlePeripheral] {
        let kUnnamedSortingString = "~~~"       // Unnamed devices go to the bottom
        var peripherals = BleManager.shared.peripherals().sorted(by: {$0.name ?? kUnnamedSortingString < $1.name ?? kUnnamedSortingString})
        
        // Apply filters
        if isOnlyUartEnabled {
            peripherals = peripherals.filter({$0.isUartAdvertised()})
        }
        
        if !isUnnamedEnabled {
            peripherals = peripherals.filter({$0.name != nil})
        }
        
        return peripherals
    }
    
    
    func filtersDescription() -> String? {
        var filtersTitle: String?
        
        let localizationManager = LocalizationManager.shared
        
        if !isUnnamedEnabled {
            let namedString = localizationManager.localizedString("scanner_filter_unnamed_description")
            if filtersTitle != nil && !filtersTitle!.isEmpty {
                filtersTitle!.append(", \(namedString)")
            } else {
                filtersTitle = namedString
            }
        }
        
        if isOnlyUartEnabled {
            let uartString = localizationManager.localizedString("scanner_filter_uart_description")
            if filtersTitle != nil && !filtersTitle!.isEmpty {
                filtersTitle!.append(", \(uartString)")
            } else {
                filtersTitle = uartString
            }
        }
        
        return filtersTitle
    }
}
