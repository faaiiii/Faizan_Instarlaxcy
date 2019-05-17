//
//  ResizableImageView.swift
//  instarlaxcy
//
//  Created by Faizan Khalid on 23/04/2019.
//  Copyright © 2019 Faizan Khalid. All rights reserved.
//

import UIKit

class ResizableImageView: UIImageView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    override var image: UIImage? {
        didSet {
            guard let image = image else { return }
            
            let resizeConstraints = [
                self.heightAnchor.constraint(equalToConstant: image.size.height),
                self.widthAnchor.constraint(equalToConstant: image.size.width)
            ]
            
            if superview != nil {
                addConstraints(resizeConstraints)
            }
        }
    }
}

