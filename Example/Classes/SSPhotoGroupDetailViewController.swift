//
//  SSPhotoGroupDetailViewController.swift
//  SSPhotoKit
//
//  Created by LawLincoln on 15/7/24.
//  Copyright (c) 2015年 CocoaPods. All rights reserved.
//

import UIKit
import Photos
import SSImageBrowser
public class SSPhotoGroupDetailViewController: UIViewController {

    private var group: PHAssetCollection? {
        didSet {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                let option = PHFetchOptions()
                option.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.Image.rawValue)
                self.result = PHAsset.fetchAssetsInAssetCollection(self.group!, options: option)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.collectionView.reloadData()
                })
            })
        }
    }
    private lazy var queue = NSOperationQueue()
    private var result: PHFetchResult!
    private lazy var collectionView: UICollectionView! = self.gCollectionView()
    private lazy var toolBar: UIToolbar! = self.gToolBar()
    private var selectedButton: UIButton!
    
    private lazy var selectedMap = [String:Bool]()
    private lazy var selectedAssets = [PHAsset]()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        view.addSubview(toolBar)
        if SSPhotoKit.shared.showCancelButton {
            let title = NSLocalizedString("取消", comment:"")
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: title, style: .Plain, target: self, action: #selector(dismiss))
        }
        
        // Do any additional setup after loading the view.
    }
    
    
    
    func dismiss() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public func config(aGroup: PHAssetCollection) {
        group = aGroup
        self.navigationItem.title = aGroup.localizedTitle
    }

}
// MARK: - UI
extension SSPhotoGroupDetailViewController {
    private func gCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = UIColor.whiteColor()
        cv.registerClass(ASDisplayCollectionViewCell.self, forCellWithReuseIdentifier: ASDisplayCollectionViewCell.idf)
        cv.alwaysBounceVertical = true
        cv.contentInset = UIEdgeInsetsMake(0, 0, 44, 0)
        return cv
    }
    
    private func gToolBar() -> UIToolbar {
        let size = view.bounds.size
        let h: CGFloat = 44
        let tool = UIToolbar(frame: CGRectMake(0, size.height - h, size.width, h))
        tool.translucent = true
        tool.items = toolBarItems()
        return tool
    }
    
    private func toolBarItems() -> [UIBarButtonItem] {
        let preview = UIBarButtonItem(title: NSLocalizedString("预览", comment: ""), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(SSPhotoGroupDetailViewController.preview))
        let fixed = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        fixed.width = 20
        let flex = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let button = UIButton(frame: CGRectMake(0, 0, 90, 50))
        button.setTitle(NSLocalizedString("选择", comment: ""), forState: .Normal)
        button.addTarget(self, action: #selector(SSPhotoGroupDetailViewController.done), forControlEvents: UIControlEvents.TouchUpInside)
        button.setTitleColor(view.tintColor, forState: .Normal)
        button.setTitleColor(UIColor.lightGrayColor(), forState: .Highlighted)
        selectedButton = button
        let done = UIBarButtonItem(customView: button)
        return [fixed,preview,flex,done]
    }
}
// MARK: - Event Response
extension SSPhotoGroupDetailViewController {
    func preview() {
        let photos = SSPhoto.photosWithAssets(selectedAssets)
        let browser = SSImageBrowser(aPhotos: photos)
        self.showViewController(browser, sender: nil)
        browser.disableVerticalSwipe = true
        browser.displayDoneButton = false
    }
    
    func done() {
        SSPhotoKit.shared.selectdDone(selectedAssets)
        dismiss()
    }
}
extension SSPhotoGroupDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    //MARK: UICollectionViewDataSource
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = result?.count
        if count == nil {
            count = 0
        }
        return count!
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ASDisplayCollectionViewCell.idf, forIndexPath: indexPath) as! ASDisplayCollectionViewCell
        let asset = result[indexPath.item] as! PHAsset
        let key = asset.identifier
        var value = false
        if let b = selectedMap[key] {
            value = b
        }
        cell.configureCellDisplayWithCardInfo(asset, selected: value,nodeConstructionQueue: queue)

        return cell
    }
    
    
    
    //MARK: UICollectionViewDelegate
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let max = SSPhotoKit.shared.maximumNumberOfSelection
        
        let asset = result[indexPath.item] as! PHAsset
        let key = asset.identifier
        var value = false
        if let b = selectedMap[key] {
            value = !b
        } else {
            value = true
        }
        if value {
            if selectedAssets.count >= max {
                return
            }
            selectedAssets.append(asset)
        } else {
            if let index = selectedAssets.indexOf(asset) {
                selectedAssets.removeAtIndex(index)
            }
        }
        selectedMap[key] = value
        
        
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ASDisplayCollectionViewCell
        cell.bSelected = value
        
        let prefix = NSLocalizedString("选择", comment: "")
        
        var selectedCount = 0
        for (_,value) in selectedMap{
            if value {
                selectedCount += 1
            }
        }
        var title = prefix+"(\(selectedCount))"
        if selectedCount == 0 {
            title = prefix
        }
        selectedButton.setTitle(title, forState: .Normal)
    }
    
    public func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(1, 2, 0, 2)
    }
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return Config.kThumbnailSize
    }
}


