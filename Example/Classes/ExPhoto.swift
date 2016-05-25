//
//  ExPhoto.swift
//  SSPhotoKit
//
//  Created by LawLincoln on 15/7/24.
//  Copyright (c) 2015年 CocoaPods. All rights reserved.
//

import UIKit
import Photos

extension PHAsset {
	var image: UIImage! {

		let cache = NSURLCache.sharedURLCache()
		let key = "https://\(identifier)"
		let url = NSURL(string: key)!
		let request = NSURLRequest(URL: url)
		if let data = cache.cachedResponseForRequest(request)?.data, img = UIImage(data: data) {
			return img
		}

		let manager = PHImageManager.defaultManager()
		let option = PHImageRequestOptions()
		var thumbnail: UIImage! = UIImage()

		let scale = UIScreen.mainScreen().scale
		var asize = Config.kGroupSize
		asize.width *= scale
		asize.height *= scale
		option.synchronous = true
		option.normalizedCropRect = CGRect(origin: CGPointZero, size: asize)
		option.resizeMode = .Exact
		manager.requestImageForAsset(self, targetSize: asize, contentMode: .AspectFill, options: option, resultHandler: { (result, info) -> Void in
			if let img = result {
				thumbnail = img
				if let data = UIImageJPEGRepresentation(img, 1) {
					let resp = NSURLResponse(URL: url, MIMEType: nil, expectedContentLength: 0, textEncodingName: nil)
					cache.storeCachedResponse(NSCachedURLResponse(response: resp, data: data), forRequest: request)
				}
			}
		})

		return thumbnail
	}

	var identifier: String {
		return self.localIdentifier// .pathComponents[0]
	}

	func imageWithSize(size: CGSize, done: (UIImage) -> ()) {
		let cache = NSURLCache.sharedURLCache()
		let key = "https://" + identifier + "-original"
		let url = NSURL(string: key)!
		let request = NSURLRequest(URL: url)
		if let data = cache.cachedResponseForRequest(request)?.data, img = UIImage(data: data) {
			done(img)
		}

		let manager = PHImageManager.defaultManager()
		let option = PHImageRequestOptions()
		option.synchronous = false
		option.networkAccessAllowed = true
		option.normalizedCropRect = CGRect(origin: CGPointZero, size: size)
		option.resizeMode = .Exact
		option.progressHandler = {
			(progress, error, stop, info) -> Void in
			print(progress, terminator: "")
			print(info, terminator: "")
		}

		manager.requestImageForAsset(self, targetSize: size, contentMode: .AspectFill, options: option, resultHandler: { (result, info) -> Void in
			if let img = result {
				if let data = UIImageJPEGRepresentation(img, 1) {
					let resp = NSURLResponse(URL: url, MIMEType: nil, expectedContentLength: 0, textEncodingName: nil)
					cache.storeCachedResponse(NSCachedURLResponse(response: resp, data: data), forRequest: request)
				}
				done(img)
			}
		})

	}

}

extension UIImage {

	public func imageRotatedByDegrees(degrees: CGFloat, flip: Bool) -> UIImage {
//        let radiansToDegrees: (CGFloat) -> CGFloat = {
//            return $0 * (180.0 / CGFloat(M_PI))
//        }
		let degreesToRadians: (CGFloat) -> CGFloat = {
			return $0 / 180.0 * CGFloat(M_PI)
		}

		// calculate the size of the rotated view's containing box for our drawing space
		let rotatedViewBox = UIView(frame: CGRect(origin: CGPointZero, size: size))
		let t = CGAffineTransformMakeRotation(degreesToRadians(degrees));
		rotatedViewBox.transform = t
		let rotatedSize = rotatedViewBox.frame.size

		// Create the bitmap context
		UIGraphicsBeginImageContext(rotatedSize)
		let bitmap = UIGraphicsGetCurrentContext()

		// Move the origin to the middle of the image so we will rotate and scale around the center.
		CGContextTranslateCTM(bitmap, rotatedSize.width / 2.0, rotatedSize.height / 2.0);

		// // Rotate the image context
		CGContextRotateCTM(bitmap, degreesToRadians(degrees));

		// Now, draw the rotated/scaled image into the context
		var yFlip: CGFloat

		if (flip) {
			yFlip = CGFloat(-1.0)
		} else {
			yFlip = CGFloat(1.0)
		}

		CGContextScaleCTM(bitmap, yFlip, -1.0)
		CGContextDrawImage(bitmap, CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height), CGImage)

		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return newImage
	}

	public func toTintColor(color: UIColor) -> UIImage! {
		UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)
		color.setFill()
		let bounds = CGRectMake(0, 0, self.size.width, self.size.height)
		UIRectFill(bounds)
		self.drawInRect(bounds, blendMode: CGBlendMode.DestinationIn, alpha: 1.0)
		let tintedImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext()
		return tintedImage
	}

}