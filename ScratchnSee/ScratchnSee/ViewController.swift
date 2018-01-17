//
//  ViewController.swift
//  TestMyNewScratchApproach
//
//  Created by Nandini on 18/01/18.
//  Copyright © 2018 SaAg. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var wonImage: UIImageView!
    @IBOutlet weak var scratchImage: ImageMaskView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        scratchImage.radius = 40
        scratchImage.beginInteraction()
        scratchImage.imageMaskFilledDelegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

extension ViewController: ImageMaskFilledDelegate {
    func imageMaskView(maskView: ImageMaskView, clearPercent: Float) {
        if clearPercent > 60 {
            UIView.animate(withDuration: 2, animations: {
                self.scratchImage.isUserInteractionEnabled = false
                self.scratchImage.alpha = 0
            }, completion: {(success) in
            })
        }
    }
}

