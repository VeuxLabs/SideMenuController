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
    class func panelAnimation(_ duration : TimeInterval, animations : @escaping (()->()), completion : (()->())? = nil) {
        UIView.animate(withDuration: duration, animations: animations, completion: { _ -> Void in
            completion?()
        }) 
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
        
        let leftButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        leftButton.accessibilityIdentifier = SideMenuController.preferences.interaction.menuButtonAccessibilityIdentifier
        leftButton.setImage(image, for: UIControlState())
        leftButton.addTarget(sideMenuController, action: #selector(SideMenuController.toggleLeft), for: UIControlEvents.touchUpInside)
        
        let leftItem:UIBarButtonItem = UIBarButtonItem()
        leftItem.customView = leftButton
        
        let leftSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        leftSpacer.width = -10
        
        let rightButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        rightButton.accessibilityIdentifier = SideMenuController.preferences.interaction.menuButtonAccessibilityIdentifier
        rightButton.setImage(image, for: UIControlState())
        rightButton.addTarget(sideMenuController, action: #selector(SideMenuController.toggleRight), for: UIControlEvents.touchUpInside)
        
        let rightItem:UIBarButtonItem = UIBarButtonItem()
        rightItem.customView = rightButton
        
        let rightSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        rightSpacer.width = -10
        
        self.topViewController?.navigationItem.leftBarButtonItems = [leftSpacer, leftItem]
        self.topViewController?.navigationItem.rightBarButtonItems = [rightSpacer, rightItem]
    }
}

public extension UIViewController {
    
    public var sideMenuController: SideMenuController? {
        return sideMenuControllerForViewController(self)
    }
    
    fileprivate func sideMenuControllerForViewController(_ controller : UIViewController) -> SideMenuController?
    {
        if let sideController = controller as? SideMenuController {
            return sideController
        }
        
        if let parent = controller.parent {
            return sideMenuControllerForViewController(parent)
        } else {
            return nil
        }
    }
}
