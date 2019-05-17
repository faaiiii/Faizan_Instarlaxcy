//
//  GalleryImageCell.swift
//  instarlaxcy
//
//  Created by Faizan Khalid on 17/04/2019.
//  Copyright © 2019 Faizan Khalid. All rights reserved.
//

import UIKit
import Kingfisher

struct FBImage {
    let url: String
    let id: String
    let timestamp: Double

    init?(key: String, raw: AnyObject) {
        guard let url = raw["profileUrl"] as? String else { return nil }
        self.url = url
        timestamp = Date().timeIntervalSince1970
        id = key
    }
}

class GalleryImageCell: UICollectionViewCell {
    var data: FBImage?
    func setData(data: FBImage) {
        self.data = data
        guard let url = URL(string: data.url) else { return }
        imageView.kf.setImage(with: ImageResource(downloadURL: url), placeholder: UIImage(named: "image_placeholder"))
    }
    @IBOutlet weak var imageView: UIImageView!
}
