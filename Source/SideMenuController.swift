//
//  SideMenuController.swift
//
//  Copyright (c) 2015 Teodor Patraş
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit

public protocol SideMenuControllerDelegate: class {
    func sideMenuControllerDidHide(sideMenuController: SideMenuController)
    func sideMenuControllerDidReveal(sideMenuController: SideMenuController)
}


public extension SideMenuController {
    
    /**
     Toggles the side pannel visible or not.
     */
    public func toggleRight() {
        
        if !transitionInProgress {
            if sidePanelVisible == .None{
                prepare(sidePanelForDisplay: true)
            }
            
            animate(toReveal: sidePanelVisible ==  .None, showingSide: .RightSide)
        }
    }
    
    public func toggleLeft() {
        
        if !transitionInProgress {
            if sidePanelVisible  ==  .None {
                prepare(sidePanelForDisplay: true)
            }
            
            animate(toReveal: sidePanelVisible  ==  .None, showingSide: .LeftSide)
        }
    }
    
    /**
     Embeds a new side controller
     
     - parameter sideViewController: controller to be embedded
     */
    public func embed(leftViewController leftViewController: UIViewController, rightViewController: UIViewController) {
        if leftSideViewController == nil {
            
            leftSideViewController = leftViewController
            leftSideViewController.view.frame = leftSidePanel.bounds
            
            leftSidePanel.addSubview(leftSideViewController.view)
            
            addChildViewController(leftSideViewController)
            leftSideViewController.didMoveToParentViewController(self)
            
            leftSidePanel.hidden = true
        }
        if rightSideViewController == nil {
            
            rightSideViewController = rightViewController
            rightSideViewController.view.frame = rightSidePanel.bounds
            
            rightSidePanel.addSubview(rightSideViewController.view)
            
            addChildViewController(rightSideViewController)
            rightSideViewController.didMoveToParentViewController(self)
            
            rightSidePanel.hidden = true
        }
    }
    
    /**
     Embeds a new center controller.
     
     - parameter centerViewController: controller to be embedded
     */
    public func embed(centerViewController controller: UIViewController) {
        
        addChildViewController(controller)
        if let controller = controller as? UINavigationController {
            prepare(centerControllerForContainment: controller)
        }
        centerPanel.addSubview(controller.view)
        
        if centerViewController == nil {
            centerViewController = controller
            centerViewController.didMoveToParentViewController(self)
        } else {
            centerViewController.willMoveToParentViewController(nil)
            
            let completion: () -> () = {
                self.centerViewController.view.removeFromSuperview()
                self.centerViewController.removeFromParentViewController()
                controller.didMoveToParentViewController(self)
                self.centerViewController = controller
            }
            
            if let animator = _preferences.animating.transitionAnimator {
                animator.performTransition(forView: controller.view, completion: completion)
            } else {
                completion()
            }
            
            if sidePanelVisible  !=  .None {
                animate(toReveal: false, showingSide: .LeftSide ,statusUpdateAnimated: false)
            }
        }
    }
}

// MARK: - Public methods -

public class SideMenuController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK:- Custom types -
    
    public enum SidePanelPosition {
        case UnderCenterPanel
        case OverCenterPanel
        
        var isPositionedUnder: Bool {
            return self == UnderCenterPanel
        }
        
    }
    
    public enum ShowingSide {
        case None
        case LeftSide
        case RightSide
    }
    
    public enum StatusBarBehaviour {
        case SlideAnimation
        case FadeAnimation
        case HorizontalPan
        case ShowUnderlay
        
        var statusBarAnimation: UIStatusBarAnimation {
            switch self {
            case FadeAnimation:
                return .Fade
            case .SlideAnimation:
                return .Slide
            default:
                return .None
            }
        }
    }
    
    public struct Preferences {
        public struct Drawing {
            public var menuButtonImage: UIImage?
            public var sidePanelPosition = SidePanelPosition.UnderCenterPanel
            public var sidePanelWidth: CGFloat = 300
            public var centerPanelOverlayColor = UIColor(hue:0.15, saturation:0.21, brightness:0.17, alpha:0.6)
            public var centerPanelShadow = false
        }
        
        public struct Animating {
            public var statusBarBehaviour = StatusBarBehaviour.SlideAnimation
            public var reavealDuration = 0.3
            public var hideDuration = 0.2
            public var transitionAnimator: TransitionAnimatable.Type? = FadeAnimator.self
        }
        
        public struct Interaction {
            public var panningEnabled = true
            public var swipingEnabled = true
            public var menuButtonAccessibilityIdentifier: String?
        }
        
        public var drawing = Drawing()
        public var animating = Animating()
        public var interaction = Interaction()
        
        public init() {}
    }
    
    // MARK: - Properties -
    
    // MARK: Public
    
    public weak var delegate: SideMenuControllerDelegate?
    public static var preferences: Preferences = Preferences()
    public(set) public var sidePanelVisible = ShowingSide.None
    
    // MARK: public
    
    public lazy var _preferences: Preferences = {
        return self.dynamicType.preferences
    }()
    
    public var centerViewController: UIViewController!
    public var centerNavController: UINavigationController? {
        return centerViewController as? UINavigationController
    }
    public var leftSideViewController: UIViewController!
    public var rightSideViewController: UIViewController!
    public var statusBarUnderlay: UIView!
    public var centerPanel: UIView!
    public var leftSidePanel: UIView!
    public var rightSidePanel: UIView!
    public var centerPanelOverlay: UIView!
    public var leftSwipeRecognizer: UISwipeGestureRecognizer!
    public var rightSwipeGesture: UISwipeGestureRecognizer!
    public var leftPanRecognizer: UIPanGestureRecognizer!
    public var rightPanRecognizer: UIPanGestureRecognizer!
    public var centerTapRecognizer: UITapGestureRecognizer!
    
    public var transitionInProgress = false
    public var flickVelocity: CGFloat = 0
    
    public lazy var screenSize: CGSize = {
        return UIScreen.mainScreen().bounds.size
    }()
    
    public lazy var sidePanelPosition: SidePanelPosition = {
        return self._preferences.drawing.sidePanelPosition
    }()
    
    // MARK: Internal
    
    
    // MARK: Computed
    
    public var statusBarHeight: CGFloat {
        return UIApplication.sharedApplication().statusBarFrame.size.height > 0 ? UIApplication.sharedApplication().statusBarFrame.size.height : 20
    }
    
    public var hidesStatusBar: Bool {
        return [.SlideAnimation, .FadeAnimation].contains(_preferences.animating.statusBarBehaviour)
    }
    
    public var showsStatusUnderlay: Bool {
        
        guard _preferences.animating.statusBarBehaviour == .ShowUnderlay else {
            return false
        }
        
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
            return true
        }
        
        return screenSize.width < screenSize.height
    }
    
    public var canDisplaySideController: Bool {
        return (leftSideViewController != nil) && (rightSideViewController != nil)
    }
    
    public var centerPanelFrame: CGRect {
        
        if sidePanelPosition.isPositionedUnder && sidePanelVisible != .None {
            
            let sidePanelWidth = _preferences.drawing.sidePanelWidth
            return CGRectMake(sidePanelWidth, 0, screenSize.width, screenSize.height)
            
        } else {
            return CGRectMake(0, 0, screenSize.width, screenSize.height)
        }
    }
    
    public var leftSidePanelFrame: CGRect {
        var sidePanelFrame: CGRect
        
        let panelWidth = _preferences.drawing.sidePanelWidth
        
        if sidePanelPosition.isPositionedUnder {
            sidePanelFrame = CGRectMake(0, 0, panelWidth, screenSize.height)
        } else {
            if sidePanelVisible != .None {
                sidePanelFrame = CGRectMake(0, 0, panelWidth, screenSize.height)
            } else {
                sidePanelFrame = CGRectMake(-panelWidth, 0, panelWidth, screenSize.height)
            }
        }
        
        return sidePanelFrame
    }
    
    public var rightSidePanelFrame: CGRect {
        var sidePanelFrame: CGRect
        
        let panelWidth = _preferences.drawing.sidePanelWidth
        
        if sidePanelPosition.isPositionedUnder {
            sidePanelFrame = CGRectMake(screenSize.width - panelWidth, 0, panelWidth, screenSize.height)
        } else {
            if sidePanelVisible != .None {
                sidePanelFrame = CGRectMake(screenSize.width - panelWidth, 0, panelWidth, screenSize.height)
            } else {
                sidePanelFrame = CGRectMake(screenSize.width, 0, panelWidth, screenSize.height)
            }
        }
        
        return sidePanelFrame
    }
    
    public var statusBarWindow: UIWindow? {
        return UIApplication.sharedApplication().valueForKey("statusBarWindow") as? UIWindow
    }
    
    // MARK:- View lifecycle -
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpViewHierarchy()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setUpViewHierarchy()
    }
    
    public func setUpViewHierarchy() {
        view = UIView(frame: UIScreen.mainScreen().bounds)
        configureViews()
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if sidePanelVisible == .LeftSide {
            toggleLeft()
        }
        
        if sidePanelVisible == .RightSide {
            toggleRight()
        }
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        screenSize = size
        
        coordinator.animateAlongsideTransition({ _ in
            // reposition center panel
            self.update(centerPanelFrame: self.centerPanelFrame)
            // reposition side panel
            self.leftSidePanel.frame = self.leftSidePanelFrame
            self.rightSidePanel.frame = self.rightSidePanelFrame
            
            // hide or show the view under the status bar
            self.set(statusUnderlayAlpha: self.sidePanelVisible != .None ? 1 : 0)
            
            // reposition the center shadow view
            if let overlay = self.centerPanelOverlay {
                overlay.frame = self.centerPanelFrame
            }
            
            self.view.layoutIfNeeded()
            
            }, completion: nil)
    }
    
    // MARK: - Configurations -
    
    public func configureViews(){
        
        centerPanel = UIView(frame: CGRectMake(0, 0, screenSize.width, screenSize.height))
        view.addSubview(centerPanel)
        
        statusBarUnderlay = UIView(frame: CGRectMake(0, 0, screenSize.width, statusBarHeight))
        view.addSubview(statusBarUnderlay)
        statusBarUnderlay.alpha = 0
        
        leftSidePanel = UIView(frame: leftSidePanelFrame)
        view.addSubview(leftSidePanel)
        leftSidePanel.clipsToBounds = true
        
        rightSidePanel = UIView(frame: rightSidePanelFrame)
        view.addSubview(rightSidePanel)
        rightSidePanel.clipsToBounds = true
        
        if sidePanelPosition.isPositionedUnder {
            view.sendSubviewToBack(leftSidePanel)
            view.sendSubviewToBack(rightSidePanel)
        } else {
            centerPanelOverlay = UIView(frame: centerPanel.frame)
            centerPanelOverlay.backgroundColor = _preferences.drawing.centerPanelOverlayColor
            view.bringSubviewToFront(leftSidePanel)
            view.bringSubviewToFront(rightSidePanel)
        }
        
        configureGestureRecognizers()
        view.bringSubviewToFront(statusBarUnderlay)
    }
    
    public func configureGestureRecognizers() {
        
        centerTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        centerTapRecognizer.delegate = self
        
        centerPanel.addGestureRecognizer(centerTapRecognizer)
        
        if sidePanelPosition.isPositionedUnder {
            leftPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleCenterPanelPanFromLeft))
            leftPanRecognizer.delegate = self
            centerPanel.addGestureRecognizer(leftPanRecognizer)
            
            rightPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleCenterPanelPanFromRight))
            rightPanRecognizer.delegate = self
            centerPanel.addGestureRecognizer(rightPanRecognizer)
        } else {
            
            leftPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleSidePanelPanFromLeft))
            leftPanRecognizer.delegate = self
            leftSidePanel.addGestureRecognizer(leftPanRecognizer)
            
            rightPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleSidePanelPanFromRight))
            rightPanRecognizer.delegate = self
            rightSidePanel.addGestureRecognizer(rightPanRecognizer)
            
            leftSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleLeftSwipeFromLeft))
            leftSwipeRecognizer.delegate = self
            leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirection.Left
            
            rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipeFromRight))
            rightSwipeGesture.delegate = self
            rightSwipeGesture.direction = UISwipeGestureRecognizerDirection.Right
            
            centerPanelOverlay.addGestureRecognizer(centerTapRecognizer)
            
            centerPanel.addGestureRecognizer(rightSwipeGesture)
            centerPanelOverlay.addGestureRecognizer(leftSwipeRecognizer)
            
            centerPanel.addGestureRecognizer(leftSwipeRecognizer)
            centerPanelOverlay.addGestureRecognizer(rightSwipeGesture)
        }
    }
    
    func handleLeftSwipeFromLeft(){
        handleLeftSwipe(.LeftSide)
    }
    func handleRightSwipeFromRight(){
        handleLeftSwipe(.RightSide)
    }
    func handleSidePanelPanFromLeft(recognizer: UIPanGestureRecognizer){
        handleSidePanelPan(recognizer, showingSide: sidePanelVisible)
    }
    func handleSidePanelPanFromRight(recognizer: UIPanGestureRecognizer){
        handleSidePanelPan(recognizer, showingSide: sidePanelVisible)
    }
    func handleCenterPanelPanFromLeft(recognizer: UIPanGestureRecognizer){
        handleCenterPanelPan(recognizer, showingSide: sidePanelVisible)
    }
    func handleCenterPanelPanFromRight(recognizer: UIPanGestureRecognizer){
        
        handleCenterPanelPan(recognizer, showingSide: sidePanelVisible)
    }
    
    public func set(statusBarHidden hidden: Bool, animated: Bool = true) {
        
        guard hidesStatusBar else {
            return
        }
        
        let setting = _preferences.animating.statusBarBehaviour
        
        let size = UIScreen.mainScreen().applicationFrame.size
        self.view.window?.frame = CGRectMake(0, 0, size.width, size.height)
        if animated {
            UIApplication.sharedApplication().setStatusBarHidden(hidden, withAnimation: setting.statusBarAnimation)
        } else {
            UIApplication.sharedApplication().statusBarHidden = hidden
        }
        
    }
    
    public func set(statusUnderlayAlpha alpha: CGFloat) {
        guard showsStatusUnderlay else {
            return
        }
        
        if let color = centerNavController?.navigationBar.barTintColor where statusBarUnderlay.backgroundColor != color {
            statusBarUnderlay.backgroundColor = color
        }
        
        statusBarUnderlay.alpha = alpha
    }
    
    func update(centerPanelFrame frame: CGRect) {
        centerPanel.frame = frame
        if _preferences.animating.statusBarBehaviour == .HorizontalPan {
            statusBarWindow?.frame = frame
        }
    }
    
    // MARK:- Containment -
    
    public func prepare(centerControllerForContainment controller: UINavigationController){
        controller.addSideMenuButton()
        controller.view.frame = centerPanel.bounds
    }
    
    public func prepare(sidePanelForDisplay display: Bool){
        
        leftSidePanel.hidden = !display
        rightSidePanel.hidden = !display
        
        if !sidePanelPosition.isPositionedUnder {
            if display && centerPanelOverlay.superview == nil {
                centerPanelOverlay.alpha = 0
                view.insertSubview(self.centerPanelOverlay, belowSubview: self.leftSidePanel)
            }else if !display {
                centerPanelOverlay.removeFromSuperview()
            }
        } else {
            set(sideShadowHidden: display)
        }
    }
    
    public func animate(toReveal reveal: Bool, showingSide: ShowingSide, statusUpdateAnimated: Bool = true){
        
        transitionInProgress = true
        sidePanelVisible = reveal ? showingSide : .None
        set(statusBarHidden: reveal, animated: statusUpdateAnimated)
        
        let setFunction = sidePanelPosition.isPositionedUnder ? setUnderSidePanel : setAboveSidePanel
        setFunction(hidden: !reveal, showingSide: showingSide) { _ in
            if !reveal {
                self.prepare(sidePanelForDisplay: false)
            }
            self.transitionInProgress = false
            self.centerViewController.view.userInteractionEnabled = !reveal
            let delegateMethod = reveal ? self.delegate?.sideMenuControllerDidReveal : self.delegate?.sideMenuControllerDidHide
            delegateMethod?(self)
        }
    }
    
    func handleTap() {
        animate(toReveal: false, showingSide: sidePanelVisible)
    }
    
    // MARK:- .UnderCenterPanelLeft & Right -
    
    public func set(sideShadowHidden hidden: Bool) {
        
        guard _preferences.drawing.centerPanelShadow else {
            return
        }
        
        if hidden {
            centerPanel.layer.shadowOpacity = 0.0
        } else {
            centerPanel.layer.shadowOpacity = 0.8
        }
    }
    
    public func setUnderSidePanel(hidden hidden: Bool, showingSide: ShowingSide, completion: (() -> ())? = nil) {
        
        var centerPanelFrame = centerPanel.frame
        
        if !hidden {
            if showingSide == .LeftSide {
                centerPanelFrame.origin.x = CGRectGetMaxX(leftSidePanel.frame)
                rightSidePanel.superview?.sendSubviewToBack(rightSidePanel)
            }else{
                centerPanelFrame.origin.x = CGRectGetMinX(rightSidePanel.frame) - CGRectGetWidth(centerPanel.frame)
                leftSidePanel.superview?.sendSubviewToBack(leftSidePanel)
            }
        } else {
            centerPanelFrame.origin = CGPointZero
        }
        
        var duration = hidden ? _preferences.animating.hideDuration : _preferences.animating.reavealDuration
        
        if abs(flickVelocity) > 0 {
            let newDuration = NSTimeInterval(leftSidePanel.frame.size.width / abs(flickVelocity))
            flickVelocity = 0
            duration = min(newDuration, duration)
        }
        
        
        UIView.panelAnimation( duration, animations: { _ in
            self.update(centerPanelFrame: centerPanelFrame)
            self.set(statusUnderlayAlpha: hidden ? 0 : 1)
        }) { _ in
            if hidden {
                self.set(sideShadowHidden: hidden)
            }
            completion?()
        }
    }
    
    func handleCenterPanelPan(recognizer: UIPanGestureRecognizer, showingSide: ShowingSide){
        
        guard canDisplaySideController else {
            return
        }
        
        self.flickVelocity = recognizer.velocityInView(recognizer.view).x
        let leftToRight = flickVelocity > 0
        
        switch(recognizer.state) {
            
        case .Began:
            if sidePanelVisible == .None {
                sidePanelVisible = leftToRight ? .LeftSide : .RightSide
                prepare(sidePanelForDisplay: true)
                set(sideShadowHidden: false)
            }
            centerPanel.superview?.sendSubviewToBack(sidePanelVisible == .LeftSide ? rightSidePanel : leftSidePanel)
            
            set(statusBarHidden: true)
            
        case .Changed:
            let translation = recognizer.translationInView(view).x
            let sidePanelFrame = showingSide == .LeftSide ? leftSidePanel.frame:  rightSidePanel.frame
            
            // origin.x or origin.x + width
            let xPoint: CGFloat = centerPanel.center.x + translation +
                (showingSide == .LeftSide ? -1  : 1 ) * CGRectGetWidth(centerPanel.frame) / 2
            
            
            if xPoint < CGRectGetMinX(sidePanelFrame) || xPoint > CGRectGetMaxX(sidePanelFrame){
                return
            }
            
            var alpha: CGFloat
            
            if showingSide == .LeftSide {
                alpha = xPoint / CGRectGetWidth(leftSidePanelFrame)
            }else{
                alpha = 1 - (xPoint - CGRectGetMinX(rightSidePanelFrame)) / CGRectGetWidth(rightSidePanelFrame)
            }
            
            set(statusUnderlayAlpha: alpha)
            var frame = centerPanel.frame
            frame.origin.x += translation
            update(centerPanelFrame: frame)
            recognizer.setTranslation(CGPointZero, inView: view)
            
        default:
            if sidePanelVisible != .None{
                
                var reveal = true
                let centerFrame = centerPanel.frame
                let sideFrame = showingSide == .LeftSide ? leftSidePanel.frame:  rightSidePanel.frame
                
                let shouldOpenPercentage = CGFloat(0.2)
                let shouldHidePercentage = CGFloat(0.8)
                
                if showingSide == .LeftSide {
                    if leftToRight {
                        // opening
                        reveal = CGRectGetMinX(centerFrame) > CGRectGetWidth(sideFrame) * shouldOpenPercentage
                    } else{
                        // closing
                        reveal = CGRectGetMinX(centerFrame) > CGRectGetWidth(sideFrame) * shouldHidePercentage
                    }
                }else{
                    if leftToRight {
                        //closing
                        reveal = CGRectGetMaxX(centerFrame) < CGRectGetMinX(sideFrame) + shouldOpenPercentage * CGRectGetWidth(sideFrame)
                    }else{
                        // opening
                        reveal = CGRectGetMaxX(centerFrame) < CGRectGetMinX(sideFrame) + shouldHidePercentage * CGRectGetWidth(sideFrame)
                    }
                }
                
                animate(toReveal: reveal, showingSide: showingSide)
            }
        }
    }
    
    // MARK:- .OverCenterPanelLeft & Right -
    
    func handleSidePanelPan(recognizer: UIPanGestureRecognizer, showingSide: ShowingSide){
        let sidePanel = showingSide == .LeftSide ? leftSidePanel : rightSidePanel
        guard canDisplaySideController else {
            return
        }
        
        flickVelocity = recognizer.velocityInView(recognizer.view).x
        
        let leftToRight = flickVelocity > 0
        let sidePanelWidth = CGRectGetWidth(sidePanel.frame)
        
        switch recognizer.state {
        case .Began:
            
            prepare(sidePanelForDisplay: true)
            set(statusBarHidden: true)
            
        case .Changed:
            
            let translation = recognizer.translationInView(view).x
            let xPoint: CGFloat = sidePanel.center.x + translation + (showingSide == .LeftSide ? 1 : -1) * sidePanelWidth / 2
            var alpha: CGFloat
            
            if showingSide == .LeftSide {
                if xPoint <= 0 || xPoint > CGRectGetWidth(sidePanel.frame) {
                    return
                }
                alpha = xPoint / CGRectGetWidth(sidePanel.frame)
            }else{
                if xPoint <= screenSize.width - sidePanelWidth || xPoint >= screenSize.width {
                    return
                }
                alpha = 1 - (xPoint - (screenSize.width - sidePanelWidth)) / sidePanelWidth
            }
            
            set(statusUnderlayAlpha: alpha)
            centerPanelOverlay.alpha = alpha
            sidePanel.center.x = sidePanel.center.x + translation
            recognizer.setTranslation(CGPointZero, inView: view)
            
        default:
            
            let shouldClose: Bool
            if showingSide == .LeftSide {
                shouldClose = !leftToRight && CGRectGetMaxX(sidePanel.frame) < sidePanelWidth
            } else {
                shouldClose = leftToRight && CGRectGetMinX(sidePanel.frame) >  (screenSize.width - sidePanelWidth)
            }
            
            animate(toReveal: !shouldClose, showingSide: showingSide)
        }
    }
    
    public func setAboveSidePanel(hidden hidden: Bool, showingSide: ShowingSide, completion: ((Void) -> Void)? = nil){
        let sidePanel = showingSide == .LeftSide ? leftSidePanel : rightSidePanel
        
        var destinationFrame = sidePanel.frame
        
        if showingSide == .LeftSide {
            if hidden {
                destinationFrame.origin.x = -CGRectGetWidth(destinationFrame)
            } else {
                destinationFrame.origin.x = CGRectGetMinX(view.frame)
            }
        } else {
            if hidden {
                destinationFrame.origin.x = CGRectGetMaxX(view.frame)
            } else {
                destinationFrame.origin.x = CGRectGetMaxX(view.frame) - CGRectGetWidth(destinationFrame)
            }
        }
        
        var duration = hidden ? _preferences.animating.hideDuration : _preferences.animating.reavealDuration
        
        if abs(flickVelocity) > 0 {
            let newDuration = NSTimeInterval (destinationFrame.size.width / abs(flickVelocity))
            flickVelocity = 0
            
            if newDuration < duration {
                duration = newDuration
            }
        }
        
        UIView.panelAnimation(duration, animations: { () -> () in
            let alpha = CGFloat(hidden ? 0 : 1)
            self.centerPanelOverlay.alpha = alpha
            self.set(statusUnderlayAlpha: alpha)
            sidePanel.frame = destinationFrame
            }, completion: completion)
    }
    
    func handleLeftSwipe(showingSide: ShowingSide){
        handleHorizontalSwipe(toLeft: true, showingSide: showingSide)
    }
    
    func handleRightSwipe(showingSide: ShowingSide){
        handleHorizontalSwipe(toLeft: false, showingSide: showingSide)
    }
    
    
    func handleHorizontalSwipe(toLeft left: Bool, showingSide: ShowingSide ) {
        if (left && showingSide == .LeftSide) ||
            (!left && showingSide != .LeftSide ) {
            if sidePanelVisible != .None{
                animate(toReveal: false, showingSide: showingSide)
            }
        } else {
            if sidePanelVisible == .None{
                prepare(sidePanelForDisplay: true)
                animate(toReveal: true, showingSide: showingSide)
            }
        }
    }
    
    // MARK:- UIGestureRecognizerDelegate -
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        
        switch gestureRecognizer {
        case leftPanRecognizer:
            return _preferences.interaction.panningEnabled
        case rightPanRecognizer:
            return _preferences.interaction.panningEnabled
        case centerTapRecognizer:
            return sidePanelVisible != .None
        default:
            if gestureRecognizer is UISwipeGestureRecognizer {
                return _preferences.interaction.swipingEnabled
            }
            return true
        }
    }
}