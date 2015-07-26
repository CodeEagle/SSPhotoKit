//
//  ExNSAttributeString.swift
//  Pods
//
//  Created by LawLincoln on 15/7/24.
//
//
import UIKit

extension NSAttributedString {
    class func groupTitle(title: String?) -> NSAttributedString? {
        if title == nil {
            return nil
        }
        let attribute = [
            NSForegroundColorAttributeName : UIColor.blackColor(),
            NSFontAttributeName : UIFont.boldSystemFontOfSize(15)
        ]
        let item = NSAttributedString(string: title!, attributes: attribute)
        return item
    }
    
    class func groupItemCount(count: Int?) -> NSAttributedString? {
        if count == nil {
            return nil
        }
        let attribute = [
            NSForegroundColorAttributeName : UIColor.blackColor(),
            NSFontAttributeName : UIFont.systemFontOfSize(12)
        ]
        let item = NSAttributedString(string: "\(count!)", attributes: attribute)
        return item
    }
}