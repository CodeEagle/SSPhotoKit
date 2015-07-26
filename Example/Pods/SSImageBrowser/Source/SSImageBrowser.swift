//
//  SSImageBrowser.swift
//  Pods
//
//  Created by LawLincoln on 15/7/10.
//
//

import UIKit
import pop
// MARK: - SSImageBrowserDelegate
public protocol SSImageBrowserDelegate: class {

    func photoBrowser(photoBrowser:SSImageBrowser, didShowPhotoAtIndex index:Int)
    func photoBrowser(photoBrowser:SSImageBrowser, didDismissAtPageIndex index:Int)
    func photoBrowser(photoBrowser:SSImageBrowser, willDismissAtPageIndex index:Int)
    func photoBrowser(photoBrowser:SSImageBrowser, captionViewForPhotoAtIndex index:Int)->SSCaptionView!
    func photoBrowser(photoBrowser:SSImageBrowser, didDismissActionSheetWithButtonIndex index:Int, photoIndex:Int)
}
// MARK: - SSImageBrowser
public class SSImageBrowser: UIViewController {
    
    // MARK: - public
    public weak var delegate: SSImageBrowserDelegate!
    public lazy var displayToolbar                   = true
    public lazy var displayCounterLabel              = true
    public lazy var displayArrowButton               = true
    public lazy var displayActionButton              = true
    public lazy var displayDoneButton                = true
    public lazy var useWhiteBackgroundColor          = false
    public lazy var arrowButtonsChangePhotosAnimated = true
    public lazy var forceHideStatusBar               = false
    public lazy var usePopAnimation                  = true
    public lazy var disableVerticalSwipe             = false
    
    public lazy var actionButtonTitles  = [String]()
    
    public weak var leftArrowImage: UIImage!
    public weak var leftArrowSelectedImage: UIImage!
    public weak var rightArrowImage: UIImage!
    public weak var rightArrowSelectedImage: UIImage!
    public weak var doneButtonImage: UIImage!
    public weak var scaleImage: UIImage!
    
    public weak var trackTintColor: UIColor!
    public weak var progressTintColor: UIColor!
    
    public lazy var backgroundScaleFactor: CGFloat = 1
    public lazy var animationDuration: CGFloat = 0.28
    
    // MARK: - Private
    private lazy var photos: [SSPhoto]!                          = [SSPhoto]()
    private lazy var pagingScrollView: UIScrollView              = UIScrollView()
    private lazy var pageIndexBeforeRotation: UInt               = 0
    private lazy var currentPageIndex: Int                       = 0
    private lazy var initalPageIndex: Int                        = 0
    private var statusBarOriginallyHidden: Bool                  = false
    private var performingLayout: Bool                           = false
    private var rotating: Bool                                   = false
    private var viewIsActive: Bool                               = false
    private var autoHide: Bool                                   = true
    private var isdraggingPhoto: Bool                            = false
    private lazy var visiblePages: Set<SSZoomingScrollView>!  = Set<SSZoomingScrollView>()
    private lazy var recycledPages: Set<SSZoomingScrollView>! = Set<SSZoomingScrollView>()
    
    private var panGesture: UIPanGestureRecognizer!
    
    private var doneButton: UIButton!
    private var toolbar: UIToolbar!
    private var previousButton: UIBarButtonItem!
    private var nextButton: UIBarButtonItem!
    private var actionButton: UIBarButtonItem!
    private var counterButton: UIBarButtonItem!
    private var counterLabel: UILabel!
    
    
    private var actionsSheet: UIAlertController!
    private var activityViewController: UIActivityViewController!
    
    private var senderViewForAnimation: UIView!
    
    private var senderViewOriginalFrame: CGRect!
    private var applicationWindow: UIWindow!
    private var applicationTopViewController: UIViewController!
    
    private var firstX: CGFloat = 0
    private var firstY: CGFloat = 0
    
    private var hideTask: CancelableTask!
    
    private func  areControlsHidden() -> Bool {
        if let t = toolbar {
            return t.alpha == 0
        }
        return true
    }
    
   
    deinit {
        pagingScrollView.delegate = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
        releaseAllUnderlyingPhotos()
    }

    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        initialize()
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        // Defaults
        initialize()
    }
    private func initialize() {
        self.hidesBottomBarWhenPushed = true
        
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        applicationWindow = UIApplication.sharedApplication().delegate?.window!
        self.modalPresentationStyle = UIModalPresentationStyle.Custom
        self.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.modalPresentationCapturesStatusBarAppearance = true
        self.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        
        // Listen for IDMPhoto notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleSSPhotoLoadingDidEndNotification:"), name: SSPHOTO_LOADING_DID_END_NOTIFICATION, object: nil)
    }
    // MARK: - SSPhoto Loading Notification
    func handleSSPhotoLoadingDidEndNotification(notification: NSNotification) {
        if let photo = notification.object as? SSPhoto {
            if let page = pageDisplayingPhoto(photo) {
                if photo.underlyingImage() != nil {
                    page.displayImage()
                    loadAdjacentPhotosIfNecessary(photo)
                } else {
                    page.displayImageFailure()
                }
                
            }
        }
    }
    
}
// MARK: - Init
extension SSImageBrowser {
    
    convenience public init(aPhotos:[SSPhoto], animatedFromView view: UIView! = nil) {
        self.init(nibName: nil, bundle: nil)
        photos = aPhotos
        senderViewForAnimation = view
    }
    
    convenience public init(aURLs:[NSURL], animatedFromView view: UIView! = nil) {
        self.init(nibName: nil, bundle: nil)
        let aPhotos = SSPhoto.photosWithURLs(aURLs)
        photos = aPhotos
        senderViewForAnimation = view
    }
}
// MARK: - Life Cycle
extension SSImageBrowser {
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(white: useWhiteBackgroundColor ? 1 : 0, alpha:1)
        
        self.view.clipsToBounds = true
        
        // Setup paging scrolling view
        let pagingScrollViewFrame = frameForPagingScrollView()
        pagingScrollView = UIScrollView(frame:pagingScrollViewFrame)
        pagingScrollView.pagingEnabled = true
        pagingScrollView.delegate = self
        pagingScrollView.showsHorizontalScrollIndicator = false
        pagingScrollView.showsVerticalScrollIndicator = false
        pagingScrollView.backgroundColor = UIColor.clearColor()
        pagingScrollView.contentSize = contentSizeForPagingScrollView()
        self.view.addSubview(pagingScrollView)
        
        // Transition animation
        performPresentAnimation()
        
        let currentOrientation = UIApplication.sharedApplication().statusBarOrientation
        
        // Toolbar
        toolbar = UIToolbar(frame: frameForToolbarAtOrientation(currentOrientation))
        toolbar.backgroundColor = UIColor.clearColor()
        toolbar.clipsToBounds = true
        toolbar.translucent = true
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: UIBarPosition.Any, barMetrics: UIBarMetrics.Default)
        
        // Close Button
        doneButton = UIButton.buttonWithType(.Custom) as! UIButton
        doneButton.frame =  frameForDoneButtonAtOrientation(currentOrientation)
        doneButton.alpha = 1.0
        doneButton.addTarget(self, action: Selector("doneButtonPressed"), forControlEvents: .TouchUpInside)
        
        if doneButtonImage == nil {
            doneButton.setTitleColor(UIColor(white:0.9, alpha:0.9), forState:.Normal | .Highlighted)
            doneButton.setTitle(SSPhotoBrowserLocalizedStrings("Done"), forState:.Normal)
            doneButton.titleLabel?.font = UIFont.boldSystemFontOfSize(11)
            doneButton.backgroundColor = UIColor(white:0.1,alpha:0.5)
            doneButton.layer.cornerRadius = 3.0
            doneButton.layer.borderColor = UIColor(white:0.9, alpha:0.9).CGColor
            doneButton.layer.borderWidth = 1.0
        }
        else {
            doneButton.setBackgroundImage(doneButtonImage, forState: .Normal)
            doneButton.contentMode = .ScaleAspectFit
        }

        let leftButtonImage = (leftArrowImage == nil) ?
            UIImage(named: "Resource/Source/IDMPhotoBrowser.bundle/images/IDMPhotoBrowser_arrowLeft.png") : leftArrowImage
        
        let rightButtonImage = (rightArrowImage == nil) ?
            UIImage(named: "Resource/Source/IDMPhotoBrowser.bundle/images/IDMPhotoBrowser_arrowRight.png") : rightArrowImage
        
        let leftButtonSelectedImage = (leftArrowSelectedImage == nil) ?
            UIImage(named: "Resource/Source/IDMPhotoBrowser.bundle/images/IDMPhotoBrowser_arrowLeftSelected.png")  : leftArrowSelectedImage
        
        let rightButtonSelectedImage = (rightArrowSelectedImage == nil) ?
            UIImage(named: "Resource/Source/IDMPhotoBrowser.bundle/images/IDMPhotoBrowser_arrowRightSelected.png") : rightArrowSelectedImage
        
        // Arrows
        
        previousButton = UIBarButtonItem(customView:customToolbarButtonImage(UIImage(), imageSelected: UIImage(), action: Selector("gotoPreviousPage")))
        
        nextButton = UIBarButtonItem(customView:customToolbarButtonImage(UIImage(), imageSelected: UIImage(), action: Selector("gotoNextPage")))
        
        
        
        // Counter Label
        counterLabel = UILabel(frame:CGRectMake(0, 0, 95, 40))
        counterLabel.textAlignment = .Center
        counterLabel.backgroundColor = UIColor.clearColor()
        counterLabel.font = UIFont(name: "Helvetica", size: 17)
        
        if !useWhiteBackgroundColor {
            counterLabel.textColor = UIColor.whiteColor()
            counterLabel.shadowColor = UIColor.darkTextColor()
            counterLabel.shadowOffset = CGSizeMake(0, 1)
        }
        else {
            counterLabel.textColor = UIColor.blackColor()
        }
        
        // Counter Button
        counterButton = UIBarButtonItem(customView:counterLabel)
        
        // Action Button
        actionButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: Selector("actionButtonPressed:"))
        
        // Gesture
        panGesture = UIPanGestureRecognizer(target:self, action:Selector("panGestureRecognized:"))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        
        
    }
    public override func viewWillAppear(animated: Bool) {
        reloadData()
        super.viewWillAppear(animated)
        
        // Status Bar
        statusBarOriginallyHidden = UIApplication.sharedApplication().statusBarHidden
        
        // Update UI
        hideControlsAfterDelay()
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        viewIsActive = true
    }
    
    public override func viewWillLayoutSubviews() {
        // Flag
        performingLayout = true
        
        let currentOrientation = UIApplication.sharedApplication().statusBarOrientation
        
        // Toolbar
        toolbar.frame = frameForToolbarAtOrientation(currentOrientation)
        
        // Done button
        doneButton.frame = frameForDoneButtonAtOrientation(currentOrientation)
        
        
        // Remember index
        let indexPriorToLayout = currentPageIndex
        
        // Get paging scroll view frame to determine if anything needs changing
        let pagingScrollViewFrame =  frameForPagingScrollView()
        
        // Frame needs changing
        pagingScrollView.frame = pagingScrollViewFrame
        
        // Recalculate contentSize based on current orientation
        pagingScrollView.contentSize =  contentSizeForPagingScrollView()
        
        // Adjust frames and configuration of each visible page
        for  page  in visiblePages  {
//            if let page = item as? SSZoomingScrollView {
                let index = PAGE_INDEX(page)
                page.frame =  frameForPageAtIndex(index)
            if let captionView = page.captionView {
                captionView.frame = frameForCaptionView(captionView, atIndex: index)
            }
            
                page.setMaxMinZoomScalesForCurrentBounds()
//            }
            
        }
        
        // Adjust contentOffset to preserve page location based on values collected prior to location
        pagingScrollView.contentOffset = contentOffsetForPageAtIndex(indexPriorToLayout)
        didStartViewingPageAtIndex(currentPageIndex) // initial
        
        // Reset
        currentPageIndex = indexPriorToLayout
        performingLayout = false
        
        // Super
        super.viewWillLayoutSubviews()
    }
    
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        releaseAllUnderlyingPhotos()
        recycledPages.removeAll(keepCapacity: false)
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().postNotificationName("stopAllRequest", object: nil)
    }
}
// MARK: - Public Func
extension SSImageBrowser {
    public func reloadData() {
        releaseAllUnderlyingPhotos()
        
        performLayout()
        
        self.view.setNeedsLayout()
    }
    
    public func setInitialPageIndex(var index:Int) {
        let count = numberOfPhotos()
        if index >= count {
            index = count - 1
        }
        initalPageIndex = index
        currentPageIndex = index
        if self.isViewLoaded() {
            jumpToPageAtIndex(index)
            if !viewIsActive {
                tilePages()
            }
        }
    }
    
    public func photoAtIndex(index:Int) -> SSPhoto {
        return photos[index]
    }
    
    // MARK: - Status Bar
    
    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return useWhiteBackgroundColor ? UIStatusBarStyle.Default : UIStatusBarStyle.LightContent
    }
    
    public override func prefersStatusBarHidden()-> Bool {
        if forceHideStatusBar {
            return true
        }
        if isdraggingPhoto {
            if statusBarOriginallyHidden {
                return true
            } else {
                return false
            }
        } else {
            return areControlsHidden()
        }
    }
    
    public override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.Fade
    }
    
}
// MARK: - UIScrollViewDelegate
extension SSImageBrowser: UIScrollViewDelegate {

    public func scrollViewDidScroll(scrollView: UIScrollView) {
        if !viewIsActive || performingLayout || rotating {
            return
        }
        setControlsHidden(true, animated: false, permanent: false)
        tilePages()
        let visibleBounds = pagingScrollView.bounds
        let x = CGRectGetMidX(visibleBounds)
        let width = CGRectGetWidth(visibleBounds)
        let f = x / width
        var index = Int(floor(f))
        if index < 0 {
            index = 0
        }
        let count = numberOfPhotos() - 1
        if index > count {
            index = count
        }
        let previousCurrentPage = currentPageIndex
        currentPageIndex = index
        if currentPageIndex != previousCurrentPage {
            didStartViewingPageAtIndex(index)
            if arrowButtonsChangePhotosAnimated {
                updateToolbar()
            }
        }
    }
  
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
    // Hide controls when dragging begins
        setControlsHidden(true, animated: true, permanent: false)
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    // Update toolbar when page changes
        if !arrowButtonsChangePhotosAnimated {
            updateToolbar()
        }
    }


    
}
// MARK: - Private Func
extension SSImageBrowser {
    
    
    
   
    
    // MARK: - Pan Gesture
    func panGestureRecognized(sender: UIPanGestureRecognizer) {
        // Initial Setup
        let scrollView = pageDisplayedAtIndex(currentPageIndex)
        if scrollView == nil {
            return
        }
        
        
        
        let viewHeight = scrollView.frame.size.height
        let viewHalfHeight = viewHeight/2
        
        var translatedPoint = sender.translationInView(self.view)
        
        // Gesture Began
        if sender.state == .Began {
            setControlsHidden(true, animated: true, permanent: true)
            firstX = scrollView.center.x
            firstY = scrollView.center.y
            senderViewForAnimation?.hidden = currentPageIndex == initalPageIndex
            isdraggingPhoto = true
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
        translatedPoint = CGPointMake(firstX, firstY+translatedPoint.y)
        scrollView.center = translatedPoint
        
        let newY = scrollView.center.y - viewHalfHeight
        let newAlpha = 1 - fabs(newY)/viewHeight //abs(newY)/viewHeight * 1.8
        
        self.view.opaque = true
        
        self.view.backgroundColor = UIColor(white: useWhiteBackgroundColor ? 1 : 0, alpha:newAlpha)
        
        // Gesture Ended
        if sender.state == .Ended {
            
            if scrollView.center.y > viewHalfHeight + 40 || scrollView.center.y < viewHalfHeight - 40  {
                if senderViewForAnimation != nil && currentPageIndex == initalPageIndex {
                    performCloseAnimationWithScrollView(scrollView)
                    return
                }
                let finalX = firstX
                var finalY: CGFloat = 0
                let windowsHeigt = applicationWindow.frame.size.height
                
                if scrollView.center.y > viewHalfHeight+30 {
                    finalY = windowsHeigt*2
                } else {
                    finalY = -viewHalfHeight
                }
                
                let aDuration:NSTimeInterval = 0.35
                UIView.animateWithDuration(NSTimeInterval(animationDuration), animations: { () -> Void in
                    scrollView.center = CGPointMake(finalX, finalY)
                    self.view.backgroundColor = UIColor.clearColor()
                })
                UIView.animateWithDuration(NSTimeInterval(animationDuration), delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
                    scrollView.center = CGPointMake(finalX, finalY)
                    }, completion: { (b) -> Void in
                        
                })
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.35 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
                    self.doneButtonPressed()
                }
                
            } else {
                isdraggingPhoto = false
                self.setNeedsStatusBarAppearanceUpdate()
                
                self.view.backgroundColor = UIColor(white: useWhiteBackgroundColor ? 1 : 0, alpha:1)
                
                let velocityY = sender.velocityInView(self.view).y*0.35
                
                let finalX = firstX
                let finalY = viewHalfHeight
                let animationDuration = abs(velocityY) * 0.0002 + 0.2
                UIView.animateWithDuration(NSTimeInterval(animationDuration), delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                    scrollView.center = CGPointMake(finalX, finalY)
                    }, completion: { (b) -> Void in
                        
                })
            }
        }
        
    }
    // MARK: - Control Hiding / Showing
    
    func cancelControlHiding() {
    // If a timer exists then cancel and release
        cancel(hideTask)
    }
    
    func hideControlsAfterDelay() {
        if  !areControlsHidden() {
            cancelControlHiding()
            hideTask = delay(5, work: { () -> Void in
                self.hideControls()
            })
        }
    }

    
    private func setControlsHidden(hidden: Bool, animated: Bool, permanent: Bool) {
        // Cancel any timers
        cancelControlHiding()
        
        // Captions
        var captionViews = Set<SSCaptionView>()
        for  page in visiblePages {
            if page.captionView != nil {
                captionViews.insert(page.captionView)
            }
        }
        
        // Hide/show bars
        UIView.animateWithDuration(animated ? 0.1 : 0, animations: { () -> Void in
            let alpha: CGFloat = hidden ? 0 : 1
            self.navigationController?.navigationBar.alpha = alpha
            self.toolbar.alpha = alpha
            self.doneButton.alpha = alpha
            for v in captionViews {
                v.alpha = alpha
            }
        })
        
        // Control hiding timer
        // Will cancel existing timer but only begin hiding if they are visible
        if !permanent {
            hideControlsAfterDelay()
        }
        self.setNeedsStatusBarAppearanceUpdate()
    }

    
    
    private func hideControls() {
        if autoHide {
            setControlsHidden(true, animated: true, permanent: false)
        }
    }
    func  toggleControls () {
        setControlsHidden(!areControlsHidden(), animated: true, permanent: false)
    }
    
    // MARK: - NSObject
    private func releaseAllUnderlyingPhotos() {
        for obj in photos {
            obj.unloadUnderlyingImage()
        }
    }
    
    // MARK: - Data
    private func numberOfPhotos() -> Int {
        return photos.count
    }
    
    
    private func captionViewForPhotoAtIndex(index: Int) -> SSCaptionView! {
        var captionView:SSCaptionView! = delegate?.photoBrowser(self, captionViewForPhotoAtIndex: index)
        if captionView == nil {
            let photo = photoAtIndex(index)
            if let _ = photo.caption() {
                captionView = SSCaptionView(aPhoto: photo)
                captionView.alpha = areControlsHidden() ? 0 : 1
            }
        }else{
            captionView.alpha = areControlsHidden() ? 0 : 1
        }
        
        return captionView
    }
    
    func imageForPhoto(photo: SSPhoto!) -> UIImage! {
        if photo != nil{
            // Get image or obtain in background
            if photo.underlyingImage() != nil {
                return photo.underlyingImage()
            } else {
                photo.loadUnderlyingImageAndNotify()
                if let img = photo.placeholderImage() {
                    return img
                }
            }
        }
        return nil
    }
    
    
    private func loadAdjacentPhotosIfNecessary(photo :SSPhoto) {
        if let page = pageDisplayingPhoto(photo) {
            let pageIndex = PAGE_INDEX(page)
            if currentPageIndex == pageIndex {
                if pageIndex > 0 {
                    let photo = photoAtIndex(pageIndex - 1)
                    if photo.underlyingImage() == nil {
                        photo.loadUnderlyingImageAndNotify()
                    }
                }
                let count = numberOfPhotos()
                if pageIndex < count - 1 {
                    let photo = photoAtIndex(pageIndex + 1)
                    if photo.underlyingImage() == nil {
                        photo.loadUnderlyingImageAndNotify()
                    }
                }
            }
        }
        
    }
    
    // MARK: - General
    
    private func prepareForClosePhotoBrowser() {
    // Gesture
        applicationWindow.removeGestureRecognizer(panGesture)
    
        autoHide = false
    
    // Controls
        NSObject.cancelPreviousPerformRequestsWithTarget(self)
    }
    
    private func dismissPhotoBrowserAnimated(animated: Bool) {
        
        self.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        delegate?.photoBrowser(self, willDismissAtPageIndex: currentPageIndex)
    
        self.dismissViewControllerAnimated(animated, completion: { () -> Void in
            self.delegate?.photoBrowser(self, didDismissAtPageIndex: self.currentPageIndex)
        })
     
    }
    private func getImageFromView(view: UIView) -> UIImage {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.renderInContext(UIGraphicsGetCurrentContext())
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    private func customToolbarButtonImage(image:UIImage, imageSelected selectedImage:UIImage, action: Selector) -> UIButton {
        let button = UIButton.buttonWithType(.Custom) as! UIButton
        button.setBackgroundImage(image, forState: .Normal)
        button.setBackgroundImage(selectedImage, forState: .Disabled)
        button.addTarget(self, action: action, forControlEvents: .TouchUpInside)
        button.contentMode = .Center
        button.frame = CGRectMake(0,0, image.size.width, image.size.height)
        return button
    }
    
    private func  topviewController() -> UIViewController {
        var topviewController = UIApplication.sharedApplication().keyWindow?.rootViewController
        
        while topviewController?.presentedViewController != nil {
            topviewController = topviewController?.presentedViewController
        }
        
        return topviewController!
    }

    
    // MARK: - Animation
    
    private func rotateImageToCurrentOrientation(image: UIImage) -> UIImage? {
        let o = UIApplication.sharedApplication().statusBarOrientation
        if UIInterfaceOrientationIsLandscape(o) {
            let orientation = o == .LandscapeLeft ? UIImageOrientation.Left : UIImageOrientation.Right
            let rotatedImage = UIImage(CGImage: image.CGImage, scale: 1.0, orientation: orientation)
            return rotatedImage
        }
        return image
    }
    
    private func performPresentAnimation() {
        
        self.view.alpha = 0.0
        pagingScrollView.alpha = 0.0
        
        if nil != senderViewForAnimation {
            var imageFromView = scaleImage != nil ? scaleImage : getImageFromView(senderViewForAnimation)
            
            imageFromView = rotateImageToCurrentOrientation(imageFromView)
            
            senderViewOriginalFrame = senderViewForAnimation.superview?.convertRect(senderViewForAnimation.frame, toView: nil)
            
            
            
            let screenBound = UIScreen.mainScreen().bounds
            let screenWidth = screenBound.size.width
            let screenHeight = screenBound.size.height
            
            let fadeView = UIView(frame:CGRectMake(0, 0, screenWidth, screenHeight))
            fadeView.backgroundColor = UIColor.clearColor()
            applicationWindow.addSubview(fadeView)
            
            
            let resizableImageView = UIImageView(image:imageFromView)
            resizableImageView.frame = senderViewOriginalFrame
            resizableImageView.clipsToBounds = true
            resizableImageView.contentMode = .ScaleAspectFit
            resizableImageView.backgroundColor = UIColor(white: useWhiteBackgroundColor ? 1 : 0, alpha:1)
            applicationWindow.addSubview(resizableImageView)
            senderViewForAnimation?.hidden = true
            
            
            
            typealias Completion = ()->()
            let completion: Completion = {
                self.view.alpha = 1.0
                self.pagingScrollView.alpha = 1.0
                resizableImageView.backgroundColor = UIColor(white: self.useWhiteBackgroundColor ? 1 : 0, alpha:1)
                fadeView.removeFromSuperview()
                resizableImageView.removeFromSuperview()
            }
            UIView.animateWithDuration(NSTimeInterval(animationDuration), animations: { () -> Void in
                fadeView.backgroundColor = self.useWhiteBackgroundColor ? UIColor.whiteColor() : UIColor.blackColor()
            })
            
            let scaleFactor = (imageFromView != nil ? imageFromView.size.width : screenWidth) / screenWidth
            let finalImageViewFrame = CGRectMake(0, (screenHeight/2)-((imageFromView.size.height / scaleFactor)/2), screenWidth, imageFromView.size.height / scaleFactor)
            
            if usePopAnimation {
                animateView(resizableImageView, toFrame: finalImageViewFrame, completion: completion)
            } else {
                UIView.animateWithDuration(NSTimeInterval(animationDuration), animations: { () -> Void in
                    resizableImageView.layer.frame = finalImageViewFrame
                    }, completion: { (b) -> Void in
                        if b {
                            completion()
                        }
                })
            }
        }else{
            self.view.alpha = 1.0
            self.pagingScrollView.alpha = 1.0
        }
        
    }

private func performCloseAnimationWithScrollView(scrollView: SSZoomingScrollView) {
    
    let fadeAlpha = 1 - fabs(scrollView.frame.origin.y)/scrollView.frame.size.height
    
    var imageFromView = scrollView.photo.underlyingImage()
    if imageFromView == nil {
        imageFromView = scrollView.photo.placeholderImage()
    }
    
    weak var wself: SSImageBrowser! = self
    typealias Completion = ()->()
    var completion: Completion = {
        wself.senderViewForAnimation?.hidden = false
        wself.senderViewForAnimation = nil
        wself.scaleImage = nil
        
        wself.prepareForClosePhotoBrowser()
        wself.dismissPhotoBrowserAnimated(false)
    }
    
    
    if imageFromView == nil {
        completion()
        return
    }
    
    //imageFromView = [self rotateImageToCurrentOrientation:imageFromView]
    
    let screenBound = UIScreen.mainScreen().bounds
    let screenWidth = screenBound.size.width
    let screenHeight = screenBound.size.height
    
    let scaleFactor = imageFromView.size.width / screenWidth
    
    let fadeView = UIView(frame:CGRectMake(0, 0, screenWidth, screenHeight))
    fadeView.backgroundColor = self.useWhiteBackgroundColor ? UIColor.whiteColor() : UIColor.blackColor()
    fadeView.alpha = fadeAlpha
    applicationWindow.addSubview(fadeView)
    
    let resizableImageView = UIImageView(image:imageFromView)
    resizableImageView.frame = imageFromView != nil ? CGRectMake(0, (screenHeight/2)-((imageFromView.size.height / scaleFactor)/2)+scrollView.frame.origin.y, screenWidth, imageFromView.size.height / scaleFactor) : CGRectZero
    resizableImageView.contentMode = UIViewContentMode.ScaleAspectFit
    resizableImageView.backgroundColor = UIColor.clearColor()
    resizableImageView.clipsToBounds = true
    applicationWindow.addSubview(resizableImageView)
    self.view.hidden = true
    
    
    var bcompletion: Completion = {
        wself.senderViewForAnimation?.hidden = false
        wself.senderViewForAnimation = nil
        wself.scaleImage = nil
        
        fadeView.removeFromSuperview()
        resizableImageView.removeFromSuperview()
        
        wself.prepareForClosePhotoBrowser()
        wself.dismissPhotoBrowserAnimated(false)
    }
    UIView.animateWithDuration(NSTimeInterval(animationDuration), animations: { () -> Void in
        fadeView.alpha = 0
        self.view.backgroundColor = UIColor.clearColor()
    })
    
    if usePopAnimation {
        animateView(resizableImageView, toFrame: senderViewOriginalFrame, completion: bcompletion)
    } else {
        UIView.animateWithDuration(NSTimeInterval(animationDuration), animations: { () -> Void in
            resizableImageView.layer.frame = self.senderViewOriginalFrame
        }, completion: { (b) -> Void in
            if b {
                bcompletion()
            }
        })
    }
    
}

    // MARK: - Layout
    
    private func performLayout() {
        
        performingLayout = true
        let photosCount = numberOfPhotos()
        
        visiblePages?.removeAll(keepCapacity: false)
        recycledPages?.removeAll(keepCapacity: false)
        
        
        if displayToolbar {
            self.view.addSubview(toolbar)
        } else {
            toolbar.removeFromSuperview()
        }
        
        if displayDoneButton && self.navigationController?.navigationBar == nil {
            self.view.addSubview(doneButton)
        }
        
        let fixedLeftSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: self, action: nil)
        fixedLeftSpace.width = 32
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: self, action: nil)
        
        var items = [UIBarButtonItem]()
        
        if displayActionButton {
            items.append(fixedLeftSpace)
        }
        
        items.append(flexSpace)
        
        if photosCount > 1 && displayArrowButton {
            items.append(previousButton)
        }
        
        if displayCounterLabel {
            items.append(flexSpace)
            items.append(counterButton)
        }
        
        items.append(flexSpace)
        
        if photosCount > 1 && displayArrowButton {
            items.append(nextButton)
        }
        
        items.append(flexSpace)
        
        if displayActionButton {
            items.append(actionButton)
        }
        
        toolbar.items = items
        
        updateToolbar()
        
        pagingScrollView.contentOffset = contentOffsetForPageAtIndex(currentPageIndex)
        tilePages()
        performingLayout = false
        
        if !disableVerticalSwipe {
            self.view.addGestureRecognizer(panGesture)
        }
    }
    
    // MARK: - Toolbar
    private func updateToolbar() {
        // Counter
        let count = numberOfPhotos()
        if count > 1 {
            counterLabel.text = "\(currentPageIndex + 1) "+SSPhotoBrowserLocalizedStrings("of")+" \(count)"
        } else {
            counterLabel.text = nil
        }
        
        // Buttons
        previousButton.enabled = currentPageIndex > 0
        nextButton.enabled = currentPageIndex < count - 1
    }
    
    private func jumpToPageAtIndex(index: Int) {
        // Change page
        let count = numberOfPhotos()
        if index < count {
            let pageFrame = frameForPageAtIndex(index)
            
            if arrowButtonsChangePhotosAnimated {
                pagingScrollView.setContentOffset(CGPointMake(pageFrame.origin.x - PADDING, 0), animated: true)
            } else {
                pagingScrollView.contentOffset = CGPointMake(pageFrame.origin.x - PADDING, 0)
                updateToolbar()
            }
        }
        
        // Update timer to give more time
        hideControlsAfterDelay()
    }
    
    func gotoPreviousPage() {
        jumpToPageAtIndex(currentPageIndex - 1)
    }
    
    func gotoNextPage() {
        jumpToPageAtIndex(currentPageIndex + 1)
    }

    // MARK: - Frame Calculations
    
    private func isLandscape(orientation: UIInterfaceOrientation) -> Bool
    {
        return UIInterfaceOrientationIsLandscape(orientation)
    }
    
    private func frameForToolbarAtOrientation(orientation: UIInterfaceOrientation) -> CGRect{
        var height: CGFloat = 44
        
        if isLandscape(orientation) {
            height = 32
        }
        
        return CGRectMake(0, self.view.bounds.size.height - height, self.view.bounds.size.width, height)
    }
    
    private func frameForDoneButtonAtOrientation(orientation: UIInterfaceOrientation) -> CGRect {
        let screenBound = self.view.bounds
        let screenWidth = screenBound.size.width
        return CGRectMake(screenWidth - 75, 30, 55, 26)
    }
    
    private func frameForCaptionView(captionView: SSCaptionView, atIndex index: Int) -> CGRect {
        let pageFrame = frameForPageAtIndex(index)
        
        let captionSize = captionView.sizeThatFits(CGSizeMake(pageFrame.size.width, 0))
        
        let captionFrame = CGRectMake(pageFrame.origin.x, pageFrame.size.height - captionSize.height - (toolbar.superview != nil ?toolbar.frame.size.height:0), pageFrame.size.width, captionSize.height)
        
        return captionFrame
    }
    
    private func frameForPageAtIndex(index: Int) -> CGRect {
        // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
        // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
        // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
        // because it has a rotation transform applied.
        let bounds = pagingScrollView.bounds
        var pageFrame = bounds
        pageFrame.size.width -= (2 * PADDING)
        pageFrame.origin.x = (bounds.size.width * CGFloat(index)) + PADDING
        return pageFrame
    }

    
    private func contentSizeForPagingScrollView() -> CGSize{
        // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
        let bounds = pagingScrollView.bounds
        let count = numberOfPhotos()
        return CGSizeMake(bounds.size.width *  CGFloat(count), bounds.size.height)
    }
    private func frameForPagingScrollView() -> CGRect {
        var frame = self.view.bounds
        frame.origin.x -= PADDING
        frame.size.width += 2 * PADDING
        return frame
    }
    
    private func contentOffsetForPageAtIndex(index: Int) -> CGPoint{
        let pageWidth = pagingScrollView.bounds.size.width
        let newOffset = CGFloat(index) * pageWidth
        return CGPointMake(newOffset, 0)
    }
    
    // MARK: - Paging
    
    private func pageDisplayedAtIndex(index: Int) -> SSZoomingScrollView! {
        for  page in visiblePages {
                if  PAGE_INDEX(page) == index {
                    return page
                }
        }
        return nil
    }
    
    private func pageDisplayingPhoto(photo: SSPhoto) -> SSZoomingScrollView! {
        var aPage: SSZoomingScrollView!
        for  page in visiblePages {
            if let bPhoto = page.photo {
                if  bPhoto == photo {
                    aPage = page
                }
            }
        }
        return aPage
    }
    
    private func isDisplayingPageForIndex(index: Int) -> Bool {
        for page in visiblePages {
            let pageIndex = PAGE_INDEX(page)
            if pageIndex == index {
                return true
            }
        }
        return false
    }
    
    private func configurePage(page: SSZoomingScrollView, forIndex index: Int) {
        page.frame = frameForPageAtIndex(index)
        page.tag = PAGE_INDEX_TAG_OFFSET + index
        page.setAPhoto(photoAtIndex(index))
        var wPhoto = page.photo
        weak var wPage: SSZoomingScrollView! = page
        wPhoto!.progressUpdateBlock = {
            (progress) -> Void in
            wPage.setProgress(progress, forPhoto: wPhoto)
        }
    }
    
    private func dequeueRecycledPage() -> SSZoomingScrollView! {
        let page = recycledPages.first
        if page != nil {
            recycledPages.remove(page!)
        }
        return page
    }
    
    private func didStartViewingPageAtIndex(index: Int) {
        // Load adjacent images if needed and the photo is already
        // loaded. Also called after photo has been loaded in background
        let currentPhoto = photoAtIndex(index)
        if currentPhoto.underlyingImage() != nil {
            // photo loaded so load ajacent now
            loadAdjacentPhotosIfNecessary(currentPhoto)
        }
        delegate?.photoBrowser(self, didShowPhotoAtIndex: index)
        
    }
    
    private func tilePages() {
        let visibleBounds = pagingScrollView.bounds
        var iFirstIndex = Int(floor((CGRectGetMinX(visibleBounds)+PADDING*2) / CGRectGetWidth(visibleBounds)))
        var iLastIndex  = Int(floor((CGRectGetMaxX(visibleBounds)-PADDING*2-1) / CGRectGetWidth(visibleBounds)))
        let phototCount = numberOfPhotos()
        if iFirstIndex < 0 {
            iFirstIndex = 0
        }
        if iFirstIndex >  phototCount - 1 {
            iFirstIndex = phototCount - 1
        }
        if iLastIndex < 0 {
            iLastIndex = 0
        }
        if iLastIndex > phototCount - 1 {
            iLastIndex = phototCount - 1
        }
        // Recycle no longer needed pages
        var pageIndex: Int = 0
        for page in visiblePages {
                pageIndex = PAGE_INDEX(page)
                if pageIndex < iFirstIndex || pageIndex > iLastIndex {
                    recycledPages.insert(page)
                    page.prepareForReuse()
                    page.removeFromSuperview()
                }
        }
        visiblePages.exclusiveOr(recycledPages)
        while recycledPages.count > 2 {
            recycledPages.remove(recycledPages.first!)
        }// Only keep 2 recycled pages
        
        
        // Add missing pages
        
        for index in iFirstIndex...iLastIndex {
            if !isDisplayingPageForIndex(index) {
                let page = SSZoomingScrollView(aPhotoBrowser: self)
                page.backgroundColor = UIColor.clearColor()
                page.opaque = true
                configurePage(page, forIndex: index)
                visiblePages.insert(page)
                pagingScrollView.addSubview(page)
                
                if let captionView = captionViewForPhotoAtIndex(index) {
                    captionView.frame = frameForCaptionView(captionView, atIndex: index)
                    pagingScrollView.addSubview(captionView)
                    page.captionView = captionView
                }
                
            }
        }
    }
    
    // MARK: - Buttons 
    func doneButtonPressed() {
        if  senderViewForAnimation != nil && currentPageIndex == initalPageIndex {
            let scrollView = pageDisplayedAtIndex(currentPageIndex)
            performCloseAnimationWithScrollView(scrollView)
        }
        else {
            senderViewForAnimation?.hidden = false
            prepareForClosePhotoBrowser()
            dismissPhotoBrowserAnimated(true)
        }
        
    }
    
    func actionButtonPressed(sender:AnyObject) {
        let photo = photoAtIndex(currentPageIndex)
        let count = self.numberOfPhotos()
        if count > 0 && photo.underlyingImage() != nil {
            if actionButtonTitles.count == 0 {
                var activityItems: [AnyObject] = [photo.underlyingImage()!]
                if let caption = photo.caption() {
                    activityItems.append(caption)
                }
                
                activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                

                weak var wself : SSImageBrowser! = self
                activityViewController.completionWithItemsHandler = {
                    (activityType,completed,returnedItems,activityError) -> Void in
                    wself.hideControlsAfterDelay()
                    wself.activityViewController = nil
                }
                self.presentViewController(activityViewController, animated: true, completion: nil)
            }else{
                // Action sheet
                actionsSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
                
                weak var wself : SSImageBrowser! = self
                
                
                for (index, atitle) in enumerate(actionButtonTitles) {
                    let action = UIAlertAction(title: atitle, style: UIAlertActionStyle.Default, handler:{
                        (aAction) -> Void in
                        wself.actionsSheet = nil
                        wself.delegate?.photoBrowser(wself, didDismissActionSheetWithButtonIndex: index, photoIndex: wself.currentPageIndex)
                        wself.hideControlsAfterDelay()
                    })
                    actionsSheet.addAction(action)
                }
                let action = UIAlertAction(title: SSPhotoBrowserLocalizedStrings("Cancel"), style: UIAlertActionStyle.Cancel, handler:{
                    (aAction) -> Void in
                    wself.actionsSheet = nil
                    wself.hideControlsAfterDelay()
                })
                
                self.presentViewController(actionsSheet, animated: true, completion: nil)
                
            }
            
        }
        setControlsHidden(false, animated: true, permanent: true)
    }
    
    
    
    // MARK: - pop Animation
    
    private func animateView(view: UIView, toFrame frame: CGRect, completion: (()->())! ) {
        let ainamtion = POPSpringAnimation(propertyNamed: kPOPViewFrame)
        ainamtion.springBounciness = 6
        ainamtion.dynamicsMass = 1
        ainamtion.toValue = NSValue(CGRect: frame)
        view.pop_addAnimation(ainamtion, forKey: nil)
        
        ainamtion.completionBlock = {
            (aniamte,finish) in
            completion?()
        }
    }
    
}

extension SSImageBrowser {
    
    typealias CancelableTask = (cancel: Bool) -> Void
    
    func delay(time: NSTimeInterval, work: dispatch_block_t) -> CancelableTask? {
        
        var finalTask: CancelableTask?
        
        var cancelableTask: CancelableTask = { cancel in
            if cancel {
                finalTask = nil // key
                
            } else {
                dispatch_async(dispatch_get_main_queue(), work)
            }
        }
        
        finalTask = cancelableTask
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            if let task = finalTask {
                task(cancel: false)
            }
        }
        
        return finalTask
    }
    
    func cancel(cancelableTask: CancelableTask?) {
        cancelableTask?(cancel: true)
    }
}