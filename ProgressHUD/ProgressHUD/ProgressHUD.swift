//
//  ProgressHUD.swift
//  ProgressHUD
//
//  Created by Emiaostein on 15/01/2018.
//  Copyright © 2018 Emiaostein. All rights reserved.
//

import Foundation

public protocol ProgressHUDFactory {
    
    func makeHUD() -> UIViewController
    func update(to: Self) -> Bool
}

public enum ProgressHUDState {
    case presenting
    case cancelling
    case dismissing
    case dismissed
}

public final class ProgressHUD {
    public typealias Style = ProgressHUDFactory
    
    static private(set) var state: ProgressHUDState = .dismissed
    static private var sentryCount = 0 // Use to cancel the out of date async action
    static private var isUseDefaultAnimated = true {
        didSet {ProgressHUDContainerViewController.animated = isUseDefaultAnimated }
    }
    static private weak var container: ProgressHUDContainerViewController?
    static private var topest: UIViewController? {
        var top = UIApplication.shared.keyWindow?.rootViewController
        while top?.presentedViewController != nil {
            top = top?.presentedViewController
        }
        return top
    }
    
    public static func present<T: Style>(style: T, dismissDelay: TimeInterval = .infinity, completed:(()->())? = nil) {
        DispatchQueue.main.async {
            guard let top = topest else { return }
            
            switch state {
            case .presenting:
                cancelAndPresentpresent(style: style,
                                        top: top,
                                        dismissDelay: dismissDelay,
                                        completed: completed)
            case .cancelling:
                return
                
            case .dismissing:
                cancelAndPresentpresent(style: style,
                                        top: top,
                                        dismissDelay: dismissDelay,
                                        completed: completed)
                
            case .dismissed:
                present(style: style,
                        top: top,
                        dismissDelay: dismissDelay,
                        completed: completed)
            }
        }
        
    }
    
    public static func update<T: Style>(style: T) {
        DispatchQueue.main.async {
            let _ = style.update(to: style)
        }
    }
    
    public static func dismiss(delay:TimeInterval = 0, completed:(()->())? = nil) {
        DispatchQueue.main.async {
            let i = sentryCount
            willDismiss(cachedSentryCount: i, delay: delay, completed: completed)
        }
    }
}

private extension ProgressHUD {
    
    static func cancelAndPresentpresent<T: Style>(style: T, top: UIViewController, dismissDelay: TimeInterval, completed:(()->())?) {
        sentryCount += 1
        let i = sentryCount
        willCancel {
            guard i == sentryCount else {return}
            willPresent(style: style, top: top, completed: {
                guard i == sentryCount else {return}
                completed?()
                willDismiss(cachedSentryCount: i, delay: dismissDelay, completed: {
                    guard i == sentryCount else {return}
                    sentryCount -= 1
                })
            })
        }
    }
    
    
    static func present<T: Style>(style: T, top: UIViewController, dismissDelay: TimeInterval, completed:(()->())?) {
        sentryCount += 1
        let i = sentryCount
        willPresent(style: style, top: top, completed: {
            guard i == sentryCount else {return}
            completed?()
            willDismiss(cachedSentryCount: i, delay: dismissDelay, completed: {
                guard i == sentryCount else {return}
                sentryCount -= 1
            })
        })
    }
    
    
    static func willCancel(completed:@escaping ()->()) {
        state = .cancelling
        if let container = container {
            container.disappear(completed: { (hud) in
                hud.view.removeFromSuperview()
                hud.removeFromParentViewController()
                completed()
            })
        } else {
            completed()
        }
    }
    
    static func willPresent<T: Style>(style: T, top: UIViewController, completed:()->()) {
        state = .presenting
        guard let top = topest else {
            completed()
            return
        }
        
        let hud = style.makeHUD()
        let hudContainer = ProgressHUDContainerViewController(hud: hud)
        top.addChildViewController(hudContainer)
        top.view.addSubview(hudContainer.view)
        if let container = container {
            container.view.removeFromSuperview()
            container.removeFromParentViewController()
        }
        
        container = hudContainer
        completed()
    }
    
    static func willDismiss(cachedSentryCount: Int, delay: TimeInterval, completed:(()->())?) {
        state = .dismissing
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard cachedSentryCount == sentryCount else {
                return
            }
            if let container = container {
                container.disappear(completed: { (hud) in
                    hud.view.removeFromSuperview()
                    hud.removeFromParentViewController()
                    state  = .dismissed
                    completed?()
                })
            } else {
                state = .dismissed
                completed?()
            }
        }
    }
}

private final class ProgressHUDContainerViewController: UIViewController {
    
    static var animated = true
    let hud: UIViewController
    
    init(hud: UIViewController) {
        self.hud = hud
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChildViewController(hud)
        view.addSubview(hud.view)
        hud.view.alpha = 0.0
        hud.view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard ProgressHUDContainerViewController.animated == true else {
            return
        }
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {[weak self] in
            guard let sf = self else {return}
            sf.hud.view.alpha = 1.0
            sf.hud.view.transform = .identity
        }) { (position) in
        }
    }
    
    func disappear(completed:@escaping (UIViewController)->()) {
        guard ProgressHUDContainerViewController.animated == true else {
            completed(self)
            return
        }
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {[weak self] in
            guard let sf = self else {return}
            sf.hud.view.alpha = 0.0
            sf.hud.view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { [weak self] (position) in
            guard let sf = self else {return}
            completed(sf)
        }
    }
}
