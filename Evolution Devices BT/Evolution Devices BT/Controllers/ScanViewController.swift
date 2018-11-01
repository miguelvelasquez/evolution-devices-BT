//
//  ScanViewController.swift
//  Evolution Devices BT
//
//  Created by Miguel A Velasquez on 10/22/18.
//  Copyright © 2018 Miguel A Velasquez. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

class ScanViewController: UIViewController {
    
    // UI
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var baseTableView: UITableView!
    
    // Data
    fileprivate let refreshControl = UIRefreshControl()
    fileprivate var peripheralList: PeripheralList!
    fileprivate var isRowDetailOpenForPeripheral = [UUID: Bool]()          // Is the detailed info row open [PeripheralIdentifier: Bool]
    
    fileprivate var selectedPeripheral: BlePeripheral?
    
    fileprivate let firmwareUpdater = FirmwareUpdater()
    fileprivate var infoAlertController: UIAlertController?
    
    fileprivate var isBaseTableScrolling = false
    fileprivate var isScannerTableWaitingForReload = false
    fileprivate var isBaseTableAnimating = false
    
    var modelController: ModelController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        baseTableView.register(UINib(nibName: "DeviceTableViewCell", bundle: nil), forCellReuseIdentifier: "peripheralCell")

        if modelController.appState.isConnected() {
            showConnected()
        } else {
            showDisconnected()
        }
        
        // Init
        peripheralList = PeripheralList()                  // Initialize here to wait for Preferences.registerDefaults to be executed
        
        // Setup table view
        baseTableView.estimatedRowHeight = 66
        baseTableView.rowHeight = UITableView.automaticDimension
        
        // Setup table refresh
        refreshControl.addTarget(self, action: #selector(onTableRefresh(_:)), for: UIControl.Event.valueChanged)
        baseTableView.addSubview(refreshControl)
        baseTableView.sendSubviewToBack(refreshControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Flush any pending state notifications
        didUpdateBleState()
        
        // Ble Notifications
        registerNotifications(enabled: true)
        DLog("Scanner: Register notifications")
        
//        let isFullScreen = UIScreen.main.traitCollection.horizontalSizeClass == .compact
//
//        if isFullScreen {
//            // If only connected to 1 peripheral and coming back to this
//            let connectedPeripherals = BleManager.shared.connectedPeripherals()
//            if connectedPeripherals.count == 1, let peripheral = connectedPeripherals.first {
//                DLog("Disconnect from previously connected peripheral")
//                // Disconnect from peripheral
//                BleManager.shared.disconnect(from: peripheral)
//            }
//        }
        
        // Start scannning
        BleManager.shared.startScan()
        DLog("Scanning")
        //        BleManager.sharedInstance.startScan(withServices: ScannerViewController.kServicesToScan)
        
        // Update UI
        updateScannedPeripherals()
    }
    
    func showConnected() {
        imageView.image = UIImage(named: "device_connection")

    }
    
    func showDisconnected() {
        imageView.image = UIImage(named: "device_unconnected")
    }
    
    // MARK: - Connections
    fileprivate func connect(peripheral: BlePeripheral) {
        DLog("connect son")
        // Connect to selected peripheral
        selectedPeripheral = peripheral
        BleManager.shared.connect(to: peripheral)
        modelController.appState.setConnected(peripheral: peripheral)
        reloadBaseTable()
    }
    
    fileprivate func disconnect(peripheral: BlePeripheral) {
        selectedPeripheral = nil
        BleManager.shared.disconnect(from: peripheral)
        modelController.appState.setDisconnected(peripheral: peripheral)
        reloadBaseTable()
    }
    
    // MARK: - UI
    private func updateScannedPeripherals() {
        
        // Reload table
        if isBaseTableScrolling || isBaseTableAnimating {
            isScannerTableWaitingForReload = true
        } else {
            reloadBaseTable()
        }
    }
    
    fileprivate func reloadBaseTable() {
        isBaseTableScrolling = false
        isBaseTableAnimating = false
        isScannerTableWaitingForReload = false
        let filteredPeripherals = peripheralList.filteredPeripherals(forceUpdate: true)     // Refresh the peripherals
        baseTableView.reloadData()
        
//        DLog("Num peripherals: \(filteredPeripherals.count)")
        
        
        // Filtered out label
//        let numPeripheralsFilteredOut = peripheralList.numPeripheralsFiltered()
        
//        let isNoDevicesFoundLabelHidden = filteredPeripherals.count > 0 || numPeripheralsFilteredOut == 0
//        if noDevicesFoundLabel.isHidden && !isNoDevicesFoundLabelHidden {
//            // If becoming visible, animate the change but wait a bit to avoid unnecesary blinking if a device is about to be discovered
//            noDevicesFoundLabel.alpha = 0
//            UIView.animate(withDuration: 0.25, delay: 0.2, options: [], animations: {
//                self.noDevicesFoundLabel.alpha = 1
//            }, completion: nil)
//        }
        
//        let localizationManager = LocalizationManager.shared
        
//        noDevicesFoundLabel.isHidden = isNoDevicesFoundLabelHidden
//
//        noDevicesFoundLabel.text = String(format:  localizationManager.localizedString(numPeripheralsFilteredOut == 1 ? "scanner_filteredoutinfo_single_format":"no_devices_found"), numPeripheralsFilteredOut)
        
        // Select the previously selected row
        if let selectedPeripheral = selectedPeripheral, let selectedRow = filteredPeripherals.index(of: selectedPeripheral) {
            baseTableView.selectRow(at: IndexPath(row: selectedRow, section: 0), animated: false, scrollPosition: .none)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Stop scanning
        BleManager.shared.stopScan()
        
        // Ble Notifications
        registerNotifications(enabled: false)
        
        // Clear peripherals
        peripheralList.clear()
        isRowDetailOpenForPeripheral.removeAll()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    
    // MARK: - BLE Notifications
    private weak var didUpdateBleStateObserver: NSObjectProtocol?
    private weak var didDiscoverPeripheralObserver: NSObjectProtocol?
    private weak var willConnectToPeripheralObserver: NSObjectProtocol?
    private weak var didConnectToPeripheralObserver: NSObjectProtocol?
    private weak var didDisconnectFromPeripheralObserver: NSObjectProtocol?
    private weak var peripheralDidUpdateNameObserver: NSObjectProtocol?
    
    private func registerNotifications(enabled: Bool) {
        let notificationCenter = NotificationCenter.default
        if enabled {
            didUpdateBleStateObserver = notificationCenter.addObserver(forName: .didUpdateBleState, object: nil, queue: .main, using: {[weak self] _ in self?.didUpdateBleState()})
            didDiscoverPeripheralObserver = notificationCenter.addObserver(forName: .didDiscoverPeripheral, object: nil, queue: .main, using: {[weak self] _ in self?.didDiscoverPeripheral()})
            willConnectToPeripheralObserver = notificationCenter.addObserver(forName: .willConnectToPeripheral, object: nil, queue: .main, using: {[weak self] notification in self?.willConnectToPeripheral(notification: notification)})
            didConnectToPeripheralObserver = notificationCenter.addObserver(forName: .didConnectToPeripheral, object: nil, queue: .main, using: {[weak self] notification in self?.didConnectToPeripheral(notification: notification)})
            didDisconnectFromPeripheralObserver = notificationCenter.addObserver(forName: .didDisconnectFromPeripheral, object: nil, queue: .main, using: {[weak self] notification in self?.didDisconnectFromPeripheral(notification: notification)})
            peripheralDidUpdateNameObserver = notificationCenter.addObserver(forName: .peripheralDidUpdateName, object: nil, queue: .main, using: {[weak self] notification in self?.peripheralDidUpdateName(notification: notification)})
        } else {
            if let didUpdateBleStateObserver = didUpdateBleStateObserver {notificationCenter.removeObserver(didUpdateBleStateObserver)}
            if let didDiscoverPeripheralObserver = didDiscoverPeripheralObserver {notificationCenter.removeObserver(didDiscoverPeripheralObserver)}
            if let willConnectToPeripheralObserver = willConnectToPeripheralObserver {notificationCenter.removeObserver(willConnectToPeripheralObserver)}
            if let didConnectToPeripheralObserver = didConnectToPeripheralObserver {notificationCenter.removeObserver(didConnectToPeripheralObserver)}
            if let didDisconnectFromPeripheralObserver = didDisconnectFromPeripheralObserver {notificationCenter.removeObserver(didDisconnectFromPeripheralObserver)}
            if let peripheralDidUpdateNameObserver = peripheralDidUpdateNameObserver {notificationCenter.removeObserver(peripheralDidUpdateNameObserver)}
        }
    }
    
    
    
    private func didUpdateBleState() {
        guard let state = BleManager.shared.centralManager?.state else { return }
        
        // Check if there is any error
        var errorMessageId: String?
        switch state {
        case .unsupported:
            errorMessageId = "bluetooth_unsupported"
        case .unauthorized:
            errorMessageId = "bluetooth_notauthorized"
        case .poweredOff:
            errorMessageId = "bluetooth_poweredoff"
        default:
            errorMessageId = nil
        }
        
        // Show alert if error found
        if let errorMessageId = errorMessageId {
            let localizationManager = LocalizationManager.shared
            let errorMessage = localizationManager.localizedString(errorMessageId)
            DLog("Error: \(errorMessage)")
            
            // Reload peripherals
            refreshPeripherals()
            
            // Show error
            let alertController = UIAlertController(title: localizationManager.localizedString("dialog_error"), message: errorMessage, preferredStyle: .alert)
            let okAction = UIAlertAction(title: localizationManager.localizedString("dialog_ok"), style: .default, handler: { (_) -> Void in
                if let navController = self.splitViewController?.viewControllers[0] as? UINavigationController {
                    navController.popViewController(animated: true)
                }
            })
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    fileprivate func refreshPeripherals() {
        isRowDetailOpenForPeripheral.removeAll()
        BleManager.shared.refreshPeripherals()
        reloadBaseTable()
    }
    
    
    private func didDiscoverPeripheral() {
        updateScannedPeripherals()
    }
    
    private func willConnectToPeripheral(notification: Notification) {
        DLog("Will connect")
//        guard let peripheral = BleManager.shared.peripheral(from: notification) else { return }
//        presentInfoDialog(title: LocalizationManager.shared.localizedString("peripheraldetails_connecting"), peripheral: peripheral)
    }
    
    private func didConnectToPeripheral(notification: Notification) {
        DLog("Did connect to peripheral")
        guard let selectedPeripheral = selectedPeripheral, let identifier = notification.userInfo?[BleManager.NotificationUserInfoKey.uuid.rawValue] as? UUID, selectedPeripheral.identifier == identifier else {
            DLog("Connected to an unexpected peripheral")
            return
        }
        // Discover services
        infoAlertController?.message = LocalizationManager.shared.localizedString("peripheraldetails_discoveringservices")
        discoverServices(peripheral: selectedPeripheral)
        
    }
    
    private func didDisconnectFromPeripheral(notification: Notification) {
        let peripheral = BleManager.shared.peripheral(from: notification)
        let currentlyConnectedPeripheralsCount = BleManager.shared.connectedPeripherals().count
        
        guard let selectedPeripheral = selectedPeripheral, selectedPeripheral.identifier == peripheral?.identifier || currentlyConnectedPeripheralsCount == 0 else {        // If selected peripheral is disconnected or if there not any peripherals connected (after a failed dfu update)
            return
        }
        
        // Clear selected peripheral
        self.selectedPeripheral = nil
        
        // Dismiss any info open dialogs
        infoAlertController?.dismiss(animated: true, completion: nil)
        infoAlertController = nil
        
        // Reload table
        reloadBaseTable()
    }
    
    private func peripheralDidUpdateName(notification: Notification) {
        let name = notification.userInfo?[BlePeripheral.NotificationUserInfoKey.name.rawValue] as? String
        DLog("centralManager peripheralDidUpdateName: \(name ?? "<unknown>")")
        
        DispatchQueue.main.async {
            // Reload table
            self.reloadBaseTable()
        }
    }
    
    
//    fileprivate func showPeripheralUpdate() {
//        if let peripheralModulesNavigationController = detailRootController as? UINavigationController, let peripheralModulesViewController = peripheralModulesNavigationController.topViewController as? PeripheralModulesViewController {
//            peripheralModulesViewController.blePeripheral = selectedPeripheral
//
//            //            if let dfuViewController = self.storyboard!.instantiateViewController(withIdentifier: "DfuModeViewController") as? DfuModeViewController {
//            //                dfuViewController.blePeripheral = selectedPeripheral
//            //                peripheralModulesNavigationController.viewControllers = [peripheralModulesViewController, dfuViewController]
//            //            }
//            showDetailViewController(peripheralModulesNavigationController, sender: self)
//        }
//    }
//
//    fileprivate func showMultipleConnectionsMode() {
//        detailRootController = self.storyboard?.instantiateViewController(withIdentifier: "PeripheralModulesNavigationController")
//        if let peripheralModulesNavigationController = detailRootController as? UINavigationController, let peripheralModulesViewController = peripheralModulesNavigationController.topViewController as? PeripheralModulesViewController {
//            peripheralModulesViewController.blePeripheral = nil
//            peripheralModulesViewController.connectionMode = .multiplePeripherals
//            showDetailViewController(peripheralModulesNavigationController, sender: self)
//        }
//    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return selectedPeripheral != nil
    }
    
    
    // MARK: - Device setup
    private func discoverServices(peripheral: BlePeripheral) {
        DLog("Discovering services")
        
        peripheral.discover(serviceUuids: nil) { [weak self] error in
            guard let context = self else { return }
            let localizationManager = LocalizationManager.shared
            
            DispatchQueue.main.async {
                guard error == nil else {
                    DLog("Error initializing peripheral")
                    context.dismiss(animated: true, completion: { [weak self] () -> Void in
                        if let context = self {
                            showErrorAlert(from: context, title: localizationManager.localizedString("dialog_error"), message: localizationManager.localizedString("peripheraldetails_errordiscoveringservices"))
                            BleManager.shared.disconnect(from: peripheral)
                        }
                    })
                    return
                }
                
            }
        }
    }
    
    func scanPeripherals() {
        // Start scannning
        BleManager.shared.startScan()
        DLog("Scanning")
        //        BleManager.sharedInstance.startScan(withServices: ScannerViewController.kServicesToScan)
        
        // Update UI
        updateScannedPeripherals()
    }
        
    
    
    // MARK: - Actions
    @objc func onTableRefresh(_ sender: AnyObject) {
        refreshPeripherals()
        refreshControl.endRefreshing()
    }
    
}

// MARK: - UITableViewDataSource
extension ScanViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Calculate num cells
        return peripheralList.filteredPeripherals(forceUpdate: false).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "peripheralCell"

        let peripheralCell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! DeviceTableViewCell
        peripheralCell.selectionStyle = .none
        // Note: not using willDisplayCell to avoid problems with self-sizing cells
        let peripheral = peripheralList.filteredPeripherals(forceUpdate: false)[indexPath.row]
        
        // Fill data
        //        DLog("SHOW ME THE DATA")
        let localizationManager = LocalizationManager.shared
        peripheralCell.deviceNameLabel.text = peripheral.name ?? localizationManager.localizedString("scanner_unnamed")
        peripheralCell.rssiImageView.image = RssiUI.signalImage(for: peripheral.rssi)
        
        
        let connected: Bool
        connected = peripheral.identifier == selectedPeripheral?.identifier || peripheral.identifier == modelController.appState.device?.identifier
        
        peripheralCell.connected = connected
        if connected {
            peripheralCell.setConnected()
        } else {
            peripheralCell.setDisconnected()
        }
//        peripheralCell.disconnectButton.isHidden = !connected
        
        
        peripheralCell.onClick = { [unowned self] in
            DLog("YOU CLICKED")
            if peripheralCell.connected ?? false {
                DLog("YOU CLICKED DISCONNECT")
                tableView.deselectRow(at: indexPath, animated: true)
                self.disconnect(peripheral: peripheral)
                peripheralCell.connected = false
                peripheralCell.button.setTitle("Connect", for: .normal)
            } else {
                DLog("YOU CLICKED CONNECT")
                self.connect(peripheral: peripheral)
            }
        }
        return peripheralCell
    }
}

// MARK: UITableViewDelegate
extension ScanViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let peripheral = peripheralList.filteredPeripherals(forceUpdate: false)[indexPath.row]
        let isDetailViewOpen = !(isRowDetailOpenForPeripheral[peripheral.identifier] ?? false)
        isRowDetailOpenForPeripheral[peripheral.identifier] = isDetailViewOpen
        
        isBaseTableAnimating = true
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.isBaseTableAnimating = false
        }
        tableView.reloadRows(at: [indexPath], with: .fade)
        tableView.scrollToRow(at: indexPath, at: .none, animated: true)
        CATransaction.commit()
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
}

// MARK: UIScrollViewDelegate
extension ScanViewController {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isBaseTableScrolling = true
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isBaseTableScrolling = false
        
        if isScannerTableWaitingForReload {
            reloadBaseTable()
        }
    }
}



