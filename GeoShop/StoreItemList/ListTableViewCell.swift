//
//  ListTableViewCell.swift
//  GeoShopping
//
//  Created by Mischa Nee on 11/22/17.
//  Copyright © 2017 Mischa Nee. All rights reserved.
//

import UIKit

class ListTableViewCell: UITableViewCell {

    var checked: Bool = false
    var checkedImage = UIImage(named: "CheckedBox")
    var uncheckedImage = UIImage(named: "UncheckedBox")
    
    @IBOutlet weak var checkBox: UIButton! {
        didSet {
            if checked {
                checkBox.setImage(checkedImage, for: UIControlState.normal)
            } else {
                checkBox.setImage(uncheckedImage, for: UIControlState.normal)
            }
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectItem(_:)))
            checkBox.addGestureRecognizer(tap)
        }
    }
    @IBOutlet weak var itemName: UILabel!
    
    @objc func selectItem(_ sender: UITapGestureRecognizer) {
        checked = !checked
        if checked {
            checkBox.setImage(checkedImage, for: UIControlState.normal)
        } else {
            checkBox.setImage(uncheckedImage, for: UIControlState.normal)
        }
    }

}

extension UIImage {
    func resizeImage(targetSize: CGSize) -> UIImage {
        let targetAspectRatio = targetSize.width / targetSize.height
        var croppingWidth = self.size.width
        var croppingHeight = self.size.height
        let currentAspectRatio = croppingWidth / croppingHeight
        var croppedImage: UIImage?
        
        if targetAspectRatio >= currentAspectRatio {
            // Desired width greater than height
            croppingHeight = croppingWidth/targetAspectRatio
            if let cgCroppedImage = self.cgImage?.cropping(to: CGRect(x: 0.0, y: (self.size.height - croppingHeight)/2.0, width: croppingWidth, height: croppingHeight)) {
                croppedImage = UIImage(cgImage: cgCroppedImage)
            }
        } else {
            croppingWidth = croppingHeight*targetAspectRatio
            if let cgCroppedImage = self.cgImage?.cropping(to: CGRect(x: (self.size.width - croppingWidth)/2.0, y: 0.0, width: croppingWidth, height: croppingHeight)) {
                croppedImage = UIImage(cgImage: cgCroppedImage)
            }
        }
        
        // Adapted from https://stackoverflow.com/questions/31314412/how-to-resize-image-in-swift
        let imageToStretch = croppedImage ?? self
        let size = imageToStretch.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0.0, y: 0.0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        imageToStretch.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
