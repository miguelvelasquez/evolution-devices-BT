//
//  PeripheralModulesViewController.swift
//  Evolution Devices BT
//
//  Created by Miguel A Velasquez on 8/3/18.
//  Copyright © 2018 Miguel A Velasquez. All rights reserved.
//

import UIKit
import MSWeakTimer


class PeripheralModulesViewController: UIViewController {
    // Config
    fileprivate static let kRssiRefreshInterval: TimeInterval = 0.3
    
    // UI
    @IBOutlet weak var baseTableView: UITableView!
    
    // Parameters
    enum ConnectionMode {
        case singlePeripheral
        case multiplePeripherals
    }
    
    var connectionMode = ConnectionMode.singlePeripheral
    weak var blePeripheral: BlePeripheral?
    
    // Data
    enum Modules: Int {
//        case uart
        case plotter
        case controller
    }
    
    private var emptyViewController: EmptyDetailsViewController?
    fileprivate var hasUart = true
    fileprivate var rssiRefreshTimer: MSWeakTimer?
    
    fileprivate var batteryLevel: Int?
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UI
        if let splitViewController = self.splitViewController {
            navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            navigationItem.leftItemsSupplementBackButton = true
        }
        
        emptyViewController = storyboard?.instantiateViewController(withIdentifier: "EmptyDetailsViewController") as? EmptyDetailsViewController
        self.title = LocalizationManager.shared.localizedString("peripheralmodules_title")
        
        // Note: Services should have been discovered previously because we will invoke .hasUart, .hasBattery, etc...
        
        // Init for iPhone
        if let blePeripheral = blePeripheral {
            hasUart = blePeripheral.hasUart()

            setupBatteryUI(blePeripheral: blePeripheral)
            baseTableView.reloadData()
        } else if connectionMode == .multiplePeripherals {
            for blePeripheral in BleManager.shared.connectedPeripherals() {
                setupBatteryUI(blePeripheral: blePeripheral)
            }
            baseTableView.reloadData()
        } else {
            let isFullScreen = UIScreen.main.traitCollection.horizontalSizeClass == .compact
            if !isFullScreen {
                showEmpty(true)
                setConnecting(false)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Notifications
        registerNotifications(enabled: true)
        
        // Schedule Rssi timer
        rssiRefreshTimer = MSWeakTimer.scheduledTimer(withTimeInterval: PeripheralModulesViewController.kRssiRefreshInterval, target: self, selector: #selector(rssiRefreshFired), userInfo: nil, repeats: true, dispatchQueue: .global(qos: .background))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Notifications
        registerNotifications(enabled: false)
        
        // Disable Rssi timer
        rssiRefreshTimer?.invalidate()
        rssiRefreshTimer = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        DLog("PeripheralModulesViewController deinit")
        
        if let blePeripheral = blePeripheral {
            stopBatterUI(blePeripheral: blePeripheral)
        } else if connectionMode == .multiplePeripherals {
            for blePeripheral in BleManager.shared.connectedPeripherals() {
                stopBatterUI(blePeripheral: blePeripheral)
            }
        }
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
        
        if isInMultiUartMode() {
        } else {
            showEmpty(true)
            setConnecting(true)
        }
    }
    
    fileprivate func willDisconnectFromPeripheral(notification: Notification) {
        guard let identifier = notification.userInfo?[BleManager.NotificationUserInfoKey.uuid.rawValue] as? UUID, identifier == blePeripheral?.identifier else { return }
        
        DLog("detail: peripheral willDisconnect")
        let isFullScreen = UIScreen.main.traitCollection.horizontalSizeClass == .compact
        if isFullScreen {       // executed when bluetooth is stopped
            
            // Back to peripheral list
            goBackToPeripheralList()
        } else {
            if connectionMode != .multiplePeripherals {
                blePeripheral = nil
            }
            showEmpty(true)
            setConnecting(false)
        }
    }
    
    fileprivate func peripheralDidUpdateRssi(notification: Notification) {
        guard let identifier = notification.userInfo?[BleManager.NotificationUserInfoKey.uuid.rawValue] as? UUID, identifier == blePeripheral?.identifier else { return }
        
        // Update section
        baseTableView.reloadSections([TableSection.device.rawValue], with: .none)
    }
    
    private func didDisconnectFromPeripheral(notification: Notification) {
        guard let identifier = notification.userInfo?[BleManager.NotificationUserInfoKey.uuid.rawValue] as? UUID, identifier == blePeripheral?.identifier else { return }
        
        // Disable Rssi timer
        rssiRefreshTimer?.invalidate()
        rssiRefreshTimer = nil
    }
    
    func setConnecting(_ isConnecting: Bool) {
        emptyViewController?.setConnecting(isConnecting)
    }
    
    // MARK: - MultiUart Mode
    fileprivate func isInMultiUartMode() -> Bool {
        return blePeripheral == nil && BleManager.shared.connectedPeripherals().count > 0
    }
    
    // MARK: - UI
    @objc private func rssiRefreshFired() {
        blePeripheral?.readRssi()
    }
    
    private func goBackToPeripheralList() {
        // Back to peripheral list
        navigationController?.popToRootViewController(animated: true)
    }
    
    func showEmpty(_ showEmpty: Bool) {
        
        if showEmpty {
            // Show empty view (if needed)
            if let viewController = emptyViewController, viewController.view.superview == nil {
                
                if let containerView = self.view, let subview = viewController.view {
                    subview.translatesAutoresizingMaskIntoConstraints = false
                    self.addChild(viewController)
                    
                    viewController.beginAppearanceTransition(true, animated: true)
                    containerView.addSubview(subview)
                    viewController.endAppearanceTransition()
                    
                    let dictionaryOfVariableBindings = ["subview": subview]
                    containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[subview]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: dictionaryOfVariableBindings))
                    containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[subview]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: dictionaryOfVariableBindings))
                    
                    viewController.didMove(toParent: self)
                }
            }
            
            emptyViewController?.startAnimating()
        } else {
            emptyViewController?.stopAnimating()
            
            if let viewController = emptyViewController {
                viewController.willMove(toParent: nil)
                viewController.view.removeFromSuperview()
                viewController.removeFromParent()
            }
        }
    }
    
    fileprivate func setupBatteryUI(blePeripheral: BlePeripheral) {
        guard blePeripheral.hasBattery() else { return }
        
        blePeripheral.startReadingBatteryLevel(handler: { [weak self] batteryLevel in
            guard let context = self else { return }
            
            context.batteryLevel = batteryLevel
            
            DispatchQueue.main.async {
                // Update section
                context.baseTableView.reloadSections([TableSection.device.rawValue], with: .none)
            }
        })
    }
    
    fileprivate func stopBatterUI(blePeripheral: BlePeripheral) {
        guard blePeripheral.hasBattery() else { return }
        
        blePeripheral.stopReadingBatteryLevel()
    }
    
    
    fileprivate func menuItems() -> [Modules] {
//        if connectionMode == .multiplePeripherals {
//            return [.uart, .plotter]
//        } else if hasUart {
//            return [.uart, .plotter]
//        }
        return [.plotter, .controller]
    }
    
}

// MARK: - UITableViewDataSource
extension PeripheralModulesViewController: UITableViewDataSource {
    
    enum TableSection: Int {
        case device = 0
        case modules = 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TableSection(rawValue: section)! {
        case .device:
            return BleManager.shared.connectedPeripherals().count
        case .modules:
            return menuItems().count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var localizationKey: String!
        
        switch TableSection(rawValue: section)! {
        case .device:
            localizationKey = isInMultiUartMode() ? "peripheralmodules_sectiontitle_device_multiconnect" : "peripheralmodules_sectiontitle_device_single"
        case .modules:
            localizationKey = "peripheralmodules_sectiontitle_modules"
        }
        
        return LocalizationManager.shared.localizedString(localizationKey)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var reuseIdentifier: String
        switch TableSection(rawValue: indexPath.section)! {
        case .device:
            reuseIdentifier = "DeviceCell"
        case .modules:
            reuseIdentifier = "ModuleCell"
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension PeripheralModulesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        let localizationManager = LocalizationManager.shared
        
        switch TableSection(rawValue: indexPath.section)! {
        case .device:
            guard let deviceCell = cell as? PeripheralModulesDeviceTableViewCell else { return }
            let peripherals = BleManager.shared.connectedPeripherals()
            guard peripherals.count > 0, indexPath.row < peripherals.count else { return }
            let peripheral = peripherals[indexPath.row]
            
            deviceCell.titleLabel.text = peripheral.name ?? localizationManager.localizedString("scanner_unnamed")
            deviceCell.rssiImageView.image = RssiUI.signalImage(for: peripheral.rssi)
            deviceCell.rssiLabel.text = peripheral.rssi != nil ? String(format: localizationManager.localizedString("peripheralmodules_rssi_format"), peripheral.rssi!) : localizationManager.localizedString("peripheralmodules_rssi_unavailable")
            
            deviceCell.batteryStackView.isHidden = batteryLevel == nil
            if let batteryLevel = batteryLevel {
                deviceCell.batteryLabel.text = String(format: localizationManager.localizedString("peripheralmodules_battery_format"), batteryLevel)   //"\(batteryLevel)%"
            }
            
        case .modules:
            guard let moduleCell = cell as? PeripheralModulesTableViewCell else { return }
            
            var titleId: String?
            var iconName: String?
            let items = menuItems()
            
            switch items[indexPath.row] {
//            case .uart:
//                iconName = "tab_uart_icon"
//                titleId = "uart_tab_title"
            case .plotter:
                iconName = "tab_plotter_icon"
                titleId = "plotter_tab_title"
            case .controller:
                iconName = "tab_controller_icon"
                titleId = "controller_tab_title"
            }
            
            moduleCell.iconImageView.tintColor = UIColor.darkGray
            moduleCell.iconImageView.image = iconName != nil ? UIImage(named: iconName!) : nil
            moduleCell.titleLabel.text = titleId != nil ? localizationManager.localizedString(titleId!) : nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch TableSection(rawValue: indexPath.section)! {
        case .device:
            return 80
        case .modules:
            return traitCollection.userInterfaceIdiom == .pad ? 66 : 44
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch TableSection(rawValue: indexPath.section)! {
        case .device:
            // Not selectable
            break
            
        case .modules:
            let items = menuItems()
            
            switch items[indexPath.row] {
//            case .uart:
//                if let uartViewController = self.storyboard?.instantiateViewController(withIdentifier: "UartModeViewController") as? UartModeViewController {
//                    uartViewController.blePeripheral = blePeripheral
//                    show(uartViewController, sender: self)
//                }
            case .plotter:
                if let plotterViewController = self.storyboard?.instantiateViewController(withIdentifier: "PlotterModeViewController") as? PlotterModeViewController {
                    plotterViewController.blePeripheral = blePeripheral
                    show(plotterViewController, sender: self)
                }
            case .controller:
                if let controllerViewController = self.storyboard?.instantiateViewController(withIdentifier: "ControllerModeViewController") as? ControllerModeViewController {
                    controllerViewController.blePeripheral = blePeripheral
                    show(controllerViewController, sender: self)
                }

            }
            
        }
        tableView.deselectRow(at: indexPath, animated: indexPath.section == 0)
    }
}
