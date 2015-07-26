//
//  SSPhotoGroupCollectionViewCell.swift
//  Pods
//
//  Created by LawLincoln on 15/7/23.
//
//

import UIKit
import Photos
public class SSPhotoGroupCollectionViewCell: UICollectionViewCell {
    static let idf = "SSPhotoGroupCollectionViewCell"
    
    private lazy var content: SSPhotoGroupContentView! = self.gContent()
    
    public func configWith(assetCollection: PHAssetCollection!) {
        content.configWith(assetCollection)
    }
    
    private func gContent() -> SSPhotoGroupContentView {
        let c = SSPhotoGroupContentView(frame: self.bounds)
        self.contentView.addSubview(c)
        return c
    }
}
