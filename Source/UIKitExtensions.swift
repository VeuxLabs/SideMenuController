//
//  UIKitExtensions.swift
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

import Foundation

extension UIView {
    class func panelAnimation(duration : NSTimeInterval, animations : (()->()), completion : (()->())? = nil) {
        UIView.animateWithDuration(duration, animations: animations) { _ -> Void in
            completion?()
        }
    }
}

public extension UINavigationController {
    public func addSideMenuButton() {
        guard let image = SideMenuController.preferences.drawing.menuButtonImage else {
            return
        }
        
        guard let sideMenuController = self.sideMenuController else {
            return
        }
        
        let leftButton = UIButton(frame: CGRectMake(0, 0, 40, 40))
        leftButton.accessibilityIdentifier = SideMenuController.preferences.interaction.menuButtonAccessibilityIdentifier
        leftButton.setImage(image, forState: UIControlState.Normal)
        leftButton.addTarget(sideMenuController, action: #selector(SideMenuController.toggleLeft), forControlEvents: UIControlEvents.TouchUpInside)
        
        let leftItem:UIBarButtonItem = UIBarButtonItem()
        leftItem.customView = leftButton
        
        let leftSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        leftSpacer.width = -10
        
        /////////////
        let rightButton = UIButton(frame: CGRectMake(0, 0, 40, 40))
        rightButton.accessibilityIdentifier = SideMenuController.preferences.interaction.menuButtonAccessibilityIdentifier
        rightButton.setImage(image, forState: UIControlState.Normal)
        rightButton.addTarget(sideMenuController, action: #selector(SideMenuController.toggleRight), forControlEvents: UIControlEvents.TouchUpInside)
        
        let rightItem:UIBarButtonItem = UIBarButtonItem()
        rightItem.customView = rightButton
        
        let rightSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        rightSpacer.width = -10
        
        self.topViewController?.navigationItem.leftBarButtonItems = [leftSpacer, leftItem]
        self.topViewController?.navigationItem.rightBarButtonItems = [rightSpacer, rightItem]
    }
}

public extension UIViewController {
    
    public var sideMenuController: SideMenuController? {
        return sideMenuControllerForViewController(self)
    }
    
    private func sideMenuControllerForViewController(controller : UIViewController) -> SideMenuController?
    {
        if let sideController = controller as? SideMenuController {
            return sideController
        }
        
        if let parent = controller.parentViewController {
            return sideMenuControllerForViewController(parent)
        } else {
            return nil
        }
    }
}
