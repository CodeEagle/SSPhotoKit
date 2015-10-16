//
//  SSPhotoAssetsCollectionViewController.swift
//  Pods
//
//  Created by LawLincoln on 15/7/23.
//
//

import UIKit
import Photos

public class SSPhotoAssetsGroupController: UICollectionViewController {

    public lazy var assetsGroup: [PHAssetCollection]! = [PHAssetCollection]()
    public var indexPathsForSelectedItems: [PHAsset] {
        return _indexPathsForSelectedItems
    }
    
    private lazy var _indexPathsForSelectedItems: [PHAsset]! = [PHAsset]()
    
    public convenience init() {
        let layout = UICollectionViewFlowLayout()
        self.init(collectionViewLayout: layout)
    }
    
    override public init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(collectionViewLayout: layout)
        initialize()
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    deinit {
        collectionView?.delegate = nil
    }
    
    private func initialize() {
        collectionView?.backgroundColor = UIColor.whiteColor()
        self.preferredContentSize = Config.kPopoverContentSize
        loadPhotoGroup()
    }
    
    private func loadPhotoGroup() {
        
        if PHPhotoLibrary.authorizationStatus() == .Denied {
            let layer = SSPhotoForbbidenView()
            collectionView?.backgroundView = layer
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
//                let option = PHFetchOptions()
                let array: [PHAssetCollectionType] = [.SmartAlbum,.Album]
                /*
                case SmartAlbumGeneric
                case SmartAlbumPanoramas
                case SmartAlbumVideos
                case SmartAlbumFavorites
                case SmartAlbumTimelapses
                case SmartAlbumAllHidden
                case SmartAlbumRecentlyAdded
                case SmartAlbumBursts
                case SmartAlbumSlomoVideos
                case SmartAlbumUserLibrary
                */
                let subtype : [[PHAssetCollectionSubtype]] = [[.SmartAlbumUserLibrary,.SmartAlbumGeneric,.SmartAlbumPanoramas,.SmartAlbumFavorites,.SmartAlbumTimelapses,.SmartAlbumRecentlyAdded,.SmartAlbumBursts],[.AlbumRegular]]
                for (i,item) in array.enumerate() {
                    
                    for (_,asubType) in subtype[i].enumerate() {
                        let smartAlbums = PHAssetCollection.fetchAssetCollectionsWithType(item, subtype: asubType, options: nil)
                        
                        smartAlbums.enumerateObjectsUsingBlock({ (obj , index, stop) -> Void in
                            if let c = obj as? PHAssetCollection {
                                let assetsFetchResult = PHAsset.fetchAssetsInAssetCollection(c, options: nil)
                                if let _ = assetsFetchResult.firstObject as? PHAsset {
                                    self.assetsGroup.append(c)
                                }
                            }
                        })
                    }
                    
                    
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    collectionView?.reloadData()
                })
            })
        }
    }
    
}

// MARK: - set up
extension SSPhotoAssetsGroupController {
    private func setupViews() {
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.alwaysBounceVertical = true
        collectionView?.registerClass(SSPhotoGroupCollectionViewCell.self, forCellWithReuseIdentifier: SSPhotoGroupCollectionViewCell.idf)
        self.title = NSLocalizedString("相簿", comment:"")
    }
    
}

extension SSPhotoAssetsGroupController: UICollectionViewDelegateFlowLayout {
    //MARK: UICollectionViewDataSource
    
    override public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assetsGroup.count
    }
    
    override public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(SSPhotoGroupCollectionViewCell.idf, forIndexPath: indexPath) as! SSPhotoGroupCollectionViewCell
        cell.configWith(assetsGroup[indexPath.item])
        return cell
    }
    
    //MARK: UICollectionViewDelegate
    
    override public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let detail = SSPhotoGroupDetailViewController()
        let group = assetsGroup[indexPath.item]
        detail.config(group)
        self.navigationController?.pushViewController(detail, animated: true)
    }
    
    override public func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    
    // MARK: - UICollectionViewDelegateFlowLayout
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0.5
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(UIScreen.mainScreen().bounds.width, Config.kGroupSize.width)
    }
    
}


// MARK: - Tips Layer
public class SSPhotoForbbidenView: UIView {
    
    
    public override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        let ctx = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(ctx, UIColor.lightGrayColor().CGColor)
        CGContextFillRect(ctx, self.bounds)
        
        var ay: CGFloat = 0
        let bundle = NSBundle(forClass: SSPhotoKit.self)
        if let lock = UIImage(named: "AssetsPickerLocked", inBundle: bundle, compatibleWithTraitCollection: nil) {
            let image = lock.toTintColor(UIColor.darkGrayColor())
            let x = ( layer.bounds.width - lock.size.width ) / 2
            let y = ( layer.bounds.height - lock.size.height ) / 2 - 40
            image.drawAtPoint(CGPointMake(x, y))
            ay = lock.size.height + y
        }
        
        let tips = "此应用无法使用您的照片或视频\n你可以在「隐私设置」中启用存取"
        let paragrah = NSMutableParagraphStyle()
        paragrah.alignment = .Center
        let attribute = [
            NSForegroundColorAttributeName: UIColor.darkGrayColor(),
            NSFontAttributeName : UIFont.boldSystemFontOfSize(16),
            NSParagraphStyleAttributeName : paragrah
        ]
        let attr = NSAttributedString(string: NSLocalizedString(tips, comment: ""), attributes: attribute)
        let rect = CGRectMake(20, ay + 20, layer.bounds.width - 40, 100)
        attr.drawWithRect(rect, options: [.UsesLineFragmentOrigin, .UsesLineFragmentOrigin], context: nil)
    }
}



