//
//  PeripheralTableViewCell.swift
//  Bluefruit Connect
//
//  Created by Antonio García on 29/01/16.
//  Copyright © 2016 Adafruit. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralTableViewCell: UITableViewCell {
    
    // UI
    @IBOutlet weak var baseStackView: UIStackView!
    @IBOutlet weak var rssiImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var connectButton: StyledConnectButton!
    @IBOutlet weak var disconnectButton: StyledConnectButton!
    @IBOutlet weak var disconnectButtonWidthConstraint: NSLayoutConstraint!
//
    @IBOutlet weak var detailBaseStackView: UIStackView!
//    @IBOutlet weak var servicesStackView: UIStackView!
//    @IBOutlet weak var servicesOverflowStackView: UIStackView!
//    @IBOutlet weak var servicesSolicitedStackView: UIStackView!
//    @IBOutlet weak var txPowerLevelValueLabel: UILabel!
    @IBOutlet weak var localNameValueLabel: UILabel!
//    @IBOutlet weak var manufacturerValueLabel: UILabel!
//    @IBOutlet weak var connectableValueLabel: UILabel!
    
    // Params
    var onConnect: (() -> Void)?
    var onDisconnect: (() -> Void)?
    
    // Data
    fileprivate var cachedExtendedViewPeripheralId: UUID?
    
    // MARK: - View Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
//        manufacturerValueLabel.text = nil
//        txPowerLevelValueLabel.text = nil
        
        let rightMarginInset = contentView.bounds.size.width - baseStackView.frame.maxX     // reposition button because it is outside the hierchy
        //DLog("right margin: \(rightMarginInset)")
        connectButton.titleEdgeInsets.right += rightMarginInset
        disconnectButton.titleEdgeInsets.right += rightMarginInset
        
        let localizationManager = LocalizationManager.shared
        connectButton.setTitle(localizationManager.localizedString("scanresult_connect"), for: .normal)
        disconnectButton.setTitle(localizationManager.localizedString("scanresult_disconnect"), for: .normal)

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Remove cached data
        cachedExtendedViewPeripheralId = nil
    }
    
    // MARK: - Actions
    @IBAction func onClickDisconnect(_ sender: AnyObject) {
        onDisconnect?()
    }
    
    @IBAction func onClickConnect(_ sender: AnyObject) {
        DLog("CONNECT BOII")
        onConnect?()
    }
    
    // MARK: - UI
    func showDisconnectButton(show: Bool) {
        disconnectButtonWidthConstraint.constant = show ? 24: 0
    }
    
    func setupPeripheralExtendedView(peripheral: BlePeripheral) {
        guard cachedExtendedViewPeripheralId != peripheral.identifier else { return }       // If data is already filled, skip
        
        cachedExtendedViewPeripheralId = peripheral.identifier
        var currentIndex = 0
        
        // Local Name
        var isLocalNameAvailable = false
        if let localName = peripheral.advertisement.localName {
            localNameValueLabel.text = localName
            isLocalNameAvailable = true
        }
        detailBaseStackView.arrangedSubviews[currentIndex].isHidden = !isLocalNameAvailable
        currentIndex = currentIndex+1
    }
    
    private func addServiceNames(stackView: UIStackView, services: [CBUUID]) {
        let styledLabel = stackView.arrangedSubviews.first! as! UILabel
        styledLabel.isHidden = true     // The first view is only to define style in InterfaceBuilder. Hide it
        
        // Clear current subviews
        for arrangedSubview in stackView.arrangedSubviews {
            if arrangedSubview != stackView.arrangedSubviews.first {
                arrangedSubview.removeFromSuperview()
                stackView.removeArrangedSubview(arrangedSubview)
            }
        }
        
        // Add services as subviews
        for serviceCBUUID in services {
            let label = UILabel()
            var identifier = serviceCBUUID.uuidString
            if let name = BleUUIDNames.shared.nameForUUID(identifier) {
                identifier = name
            }
            label.text = identifier
            label.font = styledLabel.font
            label.minimumScaleFactor = styledLabel.minimumScaleFactor
            label.adjustsFontSizeToFitWidth = styledLabel.adjustsFontSizeToFitWidth
            stackView.addArrangedSubview(label)
        }
    }
}
