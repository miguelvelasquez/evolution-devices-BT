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


protocol DashboardViewControllerDelegate: class {
    func onSendControllerPadButtonStatus(tag: Int, isPressed: Bool)
}

class DashboardViewController: UIViewController {
    
    fileprivate static let kPollInterval = 0.25

    
    @IBOutlet weak var buttonImageView: UIImageView!
    @IBOutlet weak var buttonText: UILabel!
    
    @IBOutlet weak var controllerImage: UIImageView!
    @IBOutlet weak var plotterImage: UIImageView!
    
    @IBAction func pressedControllerButton(_ sender: UITapGestureRecognizer) {
        DLog("pressed controller")
        if checkConnected() {
            if let controllerViewController = self.storyboard?.instantiateViewController(withIdentifier: "ControllerModeViewController") as? ControllerModeViewController {
                controllerViewController.modelController = self.modelController
//                sendTouchEvent(tag: 100, isPressed: false)
                show(controllerViewController, sender: self)
            }
        }
    }
    
    
    @IBAction func pressedPlotterButton(_ sender: UITapGestureRecognizer) {
        DLog("pressed plotter")
        if checkConnected() {
            if let plotterViewController = self.storyboard?.instantiateViewController(withIdentifier: "PlotterModeViewController") as? PlotterModeViewController {
                plotterViewController.blePeripheral = blePeripheral
                plotterViewController.modelController = self.modelController
//                sendTouchEvent(tag: 101, isPressed: false)
                show(plotterViewController, sender: self)
            }
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
    
    // Data
    weak var delegate: ControllerModeViewControllerDelegate?
    fileprivate var controllerData: ControllerModuleManager!
    fileprivate var contentItems = [Int]()

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
            self.updateUI()
        }
        
        // Create second button
        let buttonTwo = DefaultButton(title: "SCAN", dismissOnTap: false) {
            scanVC.scanPeripherals()
            self.updateUI()
        }
        
        // Add buttons to dialog
        popup.addButtons([buttonOne, buttonTwo])
        
        // Present dialog
        self.present(popup, animated: animated, completion: nil)
    }
    
    func showNotConnectedDialog(animated: Bool = true) {
        // Prepare the popup
        let title = "Device Not Connected"
        let message = "You must connect to the device to access this feature"
        // Create the dialog
        let popup = PopupDialog(title: title, message: message)
    
        // Create first button
        let buttonOne = CancelButton(title: "Close") {
        }
        
        // Add buttons to dialog
        popup.addButtons([buttonOne])
        
        // Present dialog
        self.present(popup, animated: animated, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
//        if let blePeripheral = modelController.appState.device {
//            hasUart = blePeripheral.hasUart()
//            self.controllerData = ControllerModuleManager(blePeripheral: blePeripheral, delegate: self as! ControllerModuleManagerDelegate)
//        }
    
        
    }
    
    func setupUART() {
        if modelController.appState.isConnected() {
            self.controllerData = ControllerModuleManager(blePeripheral: blePeripheral!, delegate: self as! ControllerModuleManagerDelegate)
        }
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        if let blePeripheral = modelController.appState.device {
//            hasUart = blePeripheral.hasUart()
//            controllerData = ControllerModuleManager(blePeripheral: blePeripheral, delegate: self as! ControllerModuleManagerDelegate)
//        }
        
        // UNCOMMENT when I know how to fix
//        if modelController.appState.isConnected() {
//            if isMovingToParent {       // To keep streaming data when pushing a child view
//                controllerData.start(pollInterval: DashboardViewController.kPollInterval) { [unowned self] in
//                }
//
//            } else {
//                // Disable cache if coming back from Control Pad
//                controllerData.isUartRxCacheEnabled = false
//            }
//        }
        
        // Schedule Rssi timer
        rssiRefreshTimer = MSWeakTimer.scheduledTimer(withTimeInterval: DashboardViewController.kRssiRefreshInterval, target: self, selector: #selector(rssiRefreshFired), userInfo: nil, repeats: true, dispatchQueue: .global(qos: .background))
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//        // Fix: remove the UINavigationController pop gesture to avoid problems with the arrows left button
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            self.navigationController?.interactivePopGestureRecognizer?.delaysTouchesBegan = false
//            self.navigationController?.interactivePopGestureRecognizer?.delaysTouchesEnded = false
//            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
//        }
//    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        if isMovingFromParent {     // To keep streaming data when pushing a child view
//            controllerData.stop()
//        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Disable Rssi timer
        rssiRefreshTimer?.invalidate()
        rssiRefreshTimer = nil
    }
    
//    @objc func onTouchUp(_ sender: UIButton) {
//        DLog("Pressed button UP")
//        sendTouchEvent(tag: sender.tag, isPressed: false)
//    }
    
    private func sendTouchEvent(tag: Int, isPressed: Bool) {
        let message = "!B\(tag)\(isPressed ? "1" : "0")"
        if let data = message.data(using: String.Encoding.utf8) {
            controllerData.sendCrcData(data)
            DLog("data sent!")
        }
    }
    
    fileprivate let kDetailItemOffset = 100

    
    // MARK: - UI
    @objc private func rssiRefreshFired() {
        blePeripheral?.readRssi()
    }
    
    func checkConnected() -> Bool {
        if !modelController.appState.isConnected() {
            showNotConnectedDialog()
            return false
        }
        return true
    }
    
    func updateUI() {
        if modelController.appState.isConnected() {
//            setupUART()
            showConnected()
        } else {
            showDisconnected()
        }
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
