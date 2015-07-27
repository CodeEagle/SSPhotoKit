//
//  SSPhotoGroupContentView.swift
//  SSPhotoKit
//
//  Created by LawLincoln on 15/7/24.
//  Copyright (c) 2015年 CocoaPods. All rights reserved.
//

import UIKit
import Photos
public class SSPhotoGroupContentView: UIView {
    
    private var group: PHAssetCollection?
    
    public func configWith(assetCollection: PHAssetCollection!) {
        group = assetCollection
        self.setNeedsDisplay()
    }
    
    override public func drawRect(rect: CGRect) {
        super.drawRect(rect)
        let ctx = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextFillRect(ctx, self.bounds)
        
        /// Image Left
        let len = Config.kGroupSize.width
        let imageRect = CGRectMake(0, 0, len, len)
        let padding: CGFloat = 10
        let assetsFetchResult = PHAsset.fetchAssetsInAssetCollection(group, options: nil)
        var images = [UIImage]()
        let acount = assetsFetchResult.count
        
        if acount > 3 {
            if let asset = assetsFetchResult[acount - 3] as? PHAsset {
                images.append(asset.image)
            }
        }
        if acount > 2 {
            if let asset = assetsFetchResult[acount - 2] as? PHAsset {
                images.append(asset.image)
            }
        }
        
        if let asset = assetsFetchResult.lastObject as? PHAsset {
            images.append(asset.image)
        }
        
        let offsetY: CGFloat = 2
        let factor: CGFloat = 0.8
        let left : CGFloat = (1 - factor)/2
        let top = (len - (Config.kGroupSize.width * factor + offsetY*(CGFloat(images.count ) - 1)))/2
        var lastImageRect = imageRect
        for (index,image) in enumerate(images) {
            
            let alen = Config.kGroupSize.width * (factor - CGFloat(images.count - index - 1)*left )
            let arect = CGRectMake((len - alen)/2, CGFloat(index)*offsetY + top, alen, alen)
            image.drawInRect(arect)
            lastImageRect = arect
        }
        
        let title = NSAttributedString.groupTitle(group?.localizedTitle)
        let next = NSAttributedString.groupTitle("\n")
        let count = NSAttributedString.groupItemCount(assetsFetchResult.count)
        let total = NSMutableAttributedString()
        let cellSize = self.bounds
        if let t = title, let n = next, let c = count {
            total.appendAttributedString(t)
            total.appendAttributedString(n)
            total.appendAttributedString(c)
            
            
            let width = cellSize.width - CGRectGetMaxX(imageRect) - padding*2
            let size = total.boundingRectWithSize(CGSizeMake(width, CGFloat.infinity), options: .UsesLineFragmentOrigin | .UsesFontLeading, context: nil)
            let y = (cellSize.height - size.height) / 2
            let rect = CGRectMake(CGRectGetMaxX(imageRect) + padding, y, width, size.height)
            total.drawWithRect(rect, options: .UsesLineFragmentOrigin | .UsesFontLeading, context: nil)
        }
        let bundle = NSBundle(forClass: SSPhotoKit.self)
        if let backArrow = UIImage(named: "back_normal", inBundle: bundle, compatibleWithTraitCollection: nil) {
            let scale = UIScreen.mainScreen().scale
            let infoArrow = UIImage(CGImage: backArrow.CGImage, scale: scale * 2, orientation: UIImageOrientation.Up)
            if let smaller = infoArrow?.imageRotatedByDegrees(180, flip: false) {
                let size = smaller.size
                let x = cellSize.width - size.width - padding
                let y = (cellSize.height - size.height) / 2
                let arect = CGRectMake(x, y, size.width, size.height)
                smaller.drawInRect(arect)
            }
            
        }
        
        if group?.assetCollectionSubtype == .SmartAlbumVideos {
            let asset = images.last
            let duration = asset?.duration
            let h: CGFloat = 20
            let text = "\(duration)"
            
            let height          = lastImageRect.size.height
            let width           = lastImageRect.size.width
            let startPoint      = CGPointMake(0, CGRectGetMidY(lastImageRect))
            let endPoint        = CGPointMake(0, CGRectGetMaxY(lastImageRect))
            
            let locations :[CGFloat] = [ 0.0, 0.75, 1 ]
            let colors: CFArray = [
                UIColor(red: 0, green: 0, blue: 0, alpha: 0).CGColor,
                UIColor(red: 0, green: 0, blue: 0, alpha: 0.8).CGColor,
                UIColor(red: 0, green: 0, blue: 0, alpha: 1).CGColor]
            let colorspace : CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()
            let gradient : CGGradientRef = CGGradientCreateWithColors(colorspace, colors, locations)
            CGContextAddRect(ctx, lastImageRect)
            CGContextClip(ctx)
            CGContextDrawLinearGradient(ctx, gradient,startPoint, endPoint, CGGradientDrawingOptions(kCGGradientDrawsBeforeStartLocation))
            
            let bundle = NSBundle(forClass: SSPhotoKit.self)
            if let image = UIImage(named: "AssetsPickerVideo", inBundle: bundle, compatibleWithTraitCollection: nil) {
                image.imageWithRenderingMode(.AlwaysTemplate)
                let rect = CGRect(
                    origin: CGPointMake(lastImageRect.origin.x + 4, height - image.size.height),
                    size: CGSizeMake(15, 8)
                )
                image.drawInRect(rect)
            }
            
            
        }
        
    }
    
}


