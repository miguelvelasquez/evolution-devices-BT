//
//  RunViewController.swift
//  Evolution Devices BT
//
//  Created by Pierluigi Mantovani on 10/30/18.
//  Copyright © 2018 Miguel A Velasquez. All rights reserved.
//

import Foundation
import UIKit

// MARK: Stopwatch
// Properties
class RunViewController: PeripheralModeViewController {
    
        @IBOutlet weak var stopwatchLabel: UILabel!
        var stopwatch: LabelStopwatch!
    
        weak var delegate: RunModuleManagerDelegate?
        fileprivate var runData: RunModuleManager!
        fileprivate var contentItems = [Int]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        let localizationManager = LocalizationManager.shared
        let name = blePeripheral?.name ?? LocalizationManager.shared.localizedString("scanner_unnamed")
        self.title = traitCollection.horizontalSizeClass == .regular ? String(format: localizationManager.localizedString("run_navigation_title_format"), arguments: [name]) : localizationManager.localizedString("run_tab_title")
        
        // Init
        assert(blePeripheral != nil)
        runData = RunModuleManager(blePeripheral: blePeripheral!, delegate: self)
        DLog("CHECKING UART STATUS")
        if let enabled = blePeripheral?.isUartEnabled() {
            DLog(String(enabled))
        }
        // UI
    //    uartView.layer.cornerRadius = 4
    //    uartView.layer.masksToBounds = true
        // Create the stopwatch with the stopwatchLabel
        stopwatch = LabelStopwatch(label: stopwatchLabel)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    // Start button action
    @IBAction func startButtonPressed(_ sender: UIButton) {
        stopwatch.start()
    }

    // Pause button action
    @IBAction func pauseButtonPressed(_ sender: UIButton) {
        stopwatch.pause()
    }

    // Stop button pressed
    @IBAction func stopButtonPressed(_ sender: UIButton) {
        stopwatch.stop()
    }
    @objc func onTouchUp(_ sender: UIButton) {
        DLog("Pressed button UP")
        sendTouchEvent(tag: sender.tag, isPressed: false)
    }
    
    private func sendTouchEvent(tag: Int, isPressed: Bool) {
        let message = "!B\(tag)\(isPressed ? "1" : "0")"
        if let data = message.data(using: String.Encoding.utf8) {
            runData.sendCrcData(data)
        }
    }
}
class Stopwatch: NSObject {
    
    // Timer
    fileprivate var timer = Timer()
    
    // MARK: Time in a string
    /**
     String representation of the number of hours shown on the stopwatch
     */
    var strHours = "00"
    /**
     String representation of the number of minutes shown on the stopwatch
     */
    var strMinutes = "00"
    /**
     String representation of the number of seconds shown on the stopwatch
     */
    var strSeconds = "00"
    /**
     String representation of the number of tenths of a second shown on the stopwatch
     */
    var strTenthsOfSecond = "00"
    /**
     String representation text shown on the stopwatch (the time)
     */
    var timeText = ""
    
    // MARK: Time in values
    /**
     The number of hours that will be shown on a stopwatch
     */
    var numHours = 0
    /**
     The number of minutes that will be shown on a stopwatch
     */
    var numMinutes = 0
    /**
     The number of seconds that will be shown on a stopwatch
     */
    var numSeconds = 0
    /**
     The number of tenths of a second that will be shown on a stopwatch
     */
    var numTenthsOfSecond = 0
    
    // Private variables
    fileprivate var startTime = TimeInterval()
    fileprivate var pauseTime = TimeInterval()
    fileprivate var wasPause = false
    
    
    
    /**
     Updates the time and saves the values as strings
     */
    @objc fileprivate func updateTime() {
        // Save the current time
        let currentTime = Date.timeIntervalSinceReferenceDate
        
        // Find the difference between current time and start time to get the time elapsed
        var elapsedTime: TimeInterval = currentTime - startTime
        
        // Calculate the hours of elapsed time
        numHours = Int(elapsedTime / 3600.0)
        elapsedTime -= (TimeInterval(numHours) * 3600)
        
        // Calculate the minutes of elapsed time
        numMinutes = Int(elapsedTime / 60.0)
        elapsedTime -= (TimeInterval(numMinutes) * 60)
        
        // Calculate the seconds of elapsed time
        numSeconds = Int(elapsedTime)
        elapsedTime -= TimeInterval(numSeconds)
        
        // Finds out the number of milliseconds to be displayed.
        numTenthsOfSecond = Int(elapsedTime * 100)
        
        // Save the values into strings with the 00 format
        strHours = String(format: "%02d", numHours)
        strMinutes = String(format: "%02d", numMinutes)
        strSeconds = String(format: "%02d", numSeconds)
        strTenthsOfSecond = String(format: "%02d", numTenthsOfSecond)
        timeText = "\(strHours):\(strMinutes):\(strSeconds):\(strTenthsOfSecond)"
    }
    
    
    // MARK: Public functions
    fileprivate func resetTimer() {
        startTime = Date.timeIntervalSinceReferenceDate
        strHours = "00"
        strMinutes = "00"
        strSeconds = "00"
        strTenthsOfSecond = "00"
        timeText = "\(strHours):\(strMinutes):\(strSeconds):\(strTenthsOfSecond)"
        
    }
    
    /**
     Starts the stopwatch, or resumes it if it was paused
     */
    func start() {
        if !timer.isValid {
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(Stopwatch.updateTime), userInfo: nil, repeats: true)
            
            if wasPause {
                startTime = Date.timeIntervalSinceReferenceDate - startTime
            } else {
                startTime = Date.timeIntervalSinceReferenceDate
            }
        }
    }
    
    /**
     Pause the stopwatch so that it can be resumed later
     */
    func pause() {
        wasPause = true
        
        timer.invalidate()
        pauseTime = Date.timeIntervalSinceReferenceDate
        startTime = pauseTime - startTime
    }
    
    /**
     Stops the stopwatch and erases the current time
     */
    func stop() {
        wasPause = false
        
        timer.invalidate()
        resetTimer()
    }
    
    
    // MARK: Value functions
    
    /**
     Converts the time into hours only and returns it
     */
    func getTimeInHours() -> Int {
        return numHours
    }
    
    /**
     Converts the time into minutes only and returns it
     */
    func getTimeInMinutes() -> Int {
        return numHours * 60 + numMinutes
    }
    
    /**
     Converts the time into seconds only and returns it
     */
    func getTimeInSeconds() -> Int {
        return numHours * 3600 + numMinutes * 60 + numSeconds
    }
    
    /**
     Converts the time into milliseconds only and returns it
     */
    func getTimeInMilliseconds() -> Int {
        return numHours * 3600000 + numMinutes * 60000 + numSeconds * 1000 + numTenthsOfSecond * 100
    }
    
}

// MARK: - ControllerModuleManagerDelegate
extension RunViewController: RunModuleManagerDelegate {
    func onRunUartIsReady(error: Error?) {
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
//        setUartText(self.controllerData.uartTextBuffer())
        
        
    }
}
// MARK: LabelStopwatch
/**
 * Subclass of Stopwatch
 *
 * This class automatically updates any UILabel wih the stopwatch time.
 * This makes it easier to use the stopwatch. All you have to do is create a
 * LabelStopwatch and pass in your UILabel as the parameter. Then the LabelStopwatch
 * will automatically update your label as you call the start, stop, or reset functions.
 */

class LabelStopwatch: Stopwatch {
    
    /**
     The label that will automatically be updated according to the stopwatch
     */
    var label = UILabel()
    
    /**
     Creates a stopwatch with a label that it will constantly update
     */
    init(label: UILabel) {
        self.label = label
    }
    
    override fileprivate func updateTime() {
        super.updateTime()
        
        //concatenate minuets, seconds and milliseconds as assign it to the UILabel
        label.text = "\(strHours):\(strMinutes):\(strSeconds):\(strTenthsOfSecond)"
    }
    
    override fileprivate func resetTimer() {
        super.resetTimer()
        label.text = "\(strHours):\(strMinutes):\(strSeconds):\(strTenthsOfSecond)"
    }
    
}


