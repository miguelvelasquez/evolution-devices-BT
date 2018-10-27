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

class DashboardViewController: UIViewController {
    
    @IBOutlet weak var buttonImageView: UIImageView!
    @IBOutlet weak var buttonText: UILabel!
    
    @IBOutlet weak var controllerImage: UIImageView!
    @IBOutlet weak var plotterImage: UIImageView!
    @IBAction func pressedControllerButton(_ sender: UITapGestureRecognizer) {
        DLog("pressed controller")
    }
    
    
    @IBAction func pressedPlotterButton(_ sender: UITapGestureRecognizer) {
        DLog("pressed plotter")
    }
    
    @IBAction func pressedConnectivityButton(_ sender: UITapGestureRecognizer) {
        showStandardDialog()
    }
    
    
    /*!
     Displays the default dialog without image, just as the system dialog
     */
    func showStandardDialog(animated: Bool = true) {
        DLog("BRUHHHHHH")
        // Prepare the popup
        let scanVC = ScanViewController(nibName: "ScanViewController", bundle: nil)
        
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
        let buttonOne = CancelButton(title: "CANCEL") {
        }
        
        // Create second button
        let buttonTwo = DefaultButton(title: "SCAN", dismissOnTap: false) {
            scanVC.imageView.image = UIImage(named: "device_connection")
            self.plotterImage.alpha = 0.8
            self.controllerImage.alpha = 0.8
            self.buttonImageView.image = UIImage(named: "device_connection")
            self.buttonText.text = "Connected"
            scanVC.scanPeripherals()
        }
        
        // Add buttons to dialog
        popup.addButtons([buttonOne, buttonTwo])
        
        // Present dialog
        self.present(popup, animated: animated, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonImageView.image = UIImage(named: "device_unconnected")
        buttonText.text = "Not Connected"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
