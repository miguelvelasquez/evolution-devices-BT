//
//  DeviceTableViewCell.swift
//  Evolution Devices BT
//
//  Created by Miguel A Velasquez on 10/23/18.
//  Copyright © 2018 Miguel A Velasquez. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

class DeviceTableViewCell: UITableViewCell {
    
    // UI
    @IBOutlet weak var rssiImageView: UIImageView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBAction func buttonPressed(_ sender: UIButton) {
//        button.borderColor = UIColor(#2ecc71)
//        button.textColor = UIColor(named: "white")
//        button.backgroundColor = UIColor(hex: <#T##UInt#>)
        onClick?()
    }
    
    // Params
    var onClick: (() -> Void)?
    var connected: Bool?
    
    // Data
    fileprivate var cachedExtendedViewPeripheralId: UUID?
    
    // MARK: - View Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()

        let localizationManager = LocalizationManager.shared
        button.setTitle(localizationManager.localizedString("scanresult_connect"), for: .normal)
//        disconnectButton.setTitle(localizationManager.localizedString("scanresult_disconnect"), for: .normal)
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Remove cached data
        cachedExtendedViewPeripheralId = nil
    }
    
    func setupPeripheralExtendedView(peripheral: BlePeripheral) {
        guard cachedExtendedViewPeripheralId != peripheral.identifier else { return }       // If data is already filled, skip
        
        cachedExtendedViewPeripheralId = peripheral.identifier
        var currentIndex = 0
        
        // Local Name
        var localNameText = "EvoDev"
        if let localName = peripheral.advertisement.localName {
            localNameText = localName
        }
        deviceNameLabel.text = localNameText
        currentIndex = currentIndex + 1
        
    }
}
