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
    
    @IBOutlet weak var buttonImageView: UIImageView!
    @IBOutlet weak var buttonText: UILabel!
    
    @IBOutlet weak var controllerImage: UIImageView!
    @IBOutlet weak var plotterImage: UIImageView!
    
    @IBAction func pressedControllerButton(_ sender: UITapGestureRecognizer) {
        DLog("pressed controller")
        if let controllerViewController = self.storyboard?.instantiateViewController(withIdentifier: "ControllerModeViewController") as? ControllerModeViewController {
            controllerViewController.blePeripheral = blePeripheral
            if blePeripheral == nil {
                DLog("It is nil")
            }
            show(controllerViewController, sender: self)
        }
    }
    
    
    @IBAction func pressedPlotterButton(_ sender: UITapGestureRecognizer) {
        DLog("pressed plotter")
        if let plotterViewController = self.storyboard?.instantiateViewController(withIdentifier: "PlotterModeViewController") as? PlotterModeViewController {
            plotterViewController.blePeripheral = blePeripheral
            show(plotterViewController, sender: self)
        }
    }
    
    @IBAction func pressedConnectivityButton(_ sender: UITapGestureRecognizer) {
        showStandardDialog()
    }
    
    // Config
    fileprivate static let kRssiRefreshInterval: TimeInterval = 0.3
    
    var modelController: ModelController!
    
    fileprivate var hasUart = true
    fileprivate var rssiRefreshTimer: MSWeakTimer?
    
    fileprivate var batteryLevel: Int?
    weak var blePeripheral: BlePeripheral?

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
        if modelController.appState.isConnected() {
            showConnected()
        } else {
            showDisconnected()
        }
        
        if let blePeripheral = blePeripheral {
            hasUart = blePeripheral.hasUart()
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Schedule Rssi timer
        rssiRefreshTimer = MSWeakTimer.scheduledTimer(withTimeInterval: DashboardViewController.kRssiRefreshInterval, target: self, selector: #selector(rssiRefreshFired), userInfo: nil, repeats: true, dispatchQueue: .global(qos: .background))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Disable Rssi timer
        rssiRefreshTimer?.invalidate()
        rssiRefreshTimer = nil
    }
    
    // MARK: - UI
    @objc private func rssiRefreshFired() {
        blePeripheral?.readRssi()
    }
    
    
    func showConnected() {
        buttonImageView.image = UIImage(named: "device_connection")
        buttonText.text = "Connected"
        self.plotterImage.alpha = 0.8
        self.controllerImage.alpha = 0.8
    }
    
    func showDisconnected() {
        buttonImageView.image = UIImage(named: "device_unconnected")
        buttonText.text = "Not Connected"
        self.plotterImage.alpha = 0.5
        self.controllerImage.alpha = 0.5
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - BLE Notifications
    private weak var willConnectToPeripheralObserver: NSObjectProtocol?
    private weak var willDisconnectFromPeripheralObserver: NSObjectProtocol?
    private weak var peripheralDidUpdateRssiObserver: NSObjectProtocol?
    private weak var didDisconnectFromPeripheralObserver: NSObjectProtocol?
    
    private func registerNotifications(enabled: Bool) {
        let notificationCenter = NotificationCenter.default
        
        if enabled {
            willConnectToPeripheralObserver = notificationCenter.addObserver(forName: .willConnectToPeripheral, object: nil, queue: .main, using: {[weak self] notification in self?.willConnectToPeripheral(notification: notification)})
            willDisconnectFromPeripheralObserver = notificationCenter.addObserver(forName: .willDisconnectFromPeripheral, object: nil, queue: .main, using: {[weak self] notification in self?.willDisconnectFromPeripheral(notification: notification)})
            peripheralDidUpdateRssiObserver = notificationCenter.addObserver(forName: .peripheralDidUpdateRssi, object: nil, queue: .main, using: {[weak self] notification in self?.peripheralDidUpdateRssi(notification: notification)})
            didDisconnectFromPeripheralObserver = notificationCenter.addObserver(forName: .didDisconnectFromPeripheral, object: nil, queue: .main, using: {[weak self] notification in self?.didDisconnectFromPeripheral(notification: notification)})
            
        } else {
            if let willConnectToPeripheralObserver = willConnectToPeripheralObserver {notificationCenter.removeObserver(willConnectToPeripheralObserver)}
            if let willDisconnectFromPeripheralObserver = willDisconnectFromPeripheralObserver {notificationCenter.removeObserver(willDisconnectFromPeripheralObserver)}
            if let peripheralDidUpdateRssiObserver = peripheralDidUpdateRssiObserver {notificationCenter.removeObserver(peripheralDidUpdateRssiObserver)}
            if let didDisconnectFromPeripheralObserver = didDisconnectFromPeripheralObserver {notificationCenter.removeObserver(didDisconnectFromPeripheralObserver)}
        }
    }
    
    fileprivate func willConnectToPeripheral(notification: Notification) {
        guard let identifier = notification.userInfo?[BleManager.NotificationUserInfoKey.uuid.rawValue] as? UUID, identifier == blePeripheral?.identifier else { return }
        

    }
    
    fileprivate func willDisconnectFromPeripheral(notification: Notification) {
        guard let identifier = notification.userInfo?[BleManager.NotificationUserInfoKey.uuid.rawValue] as? UUID, identifier == blePeripheral?.identifier else { return }
        
        DLog("detail: peripheral willDisconnect")
        let isFullScreen = UIScreen.main.traitCollection.horizontalSizeClass == .compact
        if isFullScreen {       // executed when bluetooth is stopped
            // Back to peripheral list
            goBackToPeripheralList()
        } else {
            blePeripheral = nil
        }
    }
    
    fileprivate func peripheralDidUpdateRssi(notification: Notification) {
        guard let identifier = notification.userInfo?[BleManager.NotificationUserInfoKey.uuid.rawValue] as? UUID, identifier == blePeripheral?.identifier else { return }
    }
    
    private func didDisconnectFromPeripheral(notification: Notification) {
        guard let identifier = notification.userInfo?[BleManager.NotificationUserInfoKey.uuid.rawValue] as? UUID, identifier == blePeripheral?.identifier else { return }
        
        // Disable Rssi timer
        rssiRefreshTimer?.invalidate()
        rssiRefreshTimer = nil
    }
    
    private func goBackToPeripheralList() {
        // Back to peripheral list
        navigationController?.popToRootViewController(animated: true)
    }
    
}
