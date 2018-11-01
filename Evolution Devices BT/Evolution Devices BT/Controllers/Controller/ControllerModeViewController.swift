//
//  ControllerModeViewController.swift
//  Bluefruit Connect
//
//  Created by Antonio García on 12/02/16.
//  Copyright © 2016 Adafruit. All rights reserved.
//

import UIKit

protocol ControllerModeViewControllerDelegate: class {
    func onSendControllerPadButtonStatus(tag: Int, isPressed: Bool)
}

class ControllerModeViewController: PeripheralModeViewController {
    
    // Constants
    fileprivate static let kPollInterval = 0.25
    

    // UI
    @IBOutlet weak var directionsView: UIView!
    @IBOutlet weak var numbersView: UIView!
    @IBOutlet weak var uartTextView: UITextView!
    @IBOutlet weak var uartView: UIView!
    
    // Data
    weak var delegate: ControllerModeViewControllerDelegate?
    fileprivate var controllerData: ControllerModuleManager!
    fileprivate var contentItems = [Int]()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        let localizationManager = LocalizationManager.shared
        let name = blePeripheral?.name ?? LocalizationManager.shared.localizedString("scanner_unnamed")
        self.title = traitCollection.horizontalSizeClass == .regular ? String(format: localizationManager.localizedString("controller_navigation_title_format"), arguments: [name]) : localizationManager.localizedString("controller_tab_title")
        
        // Init
        assert(blePeripheral != nil)
        controllerData = ControllerModuleManager(blePeripheral: blePeripheral!, delegate: self)
        DLog("CHECKING UART STATUS")
        if let enabled = blePeripheral?.isUartEnabled() {
            DLog(String(enabled))
        }
        // UI
        uartView.layer.cornerRadius = 4
        uartView.layer.masksToBounds = true
        
        // Setup buttons targets
        for subview in directionsView.subviews {
            if let button = subview as? UIButton {
                setupButton(button)
            }
        }
        
        for subview in numbersView.subviews {
            if let button = subview as? UIButton {
                setupButton(button)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isMovingToParent {       // To keep streaming data when pushing a child view
            controllerData.start(pollInterval: ControllerModeViewController.kPollInterval) { [unowned self] in
            }

        } else {
            // Disable cache if coming back from Control Pad
            controllerData.isUartRxCacheEnabled = false
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Fix: remove the UINavigationController pop gesture to avoid problems with the arrows left button
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.navigationController?.interactivePopGestureRecognizer?.delaysTouchesBegan = false
            self.navigationController?.interactivePopGestureRecognizer?.delaysTouchesEnded = false
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent {     // To keep streaming data when pushing a child view
            controllerData.stop()
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        DLog("ControllerModeViewController deinit")
    }
    
    // MARK: - UI
    fileprivate func setupButton(_ button: UIButton) {
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.masksToBounds = true
        
        button.setTitleColor(UIColor.lightGray, for: .highlighted)
        
        //        let hightlightedImage = UIImage(color: UIColor.darkGray)
        //        button.setBackgroundImage(hightlightedImage, for: .highlighted)
        
        button.addTarget(self, action: #selector(onTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(onTouchUp(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(onTouchUp(_:)), for: .touchDragExit)
        button.addTarget(self, action: #selector(onTouchUp(_:)), for: .touchCancel)
    }
    
    func setUartText(_ text: String) {
        
        // Remove the last character if is a newline character
        let lastCharacter = text.last
        let shouldRemoveTrailingNewline = lastCharacter == "\n" || lastCharacter == "\r" //|| lastCharacter == "\r\n"
        //let formattedText = shouldRemoveTrailingNewline ? text.substring(to: text.index(before: text.endIndex)) : text
        let formattedText = shouldRemoveTrailingNewline ? String(text[..<text.index(before: text.endIndex)]) : text
        
        //
        uartTextView.text = formattedText
        
        // Scroll to bottom
        let bottom = max(0, uartTextView.contentSize.height - uartTextView.bounds.size.height)
        uartTextView.setContentOffset(CGPoint(x: 0, y: bottom), animated: true)
        /*
         let textLength = text.characters.count
         if textLength > 0 {
         let range = NSMakeRange(textLength - 1, 1)
         uartTextView.scrollRangeToVisible(range)
         }*/
    }
    
    // MARK: - Actions
    @objc func onTouchDown(_ sender: UIButton) {
        DLog("Pressed button DOWN")
        sendTouchEvent(tag: sender.tag, isPressed: true)
    }
    
    @objc func onTouchUp(_ sender: UIButton) {
        DLog("Pressed button UP")
        sendTouchEvent(tag: sender.tag, isPressed: false)
    }
    
    private func sendTouchEvent(tag: Int, isPressed: Bool) {
        DLog("TOUCH EVENT BOIII")
        let message = "!B\(tag)\(isPressed ? "1" : "0")"
        if let data = message.data(using: String.Encoding.utf8) {
            controllerData.sendCrcData(data)
        }
    }
    
    fileprivate let kDetailItemOffset = 100
    
    // MARK: Notifications
    private weak var didReceiveWatchCommandObserver: NSObjectProtocol?

    
    // MARK: - Actions
    @IBAction func onClickHelp(_  sender: UIBarButtonItem) {
        let localizationManager = LocalizationManager.shared
        let helpViewController = storyboard!.instantiateViewController(withIdentifier: "HelpViewController") as! HelpViewController
        helpViewController.setHelp(localizationManager.localizedString("controller_help_text"), title: localizationManager.localizedString("controller_help_title"))
        let helpNavigationController = UINavigationController(rootViewController: helpViewController)
        helpNavigationController.modalPresentationStyle = .popover
        helpNavigationController.popoverPresentationController?.barButtonItem = sender
        
        present(helpNavigationController, animated: true, completion: nil)
    }
    
}

// MARK: - ControllerPadViewControllerDelegate
extension ControllerModeViewController: ControllerPadViewControllerDelegate {
    func onSendControllerPadButtonStatus(tag: Int, isPressed: Bool) {
        sendTouchEvent(tag: tag, isPressed: isPressed)
    }
}

// MARK: - UITableViewDataSource
extension ControllerModeViewController : UITableViewDataSource {
    fileprivate static let kSensorTitleKeys: [String] = ["controller_sensor_quaternion", "controller_sensor_accelerometer", "controller_sensor_gyro", "controller_sensor_magnetometer", "controller_sensor_location"]
    fileprivate static let kModuleTitleKeys: [String] = ["controller_module_pad", "controller_module_colorpicker"]
    
    enum ControllerSection: Int {
        case module = 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch ControllerSection(rawValue: section)! {
        case .module:
            return ControllerModeViewController.kModuleTitleKeys.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var localizationKey: String!
        
        switch ControllerSection(rawValue: section)! {
        case .module:
            localizationKey = "controller_module_title"
        }
        
        return LocalizationManager.shared.localizedString(localizationKey)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let localizationManager = LocalizationManager.shared
        var cell: UITableViewCell!
        switch ControllerSection(rawValue: indexPath.section)! {
            
        case .module:
            let reuseIdentifier = "ModuleCell"
            cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
            }
            cell.accessoryType = .disclosureIndicator
            cell.textLabel!.text = localizationManager.localizedString(ControllerModeViewController.kModuleTitleKeys[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch ControllerSection(rawValue: indexPath.section)! {
        default:
            return 44
        }
    }
}


// MARK: - ControllerModuleManagerDelegate
extension ControllerModeViewController: ControllerModuleManagerDelegate {
    func onControllerUartIsReady(error: Error?) {
        DispatchQueue.main.async {
            guard error == nil else {
                DLog("Error initializing uart")
                self.dismiss(animated: true, completion: { [weak self] in
                    guard let context = self else { return }
                    let localizationManager = LocalizationManager.shared
                    showErrorAlert(from: context, title: localizationManager.localizedString("dialog_error"), message: localizationManager.localizedString("uart_error_peripheralinit"))
                    
                    if let blePeripheral = context.blePeripheral {
                        BleManager.shared.disconnect(from: blePeripheral)
                    }
                })
                return
            }
        }
    }
    
    func onUarRX() {
        // Uart data recevied
        
        
//        self.enh_throttledReloadData()      // it will call self.reloadData without overloading the main thread with calls
    }
    
    func reloadData() {
        // Refresh the controllerPadViewController uart text
        setUartText(self.controllerData.uartTextBuffer())
        
    }
}
