//
//  SSPhotoAssetsPickerViewController.swift
//  Pods
//
//  Created by LawLincoln on 15/7/23.
//
//

import Foundation
import Photos
/// SSPhotoAssetsPickerDelegate
@objc public protocol SSPhotoAssetDelegate: class {
    func photoAssetPicker(picker: SSPhotoAssetController, didFinishPicking: [PHAsset])
    
    optional func photoAssetPicker(picker: SSPhotoAssetController, didSelectAsset: PHAsset)
    optional func photoAssetPicker(picker: SSPhotoAssetController, didDeselectAsset: PHAsset)
    optional func photoAssetPickerDidCancel(picker: SSPhotoAssetController)
    optional func photoAssetPickerDidMaximum(picker: SSPhotoAssetController)
    optional func photoAssetPickerDidMinimum(picker: SSPhotoAssetController)
}

/// SSPhotoAssetController
public class SSPhotoAssetController: UINavigationController {
    public weak var assetDelegate: SSPhotoAssetDelegate?
    public lazy var maximumNumberOfSelection: Int = 10
    public lazy var minimumNumberOfSelection: Int = 0
    public lazy var selectionFilter: NSPredicate = NSPredicate(value: true)
    public lazy var showEmptyGroups: Bool = false
    public lazy var isFinishDismissViewController: Bool = true
    
    public var indexPathsForSelectedItems: [PHAsset] {
        return _indexPathsForSelectedItems
    }
    
    private lazy var _indexPathsForSelectedItems: [PHAsset]! = [PHAsset]()
    
    public convenience init() {
        let collectionView = SSPhotoAssetsGroupController()
        self.init(rootViewController: collectionView)
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override public init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        initialize()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    func initialize() {
        self.preferredContentSize = Config.kPopoverContentSize
        
        if SSPhotoKit.shared.showCancelButton {
            let title = NSLocalizedString("取消", comment:"")
            self.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(title: title, style: .Plain, target: self, action: Selector("dismiss"))
        }
    }
    
    func dismiss() {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            SSPhotoKit.clear()
        })
    }
    
}







