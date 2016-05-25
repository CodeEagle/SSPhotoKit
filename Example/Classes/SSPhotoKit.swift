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
    
    static private var _shared: SSPhotoKit!
    
    class public var shared: SSPhotoKit {
        if _shared == nil {
            _shared = SSPhotoKit()
        }
        return _shared
    }
    
    class func clear() {
        _shared = nil
    }
    
    deinit {
        debugPrint("deinit SSPhotoKit")
    }
    
    override private init() {
        super.init()
    }
    
    public var cameraShooter: UIImagePickerController!
    public var maximumNumberOfSelection: Int = 10
    public lazy var showCancelButton: Bool = true
    public var photoPicker: SSPhotoAssetController!
    public weak var delegate: SSPhotoKitDelegate?
    private weak var aViewController: UIViewController!
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
    
    public func selectdDone(objs: [AnyObject]) {
        completeSelection?(objs)
        delegate?.photoKit(self, didFinishSelected: objs)
    }
}
// MARK: - Private
private extension SSPhotoKit {
    
    func configurePhotoPreviewSheet() {
        let controller = ImagePickerSheetController(mediaType: .Image)
        controller.view.tintColor = UIColor(red:0.231,  green:0.675,  blue:0.224, alpha:1)

        controller.maximumSelection = maximumNumberOfSelection
        controller.addAction(ImagePickerAction(title: NSLocalizedString("照片图库", comment: ""), secondaryTitle: { NSString.localizedStringWithFormat(NSLocalizedString("选择%lu张", comment: ""), $0) as String }, handler: {[weak self] _ in
            self?.presentImagePickerController(.PhotoLibrary)
            }, secondaryHandler: {[weak self] _, numberOfPhotos in
                self?.selectdDone(controller.selectedImageAssets)
                SSPhotoKit.clear()
        }))
        
        controller.addAction(ImagePickerAction(title: NSLocalizedString("拍照", comment: ""), handler: {[weak self]  _ in
            self?.presentImagePickerController(.Camera)
        }))
        
        controller.addAction(ImagePickerAction(title: NSLocalizedString("取消", comment: ""), style: .Cancel, handler: {[weak self]  _ in
            if let sself = self {
                sself.delegate?.photoKitDidCancel(sself)
                SSPhotoKit.clear()
            }
        }))
        
        aViewController.presentViewController(controller, animated: true, completion: nil)
        
    }
    
    func configureCameraShooter(camera: UIImagePickerController!) {
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
    
    func presentImagePickerController(var sourceType: UIImagePickerControllerSourceType) {
        if (!UIImagePickerController.isSourceTypeAvailable(sourceType)) {
            sourceType = .PhotoLibrary
        }
        if sourceType == .PhotoLibrary {
            photoPicker = SSPhotoAssetController()
            aViewController.presentViewController(photoPicker, animated: true, completion: nil)
            return
        }
        aViewController.presentViewController(cameraShooter, animated: true, completion: nil)
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





 