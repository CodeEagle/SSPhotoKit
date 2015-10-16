//
//  GroupDetailCollectionViewCell.swift
//  SSPhotoKit
//
//  Created by LawLincoln on 15/7/24.
//  Copyright (c) 2015年 CocoaPods. All rights reserved.
//

import UIKit
import Photos
public class GroupDetailCollectionViewCell: UICollectionViewCell {
    static let idf = "GroupDetailCollectionViewCell"
    
    private var asset: PHAsset!
    public var aSelected: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    private var stop: Bool = false
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        stop = true
    }
    public func configWith(aAsset: PHAsset,_selected: Bool!) {
        asset = aAsset
        if let b = _selected {
            aSelected = b
        } else {
            aSelected = false
        }
        stop = false
        setNeedsDisplay()
    }
    
    override public func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        if stop {
            return
        }
        /// Image
        let len = Config.kThumbnailLength
        let imageRect = CGRectMake(0, 0, len, len)
//        let padding: CGFloat = 10
        
        let image = asset.image
        if stop {
            return
        }
        image.drawInRect(imageRect)
        
        
        
        /// CheckMark
        var checkMark = "photo_check_default"

        if aSelected {
            checkMark = "photo_check_selected"
        }
        let bundle = NSBundle(forClass: SSPhotoKit.self)
        if let checkMarkIcon = UIImage(named: checkMark, inBundle: bundle, compatibleWithTraitCollection: nil) {
            let size = self.bounds.size
            let imgSize = checkMarkIcon.size
            let x = size.width - imgSize.width - 2
            let y: CGFloat = 2
            let rect = CGRectMake(x, y, imgSize.width, imgSize.height)
            if stop {
                return
            }
            checkMarkIcon.drawInRect(rect)
        }
    }
}
