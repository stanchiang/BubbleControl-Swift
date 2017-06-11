//
//  BubbleControl.swift
//  BubbleControl-Swift
//
//  Created by Cem Olcay on 11/12/14.
//  Copyright (c) 2014 Cem Olcay. All rights reserved.
//

import UIKit

let APPDELEGATE: AppDelegate = UIApplication.shared.delegate as! AppDelegate



// MARK: - Animation Constants

private let BubbleControlMoveAnimationDuration: TimeInterval = 0.5
private let BubbleControlSpringDamping: CGFloat = 0.6
private let BubbleControlSpringVelocity: CGFloat = 0.6


// MARK: - UIView Extension

extension UIView {
    
    
    // MARK: Frame Extensions
    
    var x: CGFloat {
        get {
            return self.frame.origin.x
        } set (value) {
            self.frame = CGRect (x: value, y: self.y, width: self.w, height: self.h)
        }
    }
    
    var y: CGFloat {
        get {
            return self.frame.origin.y
        } set (value) {
            self.frame = CGRect (x: self.x, y: value, width: self.w, height: self.h)
        }
    }
    
    var w: CGFloat {
        get {
            return self.frame.size.width
        } set (value) {
            self.frame = CGRect (x: self.x, y: self.y, width: value, height: self.h)
        }
    }
    
    var h: CGFloat {
        get {
            return self.frame.size.height
        } set (value) {
            self.frame = CGRect (x: self.x, y: self.y, width: self.w, height: value)
        }
    }
    
    
    var position: CGPoint {
        get {
            return self.frame.origin
        } set (value) {
            self.frame = CGRect (origin: value, size: self.frame.size)
        }
    }
    
    var size: CGSize {
        get {
            return self.frame.size
        } set (value) {
            self.frame = CGRect (origin: self.frame.origin, size: size)
        }
    }
    
    
    var left: CGFloat {
        get {
            return self.x
        } set (value) {
            self.x = value
        }
    }
    
    var right: CGFloat {
        get {
            return self.x + self.w
        } set (value) {
            self.x = value - self.w
        }
    }
    
    var top: CGFloat {
        get {
            return self.y
        } set (value) {
            self.y = value
        }
    }
    
    var bottom: CGFloat {
        get {
            return self.y + self.h
        } set (value) {
            self.y = value - self.h
        }
    }
    
    
    
    func leftWithOffset (_ offset: CGFloat) -> CGFloat {
        return self.left - offset
    }
    
    func rightWithOffset (_ offset: CGFloat) -> CGFloat {
        return self.right + offset
    }
    
    func topWithOffset (_ offset: CGFloat) -> CGFloat {
        return self.top - offset
    }
    
    func botttomWithOffset (_ offset: CGFloat) -> CGFloat {
        return self.bottom + offset
    }
    
    
    
    func spring (_ animations: @escaping ()->Void, completion:((Bool)->Void)?) {
        UIView.animate(withDuration: BubbleControlMoveAnimationDuration,
            delay: 0,
            usingSpringWithDamping: BubbleControlSpringDamping,
            initialSpringVelocity: BubbleControlSpringVelocity,
            options: UIViewAnimationOptions(),
            animations: animations,
            completion: completion)
    }
    
    
    func moveY (_ y: CGFloat) {
        var moveRect = self.frame
        moveRect.origin.y = y
        
        spring({ () -> Void in
            self.frame = moveRect
            }, completion: nil)
    }
    
    func moveX (_ x: CGFloat) {
        var moveRect = self.frame
        moveRect.origin.x = x
        
        spring({ () -> Void in
            self.frame = moveRect
            }, completion: nil)
    }
    
    func movePoint (_ x: CGFloat, y: CGFloat) {
        var moveRect = self.frame
        moveRect.origin.x = x
        moveRect.origin.y = y
        
        spring({ () -> Void in
            self.frame = moveRect
            }, completion: nil)
    }
    
    func movePoint (_ point: CGPoint) {
        var moveRect = self.frame
        moveRect.origin = point
        
        spring({ () -> Void in
            self.frame = moveRect
            }, completion: nil)
    }
    
    
    func setScale (_ s: CGFloat) {
        var transform = CATransform3DIdentity
        transform.m34 = 1.0 / -1000.0
        transform = CATransform3DScale(transform, s, s, s)
        
        self.layer.transform = transform
    }
    
    func alphaTo (_ to: CGFloat) {
        UIView.animate(withDuration: BubbleControlMoveAnimationDuration,
            animations: {
                self.alpha = to
        })
    }
    
    func bubble () {
        
        self.setScale(1.2)
        spring({ () -> Void in
            self.setScale(1)
            }, completion: nil)
    }
}


// MARK: - BubbleControl

class BubbleControl: UIControl {
    
    
    // MARK: Constants
    
    let popTriggerDuration: TimeInterval = 0.5
    let popAnimationDuration: TimeInterval = 1
    let popAnimationShakeDuration: TimeInterval = 0.10
    let popAnimationShakeRotations: (CGFloat, CGFloat) = (-30, 30)
    let popAnimationScale: CGFloat = 1.2
    
    let snapOffsetMin: CGFloat = 10
    let snapOffsetMax: CGFloat = 50
    
    
    
    // MARK: Optionals
    
    var contentView: UIView?
    
    var snapsInside: Bool = false
    var popsToNavBar: Bool = true
    var movesBottom: Bool = false
    
    
    
    // MARK: Actions
    
    var didToggle: ((Bool) -> ())?
    var didNavigationBarButtonPressed: (() -> ())?
    var didPop: (()->())?
    
    var setOpenAnimation: ((_ contentView: UIView, _ backgroundView: UIView?)->())?
    var setCloseAnimation: ((_ contentView: UIView, _ backgroundView: UIView?) -> ())?
    
    
    
    // MARK: Bubble State
    
    enum BubbleControlState {
        case snap       // snapped to edge
        case drag       // dragging around
        case pop        // long pressed and popping
        case navBar     // popped and went to nav bar
    }
    
    var bubbleState: BubbleControlState = .snap {
        didSet {
            if bubbleState == .snap {
                setupSnapInsideTimer()
            } else {
                snapOffset = snapOffsetMin
            }
        }
    }
    
    
    
    // MARK: Snap
    
    fileprivate var snapOffset: CGFloat!
    
    fileprivate var snapInTimer: Timer?
    fileprivate var snapInInterval: TimeInterval = 2
    
    
    
    // MARK: Toggle
    
    fileprivate var positionBeforeToggle: CGPoint?
    
    var toggle: Bool = false {
        didSet {
            didToggle? (toggle)
            if toggle {
                openContentView()
            } else {
                closeContentView()
            }
        }
    }
    
    
    
    // MARK: Navigation Button
    
    fileprivate var barButtonItem: UIBarButtonItem?
    
    
    
    // MARK: Badge
    
//    fileprivate var badgeLabel: UILabel?
    
//    var badgeCount: Int = 0 {
//        didSet {
//            if badgeCount < 0 {
//                badgeCount = 0
//            } else if badgeCount > 0 {
//                badgeLabel?.isHidden = false
//                badgeLabel?.text = "\(badgeCount)"
//                badgeLabel?.bubble()
//            } else {
//                badgeLabel?.isHidden = true
//            }
//            
//            barButtonItem?.setBadgeValue(badgeCount)
//        }
//    }
    
    
    
    // MARK: Image
    
    var imageView: UIImageView?
    var image: UIImage? {
        didSet {
            imageView?.image = image
        }
    }
    
    
    
    // MARK: Init
    
    init (size: CGSize) {
        super.init(frame: CGRect (origin: CGPoint.zero, size: size))
        defaultInit()
    }
    
    init (image: UIImage) {
        let size = image.size
        super.init(frame: CGRect (origin: CGPoint.zero, size: size))
        self.image = image
        
        defaultInit()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    
    func defaultInit () {
        
        // self
        snapOffset = snapOffsetMin
        layer.cornerRadius = w/2
        
        
        // image view
        imageView = UIImageView (frame: frame.insetBy(dx: 20, dy: 20))
        addSubview(imageView!)
        
        
        // circle border
        let borderView = UIView (frame: frame)
        borderView.layer.borderColor = UIColor.black.cgColor
        borderView.layer.borderWidth = 2
        borderView.layer.cornerRadius = w/2
        borderView.layer.masksToBounds = true
        borderView.isUserInteractionEnabled = false
        addSubview(borderView)
        
        
        // badge label
//        badgeLabel = UILabel (frame: frame.insetBy(dx: 25, dy: 25))
//        badgeLabel?.center = CGPoint(x: left + badgeLabel!.w/2, y: top + badgeLabel!.h/2)
//        badgeLabel?.backgroundColor = UIColor.red
//        badgeLabel?.textAlignment = NSTextAlignment.center
//        badgeLabel?.textColor = UIColor.white
//        badgeLabel?.text = "\(badgeCount)"
//        badgeLabel?.layer.cornerRadius = badgeLabel!.w/2
//        badgeLabel?.layer.masksToBounds = true
//        addSubview(badgeLabel!)
//        
//        badgeCount = 0
        
        
        // events
        addTarget(self, action: #selector(BubbleControl.touchDown), for: UIControlEvents.touchDown)
        addTarget(self, action: #selector(BubbleControl.touchUp), for: UIControlEvents.touchUpInside)
        addTarget(self, action: #selector(BubbleControl.touchDrag(_:event:)), for: UIControlEvents.touchDragInside)
        
        let longPress = UILongPressGestureRecognizer (target: self, action: #selector(BubbleControl.longPressHandler(_:)))
        longPress.minimumPressDuration = 0.75
        addGestureRecognizer(longPress)
        
        
        // place
        center.x = APPDELEGATE.window!.w - w/2 + snapOffset
        center.y = 84 + h/2
        snap()
    }
    
    
    
    // MARK: Snap To Edge
    
    func snap () {
        let window = APPDELEGATE.window!
        
        // if control on left side
        var targetX = window.leftWithOffset(snapOffset)
//        var badgeTargetX = w - badgeLabel!.w
        
        
        // if control on right side
        if center.x > window.w/2 {
            targetX = window.rightWithOffset(snapOffset) - w
//            badgeTargetX = 0
        }
        
        // move to snap position
        moveX(targetX)
//        badgeLabel!.moveX(badgeTargetX)
    }
    
    func snapInside () {
        print("snap inside !")
        if !toggle && bubbleState == .snap {
            snapOffset = snapOffsetMax
            snap()
        }
    }
    
    func setupSnapInsideTimer () {
        if !snapsInside {
            return
        }
        
        if let timer = snapInTimer {
            if timer.isValid {
                timer.invalidate()
            }
        }
        
        snapInTimer = Timer.scheduledTimer(timeInterval: snapInInterval,
            target: self,
            selector: #selector(BubbleControl.snapInside),
            userInfo: nil,
            repeats: false)
    }
    
    
    func lockInWindowBounds () {
        let window = APPDELEGATE.window!
        
        if top < 64 {
            var rect = frame
            rect.origin.y = 64
            frame = rect
        }
        
        if left < 0 {
            var rect = frame
            rect.origin.x = 0
            frame = rect
        }
        
        
        if bottom > window.h {
            var rect = frame
            rect.origin.y = window.botttomWithOffset(-h)
            frame = rect
        }
        
        if right > window.w {
            var rect = frame
            rect.origin.x = window.rightWithOffset(-w)
            frame = rect
        }
    }
    
    
    
    // MARK: Events
    
    func touchDown () {
        bubble()
    }
    
    func touchUp () {
        if bubbleState == .snap {
            toggle = !toggle
        } else {
            bubbleState = .snap
            snap()
        }
    }
    
    func touchDrag (_ sender: BubbleControl, event: UIEvent) {
        bubbleState = .drag
        
        if toggle {
            toggle = false
        }
        
        let touch = event.allTouches!.first! 
        let location = touch.location(in: APPDELEGATE.window!)
        
        center = location
        lockInWindowBounds()
    }
    
    
    func longPressHandler (_ press: UILongPressGestureRecognizer) {
        
        if toggle {
            return
        }
        
        switch press.state {
        case .began:
            pop()
        case .ended:
            if bubbleState == .pop {
                cancelPop()
            }
        default:
            return
        }
    }
    
    func navButtonPressed (_ sender: AnyObject) {
        didNavigationBarButtonPressed? ()
    }
    
    
    
    // MARK: Animations
    
//    override
    func animationDidStop(_ anim: CAAnimation!,
        finished flag: Bool) {
            if flag {
                if anim == layer.animation(forKey: "pop") {
                    layer.removeAnimation(forKey: "pop")
                    
                    didPop? ()
                    
                    if popsToNavBar {
                        popToNavBar()
                    }
                }
            }
    }
    
    func degreesToRadians (_ angle: CGFloat) -> CGFloat {
        return (CGFloat (M_PI) * angle) / 180.0
    }
    
    
    
    // MARK: Pop
    
    func pop () {
        bubbleState = .pop
        snap()
        
        let shake = CABasicAnimation(keyPath: "transform.rotation")
        shake.fromValue = degreesToRadians(popAnimationShakeRotations.0)
        shake.toValue = degreesToRadians(popAnimationShakeRotations.1)
        shake.duration = popAnimationShakeDuration
        shake.repeatCount = Float.infinity
        shake.autoreverses = true
        
        let grow = CABasicAnimation (keyPath: "transform.scale")
        grow.fromValue = 1
        grow.toValue = popAnimationScale
        grow.duration = popAnimationDuration
        
        let anims = CAAnimationGroup ()
        anims.animations = [shake, grow]
        anims.duration = popAnimationDuration
        anims.delegate = self as! CAAnimationDelegate
        anims.isRemovedOnCompletion = false
        
        layer.add(anims, forKey: "pop")
    }
    
    func cancelPop () {
        snap()
        layer.removeAnimation(forKey: "pop")
    }
    
    
    func popToNavBar () {
        bubbleState = .navBar
        
        spring({ () -> Void in
            self.setScale(0)
            self.alpha = 0.5
            }, completion: { finished in
                self.setScale(1)
                self.isHidden = true
        })
        
        
        var barButton: UIBarButtonItem?
        
        if let img = image {
            let navButton = UIButton (frame: CGRect (x: 0, y: 0, width: 20, height: 20))
            navButton.setBackgroundImage(image!, for: UIControlState())
            navButton.addTarget(self, action: #selector(BubbleControl.navButtonPressed(_:)),
                for: .touchUpInside)
            
            barButton = UIBarButtonItem (customView: navButton)
        } else {
            barButton = UIBarButtonItem (barButtonSystemItem: UIBarButtonSystemItem.action
                , target: self, action: #selector(BubbleControl.navButtonPressed(_:)))
        }
        
        barButtonItem = barButton
//        barButtonItem?.setBadgeValue(badgeCount)
        
        if let last = APPDELEGATE.window!.rootViewController as? UINavigationController {
            let vc = last.viewControllers[0] 
            vc.navigationItem.setRightBarButton(barButtonItem!, animated: true)
        }
    }
    
    func popFromNavBar () {
        if let last = APPDELEGATE.window!.rootViewController as? UINavigationController {
            let vc = last.viewControllers[0] 
            vc.navigationItem.rightBarButtonItem = nil
            
            bubbleState = .snap
            self.barButtonItem = nil
            self.isHidden = false
            
            let toPosition = self.frame.origin
            self.position = CGPoint(x: APPDELEGATE.window!.right, y: APPDELEGATE.window!.top)
            self.movePoint(toPosition)
            self.alphaTo(1)
        }
    }
    
    
    
    // MARK: Toggle
    
    func openContentView () {
        if let v = contentView {
            let win = APPDELEGATE.window!
            win.addSubview(v)
            win.bringSubview(toFront: self)
            
            snapOffset = snapOffsetMin
            snap()
            positionBeforeToggle = frame.origin
            
            if let anim = setOpenAnimation {
                anim (v, win.subviews[0] as? UIView)
            } else {
                v.bottom = win.bottom
            }
            
            if movesBottom {
                movePoint(CGPoint (x: win.center.x - w/2, y: win.bottom - h - snapOffset))
            } else {
                moveY(v.top - h - snapOffset)
            }
        }
    }
    
    func closeContentView () {
        if let v = contentView {
            
            if let anim = setCloseAnimation {
                anim (v, APPDELEGATE.window?.subviews[0] as? UIView)
            } else {
                v.removeFromSuperview()
            }
            
            if (bubbleState == .snap) {
                setupSnapInsideTimer()
                movePoint(positionBeforeToggle!)
            }
        }
    }
}



// MARK: - UIBarButtonItem Badge Extension

private var barButtonAssociatedObjectBadge: UInt8 = 0
extension UIBarButtonItem {
    
//    fileprivate var badgeLabel: UILabel? {
//        get {
//            return objc_getAssociatedObject(self, &barButtonAssociatedObjectBadge) as! UILabel?
//        } set (value) {
//            
//            objc_setAssociatedObject(self, &barButtonAssociatedObjectBadge, value, UInt(OBJC_ASSOCIATION_RETAIN))
//        }
//    }
    
//    func setBadgeValue (_ value: Int) {
//        print("value \(value)")
//        if let label = badgeLabel {
//            if value > 0 {
//                label.isHidden = false
//                label.text = "\(value)"
//                label.bubble()
//            } else {
//                label.isHidden = true
//            }
//        } else {
//            let view = self.value(forKey: "view") as? UIView
//            
//            badgeLabel = UILabel (frame: CGRect (x: 0, y: 0, width: 20, height: 20))
//            badgeLabel?.center = CGPoint (x: view!.right, y: view!.top)
//            badgeLabel?.backgroundColor = UIColor.red
//            
//            badgeLabel?.layer.cornerRadius = badgeLabel!.h/2
//            badgeLabel?.layer.masksToBounds = true
//            
//            badgeLabel?.textAlignment = NSTextAlignment.center
//            badgeLabel?.textColor = UIColor.white
//            badgeLabel?.font = UIFont.systemFont(ofSize: 15)
//            badgeLabel?.text = "\(value)"
//            
//            
//            if value == 0 {
//                badgeLabel?.isHidden = true
//            }
//            
//            view?.addSubview(badgeLabel!)
//        }
//    }
}

