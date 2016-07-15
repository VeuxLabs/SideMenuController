//
//  SideMenuController+Extension.swift
//  SideMenuController
//
//  Created by Miguel Ureña on 7/14/16.
//  Copyright © 2016 teodorpatras. All rights reserved.
//


import UIKit

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