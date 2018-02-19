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
    func sideMenuControllerDidHide(_ sideMenuController: SideMenuController)
    func sideMenuControllerDidReveal(_ sideMenuController: SideMenuController)
}


public extension SideMenuController {
    
    /**
     Toggles the side pannel visible or not.
     */
    @objc public func toggleRight() {
        
        if !transitionInProgress {
            if sidePanelVisible == .none{
                prepare(sidePanelForDisplay: true)
            }
            
            animate(toReveal: sidePanelVisible ==  .none, showingSide: .rightSide)
        }
    }
    
    @objc public func toggleLeft() {
        
        if !transitionInProgress {
            if sidePanelVisible  ==  .none {
                prepare(sidePanelForDisplay: true)
            }
            
            animate(toReveal: sidePanelVisible  ==  .none, showingSide: .leftSide)
        }
    }
    
    /**
     Embeds a new side controller
     
     - parameter sideViewController: controller to be embedded
     */
    @objc public func embed(leftViewController: UIViewController, rightViewController: UIViewController) {
        if leftSideViewController == nil {
            
            leftSideViewController = leftViewController
            leftSideViewController.view.frame = leftSidePanel.bounds
            
            leftSidePanel.addSubview(leftSideViewController.view)
            
            addChildViewController(leftSideViewController)
            leftSideViewController.didMove(toParentViewController: self)
            
            leftSidePanel.isHidden = true
        }
        if rightSideViewController == nil {
            
            rightSideViewController = rightViewController
            rightSideViewController.view.frame = rightSidePanel.bounds
            
            rightSidePanel.addSubview(rightSideViewController.view)
            
            addChildViewController(rightSideViewController)
            rightSideViewController.didMove(toParentViewController: self)
            
            rightSidePanel.isHidden = true
        }
    }
    
    /**
     Embeds a new center controller.
     
     - parameter centerViewController: controller to be embedded
     */
    @objc public func embed(centerViewController controller: UIViewController) {
        
        addChildViewController(controller)
        if let controller = controller as? UINavigationController {
            prepare(centerControllerForContainment: controller)
        }
        centerPanel.addSubview(controller.view)
        
        if centerViewController == nil {
            centerViewController = controller
            centerViewController.didMove(toParentViewController: self)
        } else {
            centerViewController.willMove(toParentViewController: nil)
            
            let completion: () -> () = {
                self.centerViewController.view.removeFromSuperview()
                self.centerViewController.removeFromParentViewController()
                controller.didMove(toParentViewController: self)
                self.centerViewController = controller
            }
            
            if let animator = _preferences.animating.transitionAnimator {
                animator.performTransition(forView: controller.view, completion: completion)
            } else {
                completion()
            }
            
            if sidePanelVisible  !=  .none {
                animate(toReveal: false, showingSide: .leftSide ,statusUpdateAnimated: false)
            }
        }
    }
}

// MARK: - Public methods -

open class SideMenuController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK:- Custom types -
    
    public enum SidePanelPosition {
        case underCenterPanel
        case overCenterPanel
        
        var isPositionedUnder: Bool {
            return self == SidePanelPosition.underCenterPanel
        }
        
    }
    
    public enum ShowingSide {
        case none
        case leftSide
        case rightSide
    }
    
    public enum StatusBarBehaviour {
        case slideAnimation
        case fadeAnimation
        case horizontalPan
        case showUnderlay
        
        var statusBarAnimation: UIStatusBarAnimation {
            switch self {
            case .fadeAnimation:
                return .fade
            case .slideAnimation:
                return .slide
            default:
                return .none
            }
        }
    }
    
    public struct Preferences {
        public struct Drawing {
            public var menuButtonImage: UIImage?
            public var sidePanelPosition = SidePanelPosition.underCenterPanel
            public var leftSidePanelWidth: CGFloat = 300
            public var rightSidePanelWidth: CGFloat = 300
            public var centerPanelOverlayColor = UIColor(hue:0.15, saturation:0.21, brightness:0.17, alpha:0.6)
            public var centerPanelShadow = false
        }
        
        public struct Animating {
            public var statusBarBehaviour = StatusBarBehaviour.slideAnimation
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
    
    open weak var delegate: SideMenuControllerDelegate?
    open static var preferences: Preferences = Preferences()
    open(set) open var sidePanelVisible = ShowingSide.none
    
    // MARK: public
    
    open lazy var _preferences: Preferences = {
        return type(of: self).preferences
    }()
    
    open var centerViewController: UIViewController!
    open var centerNavController: UINavigationController? {
        return centerViewController as? UINavigationController
    }
    @objc open var leftSideViewController: UIViewController!
    @objc open var rightSideViewController: UIViewController!
    open var statusBarUnderlay: UIView!
    open var centerPanel: UIView!
    open var leftSidePanel: UIView!
    open var rightSidePanel: UIView!
    open var centerPanelOverlay: UIView!
    open var leftSwipeRecognizer: UISwipeGestureRecognizer!
    open var rightSwipeGesture: UISwipeGestureRecognizer!
    open var leftPanRecognizer: UIPanGestureRecognizer!
    open var rightPanRecognizer: UIPanGestureRecognizer!
    open var centerTapRecognizer: UITapGestureRecognizer!
    
    open var transitionInProgress = false
    open var flickVelocity: CGFloat = 0
    
    open lazy var screenSize: CGSize = {
        return UIScreen.main.bounds.size
    }()
    
    open lazy var sidePanelPosition: SidePanelPosition = {
        return self._preferences.drawing.sidePanelPosition
    }()
    
    // MARK: Internal
    
    
    // MARK: Computed
    
    open var statusBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.size.height > 0 ? UIApplication.shared.statusBarFrame.size.height : 20
    }
    
    open var hidesStatusBar: Bool {
        return [.slideAnimation, .fadeAnimation].contains(_preferences.animating.statusBarBehaviour)
    }
    
    open var showsStatusUnderlay: Bool {
        
        guard _preferences.animating.statusBarBehaviour == .showUnderlay else {
            return false
        }
        
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            return true
        }
        
        return screenSize.width < screenSize.height
    }
    
    open var canDisplaySideController: Bool {
        return (leftSideViewController != nil) && (rightSideViewController != nil)
    }
    
    open var centerPanelFrame: CGRect {
        
        if sidePanelPosition.isPositionedUnder && sidePanelVisible != .none {
            
            let sidePanelWidth = _preferences.drawing.leftSidePanelWidth
            return CGRect(x: sidePanelWidth, y: 0, width: screenSize.width, height: screenSize.height)
            
        } else {
            return CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
        }
    }
    
    open var leftSidePanelFrame: CGRect {
        var sidePanelFrame: CGRect
        
        let panelWidth = _preferences.drawing.leftSidePanelWidth
        
        if sidePanelPosition.isPositionedUnder {
            sidePanelFrame = CGRect(x: 0, y: 0, width: panelWidth, height: screenSize.height)
        } else {
            if sidePanelVisible != .none {
                sidePanelFrame = CGRect(x: 0, y: 0, width: panelWidth, height: screenSize.height)
            } else {
                sidePanelFrame = CGRect(x: -panelWidth, y: 0, width: panelWidth, height: screenSize.height)
            }
        }
        
        return sidePanelFrame
    }
    
    open var rightSidePanelFrame: CGRect {
        var sidePanelFrame: CGRect
        
        let panelWidth = _preferences.drawing.rightSidePanelWidth
        
        if sidePanelPosition.isPositionedUnder {
            sidePanelFrame = CGRect(x: screenSize.width - panelWidth, y: 0, width: panelWidth, height: screenSize.height)
        } else {
            if sidePanelVisible != .none {
                sidePanelFrame = CGRect(x: screenSize.width - panelWidth, y: 0, width: panelWidth, height: screenSize.height)
            } else {
                sidePanelFrame = CGRect(x: screenSize.width, y: 0, width: panelWidth, height: screenSize.height)
            }
        }
        
        return sidePanelFrame
    }
    
    open var statusBarWindow: UIWindow? {
        return UIApplication.shared.value(forKey: "statusBarWindow") as? UIWindow
    }
    
    // MARK:- View lifecycle -
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpViewHierarchy()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setUpViewHierarchy()
    }
    
    open func setUpViewHierarchy() {
        view = UIView(frame: UIScreen.main.bounds)
        configureViews()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if sidePanelVisible == .leftSide {
            toggleLeft()
        }
        
        if sidePanelVisible == .rightSide {
            toggleRight()
        }
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        screenSize = size
        
        coordinator.animate(alongsideTransition: { _ in
            // reposition center panel
            self.update(centerPanelFrame: self.centerPanelFrame)
            // reposition side panel
            self.leftSidePanel.frame = self.leftSidePanelFrame
            self.rightSidePanel.frame = self.rightSidePanelFrame
            
            // hide or show the view under the status bar
            self.set(statusUnderlayAlpha: self.sidePanelVisible != .none ? 1 : 0)
            
            // reposition the center shadow view
            if let overlay = self.centerPanelOverlay {
                overlay.frame = self.centerPanelFrame
            }
            
            self.view.layoutIfNeeded()
            
            }, completion: nil)
    }
    
    // MARK: - Configurations -
    
    open func configureViews(){
        
        centerPanel = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        view.addSubview(centerPanel)
        
        statusBarUnderlay = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: statusBarHeight))
        view.addSubview(statusBarUnderlay)
        statusBarUnderlay.alpha = 0
        
        leftSidePanel = UIView(frame: leftSidePanelFrame)
        view.addSubview(leftSidePanel)
        leftSidePanel.clipsToBounds = true
        
        rightSidePanel = UIView(frame: rightSidePanelFrame)
        view.addSubview(rightSidePanel)
        rightSidePanel.clipsToBounds = true
        
        if sidePanelPosition.isPositionedUnder {
            view.sendSubview(toBack: leftSidePanel)
            view.sendSubview(toBack: rightSidePanel)
        } else {
            centerPanelOverlay = UIView(frame: centerPanel.frame)
            centerPanelOverlay.backgroundColor = _preferences.drawing.centerPanelOverlayColor
            view.bringSubview(toFront: leftSidePanel)
            view.bringSubview(toFront: rightSidePanel)
        }
        
        configureGestureRecognizers()
        view.bringSubview(toFront: statusBarUnderlay)
    }
    
    open func configureGestureRecognizers() {
        
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
            leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirection.left
            
            rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipeFromRight))
            rightSwipeGesture.delegate = self
            rightSwipeGesture.direction = UISwipeGestureRecognizerDirection.right
            
            centerPanelOverlay.addGestureRecognizer(centerTapRecognizer)
            
            centerPanel.addGestureRecognizer(rightSwipeGesture)
            centerPanelOverlay.addGestureRecognizer(leftSwipeRecognizer)
            
            centerPanel.addGestureRecognizer(leftSwipeRecognizer)
            centerPanelOverlay.addGestureRecognizer(rightSwipeGesture)
        }
    }
    
    @objc func handleLeftSwipeFromLeft(){
        handleLeftSwipe(.leftSide)
    }
    @objc func handleRightSwipeFromRight(){
        handleLeftSwipe(.rightSide)
    }
    @objc func handleSidePanelPanFromLeft(_ recognizer: UIPanGestureRecognizer){
        handleSidePanelPan(recognizer, showingSide: sidePanelVisible)
    }
    @objc func handleSidePanelPanFromRight(_ recognizer: UIPanGestureRecognizer){
        handleSidePanelPan(recognizer, showingSide: sidePanelVisible)
    }
    @objc func handleCenterPanelPanFromLeft(_ recognizer: UIPanGestureRecognizer){
        handleCenterPanelPan(recognizer, showingSide: sidePanelVisible)
    }
    @objc func handleCenterPanelPanFromRight(_ recognizer: UIPanGestureRecognizer){
        
        handleCenterPanelPan(recognizer, showingSide: sidePanelVisible)
    }
    
    open func set(statusBarHidden hidden: Bool, animated: Bool = true) {
        
        guard hidesStatusBar else {
            return
        }
        
        let setting = _preferences.animating.statusBarBehaviour
        
        let size = UIScreen.main.bounds
        self.view.window?.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        if animated {
            UIApplication.shared.setStatusBarHidden(hidden, with: setting.statusBarAnimation)
        } else {
            UIApplication.shared.isStatusBarHidden = hidden
        }
        
    }
    
    open func set(statusUnderlayAlpha alpha: CGFloat) {
        guard showsStatusUnderlay else {
            return
        }
        
        if let color = centerNavController?.navigationBar.barTintColor, statusBarUnderlay.backgroundColor != color {
            statusBarUnderlay.backgroundColor = color
        }
        
        statusBarUnderlay.alpha = alpha
    }
    
    func update(centerPanelFrame frame: CGRect) {
        centerPanel.frame = frame
        if _preferences.animating.statusBarBehaviour == .horizontalPan {
            statusBarWindow?.frame = frame
        }
    }
    
    // MARK:- Containment -
    
    open func prepare(centerControllerForContainment controller: UINavigationController){
        controller.addSideMenuButton()
        controller.view.frame = centerPanel.bounds
    }
    
    open func prepare(sidePanelForDisplay display: Bool){
        
        leftSidePanel.isHidden = !display
        rightSidePanel.isHidden = !display
        
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
    
    open func animate(toReveal reveal: Bool, showingSide: ShowingSide, statusUpdateAnimated: Bool = true){
        
        transitionInProgress = true
        sidePanelVisible = reveal ? showingSide : .none
        set(statusBarHidden: reveal, animated: statusUpdateAnimated)
        
        let setFunction = sidePanelPosition.isPositionedUnder ? setUnderSidePanel : setAboveSidePanel
        setFunction(!reveal, showingSide) {
            if !reveal {
                self.prepare(sidePanelForDisplay: false)
            }
            self.transitionInProgress = false
            self.centerViewController.view.isUserInteractionEnabled = !reveal
            let delegateMethod = reveal ? self.delegate?.sideMenuControllerDidReveal : self.delegate?.sideMenuControllerDidHide
            delegateMethod?(self)
        }
    }
    
    @objc func handleTap() {
        animate(toReveal: false, showingSide: sidePanelVisible)
    }
    
    // MARK:- .UnderCenterPanelLeft & Right -
    
    open func set(sideShadowHidden hidden: Bool) {
        
        guard _preferences.drawing.centerPanelShadow else {
            return
        }
        
        if hidden {
            centerPanel.layer.shadowOpacity = 0.0
        } else {
            centerPanel.layer.shadowOpacity = 0.8
        }
    }
    
    open func setUnderSidePanel(hidden: Bool, showingSide: ShowingSide, completion: (() -> ())? = nil) {
        
        var centerPanelFrame = centerPanel.frame
        
        if !hidden {
            if showingSide == .leftSide {
                centerPanelFrame.origin.x = leftSidePanel.frame.maxX
                rightSidePanel.superview?.sendSubview(toBack: rightSidePanel)
            }else{
                centerPanelFrame.origin.x = rightSidePanel.frame.minX - centerPanel.frame.width
                leftSidePanel.superview?.sendSubview(toBack: leftSidePanel)
            }
        } else {
            centerPanelFrame.origin = CGPoint.zero
        }
        
        var duration = hidden ? _preferences.animating.hideDuration : _preferences.animating.reavealDuration
        
        if abs(flickVelocity) > 0 {
            let newDuration = TimeInterval(leftSidePanel.frame.size.width / abs(flickVelocity))
            flickVelocity = 0
            duration = min(newDuration, duration)
        }
        
        
        UIView.panelAnimation( duration, animations: {
            self.update(centerPanelFrame: centerPanelFrame)
            self.set(statusUnderlayAlpha: hidden ? 0 : 1)
        }) {
            if hidden {
                self.set(sideShadowHidden: hidden)
            }
            completion?()
        }
    }
    
    func handleCenterPanelPan(_ recognizer: UIPanGestureRecognizer, showingSide: ShowingSide){
        
        guard canDisplaySideController else {
            return
        }
        
        self.flickVelocity = recognizer.velocity(in: recognizer.view).x
        let leftToRight = flickVelocity > 0
        
        switch(recognizer.state) {
            
        case .began:
            if sidePanelVisible == .none {
                sidePanelVisible = leftToRight ? .leftSide : .rightSide
                prepare(sidePanelForDisplay: true)
                set(sideShadowHidden: false)
            }
            centerPanel.superview?.sendSubview(toBack: sidePanelVisible == .leftSide ? rightSidePanel : leftSidePanel)
            
            set(statusBarHidden: true)
            
        case .changed:
            let translation = recognizer.translation(in: view).x
            let sidePanelFrame = showingSide == .leftSide ? leftSidePanel.frame:  rightSidePanel.frame
            
            // origin.x or origin.x + width
            let xPoint: CGFloat = centerPanel.center.x + translation +
                (showingSide == .leftSide ? -1  : 1 ) * centerPanel.frame.width / 2
            
            
            if xPoint < sidePanelFrame.minX || xPoint > sidePanelFrame.maxX{
                return
            }
            
            var alpha: CGFloat
            
            if showingSide == .leftSide {
                alpha = xPoint / leftSidePanelFrame.width
            }else{
                alpha = 1 - (xPoint - rightSidePanelFrame.minX) / rightSidePanelFrame.width
            }
            
            set(statusUnderlayAlpha: alpha)
            var frame = centerPanel.frame
            frame.origin.x += translation
            update(centerPanelFrame: frame)
            recognizer.setTranslation(CGPoint.zero, in: view)
            
        default:
            if sidePanelVisible != .none{
                
                var reveal = true
                let centerFrame = centerPanel.frame
                let sideFrame = showingSide == .leftSide ? leftSidePanel.frame:  rightSidePanel.frame
                
                let shouldOpenPercentage = CGFloat(0.2)
                let shouldHidePercentage = CGFloat(0.8)
                
                if showingSide == .leftSide {
                    if leftToRight {
                        // opening
                        reveal = centerFrame.minX > sideFrame.width * shouldOpenPercentage
                    } else{
                        // closing
                        reveal = centerFrame.minX > sideFrame.width * shouldHidePercentage
                    }
                }else{
                    if leftToRight {
                        //closing
                        reveal = centerFrame.maxX < sideFrame.minX + shouldOpenPercentage * sideFrame.width
                    }else{
                        // opening
                        reveal = centerFrame.maxX < sideFrame.minX + shouldHidePercentage * sideFrame.width
                    }
                }
                
                animate(toReveal: reveal, showingSide: showingSide)
            }
        }
    }
    
    // MARK:- .OverCenterPanelLeft & Right -
    
    func handleSidePanelPan(_ recognizer: UIPanGestureRecognizer, showingSide: ShowingSide){
        let sidePanel = showingSide == .leftSide ? leftSidePanel : rightSidePanel
        guard canDisplaySideController else {
            return
        }
        
        flickVelocity = recognizer.velocity(in: recognizer.view).x
        
        let leftToRight = flickVelocity > 0
        let sidePanelWidth = sidePanel?.frame.width
        
        switch recognizer.state {
        case .began:
            
            prepare(sidePanelForDisplay: true)
            set(statusBarHidden: true)
            
        case .changed:
            
            let translation = recognizer.translation(in: view).x
            let xPoint: CGFloat = sidePanel!.center.x + translation + (showingSide == .leftSide ? 1 : -1) * sidePanelWidth! / 2
            var alpha: CGFloat
            
            if showingSide == .leftSide {
                if xPoint <= 0 || xPoint > (sidePanel?.frame.width)! {
                    return
                }
                alpha = xPoint / (sidePanel?.frame.width)!
            }else{
                if xPoint <= screenSize.width - sidePanelWidth! || xPoint >= screenSize.width {
                    return
                }
                alpha = 1 - (xPoint - (screenSize.width - sidePanelWidth!)) / sidePanelWidth!
            }
            
            set(statusUnderlayAlpha: alpha)
            centerPanelOverlay.alpha = alpha
            sidePanel?.center.x = (sidePanel?.center.x)! + translation
            recognizer.setTranslation(CGPoint.zero, in: view)
            
        default:
            
            let shouldClose: Bool
            if showingSide == .leftSide {
                shouldClose = !leftToRight && sidePanel!.frame.maxX < sidePanelWidth!
            } else {
                shouldClose = leftToRight && (sidePanel?.frame.minX)! >  (screenSize.width - sidePanelWidth!)
            }
            
            animate(toReveal: !shouldClose, showingSide: showingSide)
        }
    }
    
    open func setAboveSidePanel(hidden: Bool, showingSide: ShowingSide, completion: (() -> Void)? = nil){
        let sidePanel = showingSide == .leftSide ? leftSidePanel : rightSidePanel
        
        var destinationFrame = sidePanel?.frame
        
        if showingSide == .leftSide {
            if hidden {
                let destinationFrameCopy = destinationFrame
                destinationFrame?.origin.x = -(destinationFrameCopy?.width)!
            } else {
                destinationFrame?.origin.x = view.frame.minX
            }
        } else {
            if hidden {
                destinationFrame?.origin.x = view.frame.maxX
            } else {
                let destinationFrameCopy = destinationFrame
                destinationFrame?.origin.x = view.frame.maxX - (destinationFrameCopy?.width)!
            }
        }
        
        var duration = hidden ? _preferences.animating.hideDuration : _preferences.animating.reavealDuration
        
        if abs(flickVelocity) > 0 {
            let newDuration = TimeInterval ((destinationFrame?.size.width)! / abs(flickVelocity))
            flickVelocity = 0
            
            if newDuration < duration {
                duration = newDuration
            }
        }
        
        UIView.panelAnimation(duration, animations: { () -> () in
            let alpha = CGFloat(hidden ? 0 : 1)
            self.centerPanelOverlay.alpha = alpha
            self.set(statusUnderlayAlpha: alpha)
            sidePanel?.frame = destinationFrame!
            }, completion: completion)
    }
    
    func handleLeftSwipe(_ showingSide: ShowingSide){
        handleHorizontalSwipe(toLeft: true, showingSide: showingSide)
    }
    
    func handleRightSwipe(_ showingSide: ShowingSide){
        handleHorizontalSwipe(toLeft: false, showingSide: showingSide)
    }
    
    
    func handleHorizontalSwipe(toLeft left: Bool, showingSide: ShowingSide ) {
        if (left && showingSide == .leftSide) ||
            (!left && showingSide != .leftSide ) {
            if sidePanelVisible != .none{
                animate(toReveal: false, showingSide: showingSide)
            }
        } else {
            if sidePanelVisible == .none{
                prepare(sidePanelForDisplay: true)
                animate(toReveal: true, showingSide: showingSide)
            }
        }
    }
    
    // MARK:- UIGestureRecognizerDelegate -
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        switch gestureRecognizer {
        case leftPanRecognizer:
            return _preferences.interaction.panningEnabled
        case rightPanRecognizer:
            return _preferences.interaction.panningEnabled
        case centerTapRecognizer:
            return sidePanelVisible != .none
        default:
            if gestureRecognizer is UISwipeGestureRecognizer {
                return _preferences.interaction.swipingEnabled
            }
            return true
        }
    }
}
