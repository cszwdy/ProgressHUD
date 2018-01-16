//
//  AppleHUD.swift
//  ProgressHUD
//
//  Created by Emiaostein on 16/01/2018.
//  Copyright © 2018 Emiaostein. All rights reserved.
//

import Foundation

public struct Apple: ProgressHUDFactory {
    
    public enum Resource {
        case success
        case failture
        case loading
        case progress(CGFloat)
    }
    
    public static var resourceMaker:(Resource)->(UIImageView)->() = makeResource
    
    let title: String
    let subTitle: String
    let resource: Resource
    
   public init(_ resource: Resource, _ title: String, _ subTitle: String) {
        self.resource = resource
        self.title = title
        self.subTitle = subTitle
    }
    
    public func makeHUD() -> UIViewController {
        let hud = UIStoryboard(name: "Apple", bundle: Bundle(for: ProgressHUD.self)).instantiateViewController(withIdentifier: "AppleLight")
        
        let titleLabel = hud.view.viewWithTag(101) as! UILabel
        let subTitleLabel = hud.view.viewWithTag(102) as! UILabel
        let imageView = hud.view.viewWithTag(100) as! UIImageView
        
        titleLabel.text = title
        subTitleLabel.text = subTitle
        Apple.resourceMaker(resource)(imageView)
        
        Apple.hud = hud
        Apple.apple = self
        
        return hud
    }
    
    static var apple: Apple?
    static weak var hud: UIViewController?
    public func update(to: Apple) -> Bool {
        guard let hud = Apple.hud, let pre = Apple.apple else {
            return false
        }
        let t = to.title
        let st = to.subTitle
        let r = to.resource
        
        switch (pre.resource, r) {
        case (.progress(let p1), .progress(let p2)):
            var pu = false
            var tu = false
            var  stu = false
            if let progressView = hud.view.viewWithTag(100)?.viewWithTag(200) as? ProgressView, p1 != p2 {
                Apple.apple = to
                progressView.play(from: p1, to: p2)
                pu = true
            }
            
            if let titleLabel = hud.view.viewWithTag(101) as? UILabel {
                titleLabel.text = t
                tu = true
            }
            
            if let subTitleLabel = hud.view.viewWithTag(102) as? UILabel {
                subTitleLabel.text = st
                stu = true
            }
            
             return pu || tu || stu
            
        default:
            return false
        }
    }
}

class ProgressView: UIView {
    
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
        if #available(iOS 11.0, *) {
            oval.strokeColor = UIColor(named: "AppleStyleColor", in: Bundle(for: ProgressHUD.self), compatibleWith: nil)?.cgColor
        } else {
            // Fallback on earlier versions
            let v: CGFloat = 68.0/255.0
            oval.strokeColor = UIColor(red: v, green: v, blue: v, alpha: 1.0).cgColor
        }
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
        if #available(iOS 11.0, *) {
            oval2.strokeColor = UIColor(named: "AppleStyleColor", in: Bundle(for: ProgressHUD.self), compatibleWith: nil)?.cgColor
        } else {
            // Fallback on earlier versions
            let v: CGFloat = 68.0/255.0
            oval2.strokeColor = UIColor(red: v, green: v, blue: v, alpha: 1.0).cgColor
        }
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

func makeResource(r: Apple.Resource)->(UIImageView)->() {
    
    switch r {
    case .success:
        return {(imgView: UIImageView) in imgView.image = UIImage(named: "hud-success", in: Bundle(for: ProgressHUD.self), compatibleWith: nil)}
    case .failture:
        return {(imgView: UIImageView) in imgView.image = UIImage(named: "hud-failture", in: Bundle(for: ProgressHUD.self), compatibleWith: nil)}
    case .loading:
        return {(imgView: UIImageView) in
            imgView.animationImages = (0..<8).map{UIImage(named: "hud-loading-\($0)", in: Bundle(for: ProgressHUD.self), compatibleWith: nil)!}
            imgView.animationDuration = 0.5
            imgView.startAnimating()
        }
    case .progress(let p):
        return {(imgView: UIImageView) in
            let a = imgView.bounds.size
            let b = CGSize(width: 60, height: 60)
            let progressView = ProgressView(frame: imgView.bounds.insetBy(dx: (a.width - b.width)/2, dy: (a.height - b.height)/2))
            progressView.tag = 200
            progressView.play(from: 0, to: p, duration: 0)
            imgView.addSubview(progressView)
        }
    }
}
