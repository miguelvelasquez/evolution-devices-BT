//
//  DashboardCell.swift
//  Evolution Devices BT
//
//  Created by Miguel A Velasquez on 10/30/18.
//  Copyright © 2018 Miguel A Velasquez. All rights reserved.
//

import Foundation
import UIKit

class DashboardCell: UICollectionViewCell {

//    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var viewController: UIViewController!
    var title: String!
    // MARK: - View Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
//    func displayImage(image: UIImage) {
//        self.image.image = image
//    }
    func setLabel(text: String) {
        if let textLabel = label
        {
            DLog("HUH??")
            textLabel.text = text
        }
    }
}
