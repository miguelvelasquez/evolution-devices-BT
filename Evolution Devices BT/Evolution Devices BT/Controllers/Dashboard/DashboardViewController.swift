//
//  DashboardViewController.swift
//  Evolution Devices BT
//
//  Created by Miguel A Velasquez on 10/20/18.
//  Copyright © 2018 Miguel A Velasquez. All rights reserved.
//

import Foundation
import PopupDialog
import UIKit
import MSWeakTimer

class DashboardViewController: UIViewController {
    
    // Config
    fileprivate static let kRssiRefreshInterval: TimeInterval = 0.3
    
    // UI
    @IBOutlet weak var buttonImageView: UIImageView!
    @IBOutlet weak var buttonText: UILabel!

    @IBOutlet weak var collectionView: UICollectionView!
    
    // Parameters
    enum ConnectionMode {
        case singlePeripheral
        case multiplePeripherals
    }
    
    var connectionMode = ConnectionMode.singlePeripheral
    weak var blePeripheral: BlePeripheral?
    
    fileprivate var hasUart = false
    fileprivate var hasDfu = false
    fileprivate var rssiRefreshTimer: MSWeakTimer?
    
    fileprivate var batteryLevel: Int?
    
    @IBAction func tappedConnectivityButton(_ sender: Any) {
        showStandardDialog()

    }
    
    var modelController: ModelController!
    
    
    /*!
     Displays the default dialog without image, just as the system dialog
     */
    func showStandardDialog(animated: Bool = true) {
        // Prepare the popup
        let scanVC = ScanViewController(nibName: "ScanViewController", bundle: nil)
        scanVC.modelController = self.modelController

        
        // Create the dialog
        let popup = PopupDialog(viewController: scanVC,
                                buttonAlignment: .horizontal,
                                transitionStyle: .bounceUp,
                                tapGestureDismissal: true,
                                panGestureDismissal: true,
                                hideStatusBar: true) {
                                    print("Completed")
        }
        
        // Create first button
        let buttonOne = CancelButton(title: "CLOSE") {
        }
        
        // Create second button
        let buttonTwo = DefaultButton(title: "SCAN", dismissOnTap: false) {
            scanVC.scanPeripherals()
        }
        
        // Add buttons to dialog
        popup.addButtons([buttonOne, buttonTwo])
        
        // Present dialog
        self.present(popup, animated: animated, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.register(DashboardCell.self, forCellWithReuseIdentifier: "dashCell")

        if modelController.appState.isConnected() {
            showConnected()
        } else {
            showDisconnected()
        }
        
        // Init for iPhone
        if let blePeripheral = blePeripheral {
            hasUart = blePeripheral.hasUart()
            hasDfu = blePeripheral.peripheral.services?.first(where: {$0.uuid == FirmwareUpdater.kDfuServiceUUID}) != nil
            setupBatteryUI(blePeripheral: blePeripheral)
        }
    }
    
    fileprivate func setupBatteryUI(blePeripheral: BlePeripheral) {
        guard blePeripheral.hasBattery() else { return }
        
        blePeripheral.startReadingBatteryLevel(handler: { [weak self] batteryLevel in
            guard let context = self else { return }
            
            context.batteryLevel = batteryLevel
            
            DispatchQueue.main.async {
                // Update section
//                context.baseTableView.reloadSections([TableSection.device.rawValue], with: .none)
            }
        })
    }
    
    fileprivate func stopBatterUI(blePeripheral: BlePeripheral) {
        guard blePeripheral.hasBattery() else { return }
        
        blePeripheral.stopReadingBatteryLevel()
    }
    
    func showConnected() {
        buttonImageView.image = UIImage(named: "device_connection")
        buttonText.text = "Connected"
//        self.plotterImage.alpha = 0.8
//        self.controllerImage.alpha = 0.8
    }
    
    func showDisconnected() {
        buttonImageView.image = UIImage(named: "device_unconnected")
        buttonText.text = "Not Connected"
//        self.plotterImage.alpha = 0.5
//        self.controllerImage.alpha = 0.5
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}


