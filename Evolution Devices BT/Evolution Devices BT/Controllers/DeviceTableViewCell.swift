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
        button.borderColor = UIColor(hexString: "#1793FE")
        button.setTitleColor(UIColor(hexString: "#ffffff"), for: .normal)
        button.backgroundColor = UIColor(hexString: "#1793FE")
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

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
