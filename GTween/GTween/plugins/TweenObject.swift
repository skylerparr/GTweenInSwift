//
//  TweenObject.swift
//  GTween
//
//  Created by Goon Nguyen on 10/13/14.
//  Copyright (c) 2014 Goon Nguyen. All rights reserved.
//

import Foundation
import UIKit

class TweenObject:NSObject {
    var loop:CADisplayLink!
    
    /*var fromValue:Float!
    var toValue:Float!*/
    var changeValue:Float!
    
    var speed:Double = 1
    var target:AnyObject!
    var targetFrame:CGRect!
    var currentTime:Double = 0
    var totalTime:Double = 0
    var delayTime:Double = 0
    
    var repeat:Int = 0
    var repeatCount:Int = 0
    
    var _time:Float!
    
    var isPaused:Bool = false;
    var isStarted:Bool = false;
    var isYoyo:Bool = false;
    
    var inputParams:Dictionary<String, Any>!
    var tweenParams:[String: AnyObject]!
    
    var easeNumber:Float?
    var easeType:String = "Linear.easeNone" //default
    
    /*var linearMode:ModeLinear = ModeLinear()
    var backMode:ModeBack = ModeBack()
    var quintMode:ModeQuint = ModeQuint()
    var elasticMode:ModeElastic = ModeElastic()
    var bounceMode:ModeBounce = ModeBounce()
    var sineMode:ModeSine = ModeSine()
    var expoMode:ModeExpo = ModeExpo()
    var circMode:ModeCirc = ModeCirc()
    var cubicMode:ModeCubic = ModeCubic()
    var quartMode:ModeQuart = ModeQuart()
    var quadMode:ModeQuad = ModeQuad()*/
    
    typealias OnCompleteType = ()->Void
    
    var runOnComplete:(()->())?
    var runOnUpdate:(()->())?
    var runOnStart:(()->())?
    
    //tween values
    var toX:Float!
    var toY:Float!
    var toWidth:Float!
    var toHeight:Float!
    var toScaleX:Float!
    var toScaleY:Float!
    var toAlpha:Float!
    var toRotation:Float!
    var originScaleX:Float!
    var originScaleY:Float!
    var originCenterX:Float!
    var originCenterY:Float!
    var originRotation:Float!
    
    init(_target:AnyObject, time:Float, params:[String: Any], events:[String: ()->Void] = Dictionary()){
        target = _target
        _time = time;
        targetFrame = target.frame;
        inputParams = params;
        println(targetFrame)
        
        originCenterX = Float(target.center.x)
        originCenterY = Float(target.center.y)
        
        if var inputEase = params["ease"] as? String {
            easeType = String(inputEase)
        }
        
        if var delayInInt = params["delay"] as? Int {
            delayTime = Double(delayInInt)
        } else if let delayInDouble = params["delay"] as? Float {
            delayTime = Double(delayInDouble)
        } else if let delayInFloat = params["delay"] as? Double {
            delayTime = delayInFloat
        }
        
        runOnComplete  = events["onComplete"]
        runOnUpdate    = events["onUpdate"]
        runOnStart     = events["onStart"]
        
        if var xInInt = params["x"] as? Int {
            toX = Float(xInInt)
        } else if let xInDouble = params["x"] as? Double {
            toX = Float(xInDouble)
        } else if let xInFloat = params["x"] as? Float {
            toX = xInFloat
        }
        
        if let yInInt = params["y"] as? Int {
            toY = Float(yInInt)
        } else if let yInDouble = params["y"] as? Double {
            toY = Float(yInDouble)
        } else if let yInFloat = params["y"] as? Float {
            toY = yInFloat
        }
        if let widthInInt = params["width"] as? Int {
            toWidth = Float(widthInInt)
        } else if let widthInDouble = params["width"] as? Double {
            toWidth = Float(widthInDouble)
        } else if let widthInFloat = params["width"] as? Float {
            toWidth = widthInFloat
        }
        
        if let heightInInt = params["height"] as? Int {
            toHeight = Float(heightInInt)
        } else if let heightInDouble = params["height"] as? Double {
            toHeight = Float(heightInDouble)
        } else if let heightInFloat = params["height"] as? Float {
            toHeight = heightInFloat
        }
        
        if let scaleXInInt = params["scaleX"] as? Int {
            toScaleX = Float(scaleXInInt)
        } else if let scaleXInDouble = params["scaleX"] as? Double {
            toScaleX = Float(scaleXInDouble)
        } else if let scaleXInFloat = params["scaleX"] as? Float {
            toScaleX = scaleXInFloat
        }
        
        if let scaleYInInt = params["scaleY"] as? Int {
            toScaleY = Float(scaleYInInt)
        } else if let scaleYInDouble = params["scaleY"] as? Double {
            toScaleY = Float(scaleYInDouble)
        } else if let scaleYInFloat = params["scaleY"] as? Float {
            toScaleY = scaleYInFloat
        }
        
        if let alphaInInt = params["alpha"] as? Int {
            toAlpha = Float(alphaInInt)
        } else if let alphaInDouble = params["alpha"] as? Double {
            toAlpha = Float(alphaInDouble)
        } else if let alphaInFloat = params["alpha"] as? Float {
            toAlpha = alphaInFloat
        }
        
        if let rotationInInt = params["rotation"] as? Int {
            toRotation = Float(rotationInInt)
        } else if let rotationInDouble = params["rotation"] as? Double {
            toRotation = Float(rotationInDouble)
        } else if let rotationInFloat = params["rotation"] as? Float {
            toRotation = rotationInFloat
        }
        
        //println("x:\(toX) y:\(toY) scaleX:\(toScaleX) scaleY:\(toScaleY) alpha:\(toAlpha)")
        
        super.init()
        
        originScaleX = xscale(target)
        originScaleY = yscale(target)
        originRotation = getrotation(target) * Float(180 / M_PI)
        
        //println(originRotation)
        
        setup()
    }
    
    func setup(){
        loop = CADisplayLink(target: self, selector: Selector("onLoop"))
        loop.frameInterval = 1
        loop.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    func onLoop(){
        //println("\(currentTime)")
        if ((currentTime >= delayTime && speed > 0) || (speed < 0))// && _currentTime <= _totalTime))
        {
            //var value;
            var time = Float((currentTime - delayTime) / Double(_time));
            //make this nicer!
            time = fminf(1.0, fmaxf(0.0, time));
            
            //=============================================
            //        UPDATE VALUES
            //=============================================
            
            easeNumber = Ease.getEaseNumber(easeType, time: time)
            
            var newX:Float!
            var newY:Float!
            var newW:Float!
            var newH:Float!
            var newAlpha:Float!
            var newScaleX:Float!
            var newScaleY:Float!
            var newRotation:Float!
            
            if toX != nil {
                newX = getNewValue(toX, fromValue: Float(targetFrame.origin.x), ease: easeNumber!)
            } else {
                newX = Float(targetFrame.origin.x)
            }
            
            if toY != nil {
                newY = getNewValue(toY, fromValue: Float(targetFrame.origin.y), ease: easeNumber!)
            } else {
                newY = Float(targetFrame.origin.y)
            }
            
            if toWidth != nil {
                newW = getNewValue(toWidth, fromValue: Float(targetFrame.size.width), ease: easeNumber!)
            } else {
                newW = Float(targetFrame.size.width)
            }
            
            if toHeight != nil {
                newH = getNewValue(toHeight, fromValue: Float(targetFrame.size.height), ease: easeNumber!)
            } else {
                newH = Float(targetFrame.size.height)
            }
            
            if toScaleX != nil {
                newScaleX = getNewValue(toScaleX, fromValue: originScaleX, ease: easeNumber!)
            } else {
                newScaleX = xscale(target)
            }
            
            if toScaleY != nil {
                newScaleY = getNewValue(toScaleY, fromValue: originScaleY, ease: easeNumber!)
            } else {
                newScaleY = yscale(target)
            }
            
            if toRotation != nil {
                newRotation = getNewValue(toRotation, fromValue: originRotation, ease: easeNumber!)
            } else {
                newRotation = getrotation(target) * Float(180 / M_PI)
            }
            
            var scaleTransform = CGAffineTransformMakeScale(CGFloat(newScaleX), CGFloat(newScaleY))
            var rotateTransform = CGAffineTransformMakeRotation(CGFloat(Double(newRotation)/180.0*M_PI))
            //var newTransform = CGAffineTransformMakeRotation(CGFloat(Double(newRotation)/180.0*M_PI))
            var newTransform = CGAffineTransformConcat(scaleTransform, rotateTransform)
            
            //println("scaleX: \(newScaleX) scaleY: \(newScaleY)")
            var newFrame = target.frame
            newFrame.origin.x = CGFloat(newX)
            newFrame.origin.y = CGFloat(newY)
            newFrame.size.width = CGFloat(newW)
            newFrame.size.height = CGFloat(newH)
            
            var newCenter = target.center
            newCenter.x = CGFloat(newX)
            newCenter.y = CGFloat(newY)
            
            /*if(toScaleX == nil) {
            newFrame.size.width = CGFloat(newW)
            }
            
            if(toScaleY == nil) {
            newFrame.size.height = CGFloat(newH)
            }*/
            
            if((target as? UIView) != nil){
                var newTarget = (target as! UIView)
                //print("uiview")
                if(toScaleX != nil || toScaleY != nil || toRotation != nil) {
                    newTarget.transform = newTransform
                    
                    newFrame = newTarget.frame
                    if(toX != nil){ newFrame.origin.x = CGFloat(newX) }
                    if(toY != nil){ newFrame.origin.y = CGFloat(newY) }
                    //newFrame.size.width = newTarget.bounds.size.width
                    //newFrame.size.height = newTarget.bounds.size.height
                    newTarget.frame = newFrame
                    //newTarget.bounds = newFrame
                    //println(newFrame)
                } else {
                    newTarget.frame = newFrame
                }
            } else if((target as? UILabel) != nil){
                var newTarget = (target as! UILabel)
                
                if(toScaleX != nil || toScaleY != nil || toRotation != nil) {
                    newTarget.transform = newTransform
                    newFrame = newTarget.frame
                    if(toX != nil){ newFrame.origin.x = CGFloat(newX) }
                    if(toY != nil){ newFrame.origin.y = CGFloat(newY) }
                    newTarget.frame = newFrame
                } else {
                    newTarget.frame = newFrame
                }
            } else if((target as? UIImageView) != nil){
                var newTarget = (target as! UIImageView)
                
                if(toScaleX != nil || toScaleY != nil || toRotation != nil) {
                    newTarget.transform = newTransform
                    newFrame = newTarget.frame
                    if(toX != nil){ newFrame.origin.x = CGFloat(newX) }
                    if(toY != nil){ newFrame.origin.y = CGFloat(newY) }
                    newTarget.frame = newFrame
                } else {
                    newTarget.frame = newFrame
                }
            } else if((target as? UIButton) != nil){
                var newTarget = (target as! UIButton)
                println("uibutton")
                if(toScaleX != nil || toScaleY != nil || toRotation != nil) {
                    newTarget.transform = newTransform
                    newFrame = newTarget.frame
                    if(toX != nil){ newFrame.origin.x = CGFloat(newX) }
                    if(toY != nil){ newFrame.origin.y = CGFloat(newY) }
                    //newTarget.frame = newFrame
                    println(newFrame)
                } else {
                    newTarget.frame = newFrame
                }
            } else if((target as? UICollectionView) != nil){
                var newTarget = (target as! UICollectionView)
                
                if(toScaleX != nil || toScaleY != nil || toRotation != nil) {
                    newTarget.transform = newTransform
                    newFrame = newTarget.frame
                    if(toX != nil){ newFrame.origin.x = CGFloat(newX) }
                    if(toY != nil){ newFrame.origin.y = CGFloat(newY) }
                    newTarget.frame = newFrame
                } else {
                    newTarget.frame = newFrame
                }
            } else if((target as? UITextView) != nil){
                var newTarget = (target as! UITextView)
                
                if(toScaleX != nil || toScaleY != nil || toRotation != nil) {
                    newTarget.transform = newTransform
                    newFrame = newTarget.frame
                    if(toX != nil){ newFrame.origin.x = CGFloat(newX) }
                    if(toY != nil){ newFrame.origin.y = CGFloat(newY) }
                    newTarget.frame = newFrame
                } else {
                    newTarget.frame = newFrame
                }
            } else if((target as? UIScrollView) != nil){
                var newTarget = (target as! UIScrollView)
                
                if(toScaleX != nil || toScaleY != nil || toRotation != nil) {
                    newTarget.transform = newTransform
                    newFrame = newTarget.frame
                    if(toX != nil){ newFrame.origin.x = CGFloat(newX) }
                    if(toY != nil){ newFrame.origin.y = CGFloat(newY) }
                    newTarget.frame = newFrame
                } else {
                    newTarget.frame = newFrame
                }
            } else if((target as? UIPickerView) != nil){
                (target as! UIPickerView).frame = newFrame
            } else if((target as? UIWebView) != nil){
                (target as! UIWebView).frame = newFrame
            } else if((target as? UIToolbar) != nil){
                (target as! UIToolbar).frame = newFrame
            } else if((target as? UISwitch) != nil){
                (target as! UISwitch).frame = newFrame
            } else if((target as? UIActivityIndicatorView) != nil){
                (target as! UIActivityIndicatorView).frame = newFrame
            } else if((target as? UIProgressView) != nil){
                (target as! UIProgressView).frame = newFrame
            } else if((target as? UIPageControl) != nil){
                (target as! UIPageControl).frame = newFrame
            } else if((target as? UIStepper) != nil){
                (target as! UIStepper).frame = newFrame
            }
            
            if toAlpha != nil {
                newAlpha = getNewValue(toAlpha, fromValue: Float(target.layer.opacity), ease: easeNumber!)
                target.layer.opacity = newAlpha
            } else {
                newAlpha = Float(target.layer.opacity)
            }
            
            
            //=============================================
            
            if(runOnStart != nil && !isStarted){
                runOnStart?()
                isStarted = true
            }
            
            if (runOnUpdate != nil) {
                runOnUpdate?()
            }
            
            if (time == 1.0)
            {
                if (!isYoyo)
                {
                    if (repeat == 0 || repeatCount == repeat)
                    {
                        self.stop()
                    }
                    else
                    {
                        currentTime = 0.0;
                        repeatCount++;
                    }
                }
                else
                {
                    currentTime = totalTime;
                    speed = speed * -1;
                }
            }
            else if (time == 0 && speed < 0)
            {
                if (repeat == 0 || repeatCount == repeat)
                {
                    self.stop()
                }
                else
                {
                    currentTime = 0.0;
                    speed = speed * -1;
                    repeatCount++;
                }
            }
        }
        
        currentTime += loop.duration * speed;
    }
    
    func getNewValue(toValue:Float, fromValue:Float, ease:Float)->Float {
        changeValue = toValue - fromValue
        var value = fromValue + changeValue * ease;
        return value
    }
    
    func start(){
        setup()
    }
    
    func pause(){
        if(!isPaused){
            loop.invalidate()
            isPaused = true;
        }
    }
    
    func resume(){
        if(isPaused){
            setup()
            isPaused = false;
        }
    }
    
    func stop(){
        //testOnComplete?()
        runOnComplete?()
        loop.invalidate()
    }
}