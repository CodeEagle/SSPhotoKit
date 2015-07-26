//
//  ASdiplayCollectionViewCell.swift
//  Luxuryker
//
//  Created by LawLincoln on 15/7/8.
//  Copyright (c) 2015年 LawLincoln. All rights reserved.
//

import UIKit
import AsyncDisplayKit
import Photos

public class ASDisplayCollectionViewCell: UICollectionViewCell {
    static let idf = "ASDisplayCollectionViewCell"
    private var contentNode: ASDisplayNode!
    private var contentNodeObj: CALayer!
    
    private var placeholder: CALayer!
    private var nodeConstructionOperation: NSOperation?
    private var off: UIImage! = UIImage(named: "photo_check_default")
    private var on: UIImage! = UIImage(named: "photo_check_selected")
    public var bSelected: Bool = false {
        didSet {
            var img = off
            if bSelected {
                img = on
            }
            checkMark.image = img
        }
    }

    
    private var checkMark: UIImageView!

    public init() {
        super.init(frame: CGRectZero)
        initialize()
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        if let operation = nodeConstructionOperation {
            operation.cancel()
        }
        clear()

    }
    
    func clear() {

        contentNode?.recursivelySetDisplaySuspended(true)
        contentNodeObj?.removeFromSuperlayer()
        contentNodeObj = nil
        contentNode = nil
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        placeholder?.frame = self.contentView.bounds
        CATransaction.commit()
    }
    
    public func initialize() {
        self.layer.cornerRadius = 1
        self.layer.masksToBounds = true
        self.contentView.clipsToBounds = true
        placeholder = CALayer()
        placeholder.frame = self.contentView.bounds
        placeholder.contentsGravity = kCAGravityCenter
        placeholder.contentsScale = UIScreen.mainScreen().scale
        placeholder.backgroundColor = UIColor.whiteColor().CGColor
        contentView.layer.addSublayer(placeholder)
        
        
        checkMark = UIImageView(image: UIImage(named: "photo_check_default"))
        let size = self.bounds.size
        let imgSize = checkMark.bounds.size
        let x = size.width - imgSize.width - 2
        let y: CGFloat = 2
        let rect = CGRectMake(x, y, imgSize.width, imgSize.height)
        checkMark.frame = rect
        contentView.addSubview(checkMark)
        
    }
}

extension ASDisplayCollectionViewCell {
    public func configureCellDisplayWithCardInfo(item: PHAsset, selected b: Bool, nodeConstructionQueue: NSOperationQueue)  {
        if let oldNodeConstructionOperation = nodeConstructionOperation {
            oldNodeConstructionOperation.cancel()
        }
        nodeConstructionOperation = nodeConstructionOperationWithCardInfo(item,aSelected: b)
        nodeConstructionQueue.addOperation(nodeConstructionOperation!)
    }
    
    func nodeConstructionOperationWithCardInfo(asset: PHAsset,aSelected: Bool) -> NSOperation {
        let nodeConstructionOperation = NSBlockOperation()
        nodeConstructionOperation.addExecutionBlock {
            [weak self, unowned nodeConstructionOperation] in
            
            if nodeConstructionOperation.cancelled {
                return
            }
            if let strongSelf = self {
                
                var containerNode: ASDisplayNode!  = ASDisplayNode()
                containerNode.layerBacked = true
                containerNode.shouldRasterizeDescendants = true
                containerNode.frame = strongSelf.bounds
                
                let img = ASImageNode()

                let len = Config.kThumbnailLength
                let imageRect = CGRectMake(0, 0, len, len)
                let padding: CGFloat = 10
                img.image = asset.image
                img.layerBacked = true
                img.frame = imageRect
                containerNode.addSubnode(img)
                
                if asset.mediaType == .Video {
                    let bg = ASDisplayNode()
                    bg.layerBacked = true
                    bg.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
                    bg.frame = CGRectMake(0, len/3*2, len, len/3)
                    containerNode.addSubnode(bg)
                    
                    let bundle = NSBundle(forClass: SSPhotoKit.self)
                    var aimageRect: CGRect!
                    if let image = UIImage(named: "AssetsPickerVideo", inBundle: bundle, compatibleWithTraitCollection: nil) {
                        image.imageWithRenderingMode(.AlwaysTemplate)
                        aimageRect = CGRect(
                            origin: CGPointMake(imageRect.origin.x + 4, (len/3 - image.size.height)/2 + len/3*2),
                            size: CGSizeMake(15, 8)
                        )
                        let video = ASImageNode()
                        video.layerBacked = true
                        video.frame = aimageRect
                        video.image = image
                        containerNode.addSubnode(video)
                    }
                    
                    let duration = ASTextNode()
                    let font = UIFont.systemFontOfSize(12)
                    let width = len - CGRectGetMaxX(aimageRect) - 6
                    duration.frame = CGRectMake(CGRectGetMaxX(aimageRect), len/3*2 + (len/3 - font.lineHeight)/2, width, len/3)
                    duration.layerBacked = true
                    let paragraph = NSMutableParagraphStyle()
                    paragraph.alignment = .Right
                    let attribute = [
                        NSForegroundColorAttributeName : UIColor.whiteColor(),
                        NSFontAttributeName : font,
                        NSParagraphStyleAttributeName: paragraph
                    ]
                    let text = NSDate.timeDescriptionOfTimeInterval(asset.duration)
                    duration.attributedString = NSAttributedString(string: text, attributes: attribute)
                    containerNode.addSubnode(duration)
                }
                
//                if group?.assetCollectionSubtype == .SmartAlbumVideos {
//                    let asset = images.last
//                    let duration = asset?.duration
//                    let h: CGFloat = 20
//                    let text = "\(duration)"
//                    
//                    let height          = lastImageRect.size.height
//                    let width           = lastImageRect.size.width
//                    let startPoint      = CGPointMake(0, CGRectGetMidY(lastImageRect))
//                    let endPoint        = CGPointMake(0, CGRectGetMaxY(lastImageRect))
//                    
//                    let locations :[CGFloat] = [ 0.0, 0.75, 1 ]
//                    let colors: CFArray = [
//                        UIColor(red: 0, green: 0, blue: 0, alpha: 0).CGColor,
//                        UIColor(red: 0, green: 0, blue: 0, alpha: 0.8).CGColor,
//                        UIColor(red: 0, green: 0, blue: 0, alpha: 1).CGColor]
//                    let colorspace : CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()
//                    let gradient : CGGradientRef = CGGradientCreateWithColors(colorspace, colors, locations)
//                    CGContextAddRect(ctx, lastImageRect)
//                    CGContextClip(ctx)
//                    CGContextDrawLinearGradient(ctx, gradient,startPoint, endPoint, CGGradientDrawingOptions(kCGGradientDrawsBeforeStartLocation))
                
                    //            let nsText = text as NSString
                    //            let font = UIFont.systemFontOfSize(12)
                    //            let aSize = CGSizeMake(Config.kThumbnailLength, Config.kThumbnailLength)
                    
                    //            UIColor.blackColor().set()
                    //            var pragrah = NSMutableParagraphStyle()
                    //            pragrah.lineBreakMode = .ByTruncatingTail
                    //            let aFont = UIFont(descriptor: font.fontDescriptor(), size: 12)
                    //            let attribute = [
                    //                NSFontAttributeName : aFont,
                    //                NSBaselineOffsetAttributeName : 1.0,
                    //                NSParagraphStyleAttributeName : pragrah
                    //            ]
                    //            let attributeString = NSAttributedString(string: text, attributes: attribute)
                    //            let titleSize        = attributeString.boundingRectWithSize(aSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)
                    
                    //            attributeString.drawInRect(CGRectMake(lastImageRect.size.width - titleSize.width - 2 , (height - 12) / 2, Config.kThumbnailLength, titleSize.height))
                    
                    
                    
                    
//                }
                
                
                if nodeConstructionOperation.cancelled {
                    return
                }
                
                dispatch_async(dispatch_get_main_queue()) { [weak nodeConstructionOperation] in
                    if let strongNodeConstructionOperation = nodeConstructionOperation {
                        if strongNodeConstructionOperation.cancelled {
                            return
                        }
                        if strongSelf.nodeConstructionOperation !== strongNodeConstructionOperation {
                            return
                        }
                        if containerNode.displaySuspended {
                            return
                        }
                        
                        strongSelf.bSelected = aSelected
                        strongSelf.contentView.layer.insertSublayer(containerNode.layer, above: strongSelf.placeholder)
                        strongSelf.contentNodeObj = containerNode.layer
                        strongSelf.contentNode = containerNode
                    }
                }
            }
        }
        return nodeConstructionOperation
    }
    
}
extension CALayer {
    func fadeIn(){
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 0.2
        self.addAnimation(animation, forKey: "opacity")
    }
}