//
//  DemoViewController.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 7/8/25.
//

import UIKit
import MetalPetal

class DemoViewController: UIViewController {
    
    @IBOutlet weak var mtImageView: MTIImageView!
    
    var image: MTIImage? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        mtImageView.resizingMode = .aspect
        // Do any additional setup after loading the view.
        mtImageView.image = image
    }
    
    @IBAction func tappedOnCancelBtn(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
}
