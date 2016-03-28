//
//  SSPhotoKit.swift
//  Pods
//
//  Created by LawLincoln on 15/7/23.
//
//

import UIKit
import Photos
import AVFoundation
import ImagePickerSheetController

public protocol SSPhotoKitDelegate: class {
    func photoKit(photoKit: SSPhotoKit, didFinishSelected: [AnyObject])
    func photoKitDidCancel(photoKit: SSPhotoKit)
}
public struct Config {
    static let kGroupSize = CGSizeMake(80, 80)
    static let kThumbnailLength = (UIScreen.mainScreen().bounds.size.width - 8) / 4
    static let kThumbnailSize = CGSizeMake(Config.kThumbnailLength, Config.kThumbnailLength)
    static let kPopoverContentSize = CGSizeMake(320, 480)
    static let insetsTop: CGFloat = 2
}
public class SSPhotoKit: NSObject {
    
    static var shared: SSPhotoKit!
    
    public var cameraShooter: UIImagePickerController!
    public var maximumNumberOfSelection: Int = 10
    public lazy var showCancelButton: Bool = true
    public var photoPicker: SSPhotoAssetController!
    public weak var delegate: SSPhotoKitDelegate?
    private var aViewController: UIViewController!
    private var completeSelection:(([AnyObject])->())!
    public func showPickerIn(viewController: UIViewController,done: ([AnyObject])->()) {
        showPickerIn(viewController, cameraConfig: nil, done: done)
    }
    
    public func showPickerIn(viewController: UIViewController, cameraConfig camera: UIImagePickerController!, done: ([AnyObject])->()) {
        aViewController = viewController
        configureCameraShooter(camera)
        configurePhotoPreviewSheet()
        completeSelection = done
    }
    
    
    override public init() {
        super.init()
        SSPhotoKit.shared = self
    }
}

extension SSPhotoKit {
    
    
    private func configurePhotoPreviewSheet() {
        let controller = ImagePickerSheetController(mediaType: .Image)
        weak var wself: SSPhotoKit! = self
        controller.maximumSelection = maximumNumberOfSelection
        controller.addAction(ImagePickerAction(title: NSLocalizedString("照片图库", comment: ""), secondaryTitle: { NSString.localizedStringWithFormat(NSLocalizedString("选择%lu张", comment: ""), $0) as String }, handler: { _ in
            wself?.presentImagePickerController(.PhotoLibrary)
            }, secondaryHandler: { _, numberOfPhotos in
                wself?.selectdDone(controller.selectedImageAssets)
        }))
        
        controller.addAction(ImagePickerAction(title: NSLocalizedString("拍照", comment: ""), handler: { _ in
            wself?.presentImagePickerController(.Camera)
        }))
        
        controller.addAction(ImagePickerAction(title: NSLocalizedString("取消", comment: ""), style: .Cancel, handler: { _ in
            wself?.delegate?.photoKitDidCancel(wself)
        }))
        
        aViewController.presentViewController(controller, animated: true, completion: nil)
        
    }
    
    private func configureCameraShooter(camera: UIImagePickerController!) {
        if let aCamera = camera {
            cameraShooter = aCamera
        }else{
            cameraShooter = UIImagePickerController()
        }
        let isCamera = UIImagePickerController.isSourceTypeAvailable(.Camera)
        var sourceType: UIImagePickerControllerSourceType = .PhotoLibrary
        if isCamera {
            sourceType = .Camera
        }
        cameraShooter.sourceType = sourceType
        
        let isDenied = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) == .Denied
        if isDenied && isCamera {
            let views = SSPhotoForbbidenView()
            var rect = CGRectInset(cameraShooter.view.bounds, 0, 60)
            rect.offsetInPlace(dx: 0, dy: -20)
            views.frame = rect
            cameraShooter.cameraOverlayView = views
        }
        
        cameraShooter.delegate = self
        
    }
    

    private func presentImagePickerController(sourceType: UIImagePickerControllerSourceType) {
        if (!UIImagePickerController.isSourceTypeAvailable(sourceType)) {
            let alertController =  UIAlertController(title: NSLocalizedString("提示", comment: ""), message: NSLocalizedString("不支持此功能", comment: ""), preferredStyle: .Alert)
            let confirmAction = UIAlertAction(title: NSLocalizedString("确定", comment: ""), style: .Default, handler: nil)
            alertController.addAction(confirmAction)
            aViewController.presentViewController(alertController, animated: true, completion: nil)
            return
        }
        
        if sourceType == .PhotoLibrary {
            photoPicker = SSPhotoAssetController()
            aViewController.presentViewController(photoPicker, animated: true, completion: nil)
        }
        else {
            aViewController.presentViewController(cameraShooter, animated: true, completion: nil)
        }
    }
    
    
    public func selectdDone(objs: [AnyObject]) {
        completeSelection?(objs)
        delegate?.photoKit(self, didFinishSelected: objs)
    }
}

private typealias CameraPhotoInfo = [NSObject : AnyObject]

// MARK: - UIImagePickerControllerDelegate
extension SSPhotoKit: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    ///拍照返回
    public func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        selectdDone([info])
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    public func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        delegate?.photoKitDidCancel(self)
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
}





 