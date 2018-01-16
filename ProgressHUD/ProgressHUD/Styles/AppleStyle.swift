//
//  AppleStyle.swift
//  ProgressHUD
//
//  Created by Emiaostein on 15/01/2018.
//  Copyright © 2018 Emiaostein. All rights reserved.
//

import Foundation

public protocol Resourceable: class {
    func applyTo(imageView: UIImageView)->Self
}
extension UIView: Resourceable {
    public func applyTo(imageView: UIImageView)-> Self {
        imageView.superview?.addSubview(self)
        self.center = imageView.center
        return self
    }
}
 extension UIImage: Resourceable {
    public func applyTo(imageView: UIImageView)->Self {
        imageView.image = self
        return self
    }
}

 extension Array where Element == Resourceable {
    public func applyTo(imageView: UIImageView)->Any {
        if self.count == 1 {
            return self[0].applyTo(imageView: imageView)
        } else if let images = self as? [UIImage], self.count > 1 {
            imageView.animationImages = images
            imageView.animationDuration = 0.5
            imageView.startAnimating()
            return self
        }
        
        return self
    }
}



public enum AppleStyle: ProgressHUDFactory {

    public static var resourceMaker: (AppleStyle)->[Resourceable] = createResource
    static var currentStyle: AppleStyle?
    static var resource: Resourceable?
    static weak var hud: UIViewController?
    
    case success(String, String)
    case failture(String, String)
    case loading(String, String)
    case progress(String, String, CGFloat)
    
    public func makeHUD() -> UIViewController {
        let hud = UIStoryboard(name: "AppleStyle", bundle: Bundle(for: ProgressHUD.self)).instantiateViewController(withIdentifier: "StyleA")
        let imageView = hud.view.viewWithTag(100) as! UIImageView
        let titleLabel = hud.view.viewWithTag(101) as! UILabel
        let subTitlelabel = hud.view.viewWithTag(102) as! UILabel
        
        let resource = AppleStyle.resourceMaker(self).applyTo(imageView: imageView)
        
        switch self {
        case .success(let t, let st):
            titleLabel.text = t
            subTitlelabel.text = st
            
        case .failture(let t, let st):
            titleLabel.text = t
            subTitlelabel.text = st
            
        case .loading(let t, let st):
            
            imageView.animationDuration = 0.5
            imageView.startAnimating()
            titleLabel.text = t
            subTitlelabel.text = st
            
        case .progress(let t, let st, let p):
            if let pv = resource as? HUDProgressView {
               AppleStyle.resource = pv
                pv.play(from: 0, to: p, duration: 0)
            }
            
            titleLabel.text = t
            subTitlelabel.text = st
        }
        
        AppleStyle.hud = hud
        AppleStyle.currentStyle = self
        
        return hud
    }
    
    public func update(to: AppleStyle) -> Bool {
        switch to {
        case .progress(let t, let st, let p):
            guard let hud = AppleStyle.hud, let pre = AppleStyle.currentStyle, let pv = AppleStyle.resource as? HUDProgressView else {return false}
            switch pre {
            case .progress(_, _, let preProgress):
                guard preProgress != p else {return false}
                let titleLabel = hud.view.viewWithTag(101) as! UILabel
                let subTitlelabel = hud.view.viewWithTag(102) as! UILabel
                titleLabel.text = t
                subTitlelabel.text = st
                pv.play(from: preProgress, to: p)
                
                AppleStyle.currentStyle = to
                return true
            default:
                return true
            }
        default:
            return false
        }
    }
}


class HUDProgressView: UIView {

    var progress: CAShapeLayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createUI(frame: bounds)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createUI(frame: bounds)
    }
    
    func createUI(frame: CGRect) {
        let lineWidth: CGFloat = 3
        let inset: CGFloat = lineWidth / 2.0
        
        let oval = CAShapeLayer()
        self.layer.addSublayer(oval)
        oval.fillColor   = nil
        oval.strokeColor = UIColor(named: "AppleStyleColor", in: Bundle(for: ProgressHUD.self), compatibleWith: nil)?.cgColor
        oval.lineWidth   = lineWidth
        let ovalFrame = bounds.insetBy(dx: inset, dy: inset)
        oval.frame = ovalFrame
        oval.position = CGPoint(x: bounds.midX, y: bounds.midY)
        oval.path  = UIBezierPath(ovalIn: bounds).cgPath
        
        let len: CGFloat = 1
        let raduis: CGFloat = bounds.insetBy(dx: lineWidth + len, dy: lineWidth + len).width / 2
        let inset2: CGFloat = raduis/2 + lineWidth + len
        let oval2 = CAShapeLayer()
        self.layer.addSublayer(oval2)
//        oval2.lineCap     = kCALineCapRound
//        oval2.lineJoin    = kCALineJoinRound
        oval2.fillColor   = nil
        oval2.strokeColor = UIColor(named: "AppleStyleColor", in: Bundle(for: ProgressHUD.self), compatibleWith: nil)?.cgColor
        oval2.lineWidth   = raduis
        oval2.strokeStart = 0
        oval2.strokeEnd = 0
        let oval2Frame = bounds.insetBy(dx: inset2, dy: inset2)
        oval2.frame = oval2Frame
        oval2.position = CGPoint(x: bounds.midX, y: bounds.midY)
        oval2.path  = UIBezierPath(ovalIn: CGRect(x: lineWidth / 2, y: lineWidth / 2, width: oval2Frame.width, height: oval2Frame.height)).cgPath
        
        progress = oval2
        
        self.transform = CGAffineTransform(rotationAngle: -CGFloat(Double.pi * 0.5))
    }
    
    func play(from: CGFloat, to: CGFloat, duration: TimeInterval = 0.3) {
        
        if duration > 0 {
            ////Oval animation
            let ovalStrokeEndAnim      = CAKeyframeAnimation(keyPath:"strokeEnd")
            ovalStrokeEndAnim.values   = [min(1, from), min(1, to)]
            ovalStrokeEndAnim.keyTimes = [0, 1]
            ovalStrokeEndAnim.duration = duration
            ovalStrokeEndAnim.fillMode = kCAFillModeForwards
            ovalStrokeEndAnim.isRemovedOnCompletion = false
            
            progress.add(ovalStrokeEndAnim, forKey:"ovalUntitled1Anim")
        } else {
            progress.strokeStart = from
            progress.strokeEnd = to
        }
    }
}


var successImage: UIImage?
var failtureImage: UIImage?
var loadingImages: [UIImage]?
func createResource(style: AppleStyle)-> [Resourceable] {
    switch style {
    case .success(_, _):
        if successImage == nil {
            successImage = UIImage(named: "hud-success", in: Bundle(for: ProgressHUD.self), compatibleWith: nil)!
        }
        return [successImage!]
    
    case .failture(_, _):
        if failtureImage == nil {
            failtureImage = UIImage(named: "hud-failture", in: Bundle(for: ProgressHUD.self), compatibleWith: nil)!
        }
        return [failtureImage!]
    case .loading(_, _):
        if loadingImages == nil {
            loadingImages = (0..<8).map{UIImage(named: "hud-loading-\($0)", in: Bundle(for: ProgressHUD.self), compatibleWith: nil)!}
        }
        return loadingImages!
    case .progress(_, _, _):
        let v = HUDProgressView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        return [v]
    }
}
