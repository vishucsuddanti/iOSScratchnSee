//
// Scratch and See
//
// The project provides en effect when the user swipes the finger over one texture
// and by swiping reveals the texture underneath it. The effect can be applied for
// scratch-card action or wiping a misted glass.
//
// Copyright (C) 2012 http://moqod.com Andrew Kopanev <andrew@moqod.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//

import UIKit

typealias FillTileWithPointFunc = (Any, Selector, CGPoint)
typealias FillTileWithTwoPointsFunc = (Any, Selector, CGPoint, CGPoint)

@inline(__always) func fromUItoQuartz(point: CGPoint, frameSize: CGSize) -> CGPoint {
    var newPoint = point
    newPoint.y = frameSize.height - point.y
    return newPoint
}

@inline(__always) func scalePoint(point: CGPoint, previousSize: CGSize, currentSize: CGSize) -> CGPoint {
    return CGPoint(x: currentSize.width * point.x / previousSize.width, y: currentSize.height * point.y / previousSize.height)
}

protocol ImageMaskFilledDelegate: class {
    func imageMaskView(maskView: ImageMaskView, clearPercent: Float)
}

class ImageMaskView: UIImageView {
    
    var tilesX = size_t()
    var tilesY = size_t()
    var tilesFilled: Int = 0
    var maskedMatrix: Matrix?
    var imageContext: CGContext?
    var colorSpace: CGColorSpace?
    var touchPoints = [NSValue]()
    
    var percentofImageMasked: Double = 0.0
    weak var imageMaskFilledDelegate: ImageMaskFilledDelegate?
    var radius: CGFloat = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func beginInteraction() {
        self.isUserInteractionEnabled = true
        self.tilesFilled = 0
        self.backgroundColor = UIColor.clear
        self.radius = self.radius > 0 ? self.radius : 20
        let size = self.image?.size
        
        self.colorSpace = CGColorSpaceCreateDeviceRGB()
        if let imageSize = size, let myColorSpace = self.colorSpace, let img = self.image?.cgImage{
            
            self.imageContext = CGContext.init(data: nil, width: Int(imageSize.width), height: Int(imageSize.height), bitsPerComponent: 8, bytesPerRow: Int(imageSize.width * 4), space: myColorSpace, bitmapInfo: 1, releaseCallback: nil, releaseInfo: nil)
            if let imgContext = self.imageContext {
                imgContext.draw(img, in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height), byTiling: false)
                imgContext.setBlendMode(CGBlendMode.clear)
            }
            self.tilesX = size_t(imageSize.width / (2 * self.radius))
            self.tilesY = size_t(imageSize.height / (2 * self.radius))
            self.maskedMatrix = Matrix(maxX: self.tilesX, maxY: self.tilesY)
            
        }
        
    }
    
    func procentofImageMasked() -> Double {
        guard let myMaskedMatrix = self.maskedMatrix?.max else { return 0.0 }
        return (100.0 * Double(self.tilesFilled)) / Double(myMaskedMatrix.x * myMaskedMatrix.y)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.image == nil {
            return
        }
        if let img = self.addTouches(touches: touches) {
            self.image = img
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.image == nil {
            return
        }
        if let img = self.addTouches(touches: touches) {
            self.image = img
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touches ended")
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touches cancelled")
    }
    
    
    func addTouches(touches: Set<UITouch>) -> UIImage? {
        
        let size = self.image?.size
        let ctx = self.imageContext
        
        ctx?.setFillColor(UIColor.clear.cgColor)
        ctx?.setStrokeColor(UIColor.init(red: 0, green: 0, blue: 0, alpha: 0).cgColor)
        let tempFilled = self.tilesFilled
        
        for touch in touches {
            ctx?.beginPath()
            var touchPoint = touch.location(in: self)
            touchPoint = fromUItoQuartz(point: touchPoint, frameSize: self.bounds.size)
            touchPoint = scalePoint(point: touchPoint, previousSize: self.bounds.size, currentSize: size ?? CGSize.zero)
            
            if touch.phase == UITouchPhase.began {
                self.touchPoints.removeAll()
                self.touchPoints.append(NSValue.init(cgPoint: touchPoint))
                self.touchPoints.append(NSValue.init(cgPoint: touchPoint))
                let rect = CGRect(x: touchPoint.x - self.radius, y: touchPoint.y - self.radius, width: 2 * self.radius, height: 2 * self.radius)
                // On begin, draw ellipse
                ctx?.setShadow(offset: CGSize.zero, blur: 10.0, color: UIColor.black.cgColor)
                ctx?.addEllipse(in: rect)
                ctx?.fillPath()
                self.fillTileWithPoint(rect.origin)
            } else if (touch.phase == UITouchPhase.moved) {
                // On touch moved, draw superior-width line
                self.touchPoints.append(NSValue.init(cgPoint: touchPoint))
                ctx?.setStrokeColor(UIColor.yellow.cgColor)
                ctx?.setShadow(offset: CGSize.zero, blur: 10.0, color: UIColor.black.cgColor)
                ctx?.setLineCap(CGLineCap.round)
                ctx?.setLineWidth(2*radius)
                
                while(self.touchPoints.count > 3) {
                    var bezier = [CGPoint].init(repeating: CGPoint.zero, count: 4)
                    bezier[0] = self.touchPoints[1].cgPointValue
                    bezier[3] = self.touchPoints[2].cgPointValue
                    
                    let k:CGFloat = 0.3
                    let len:CGFloat = sqrt(pow(bezier[3].x - bezier[0].x, 2) + pow(bezier[3].y - bezier[0].y, 2))
                    bezier[1] = self.touchPoints[0].cgPointValue
                    
                    bezier[1] = self.normalizeVector(point: CGPoint(x: bezier[0].x - bezier[1].x - (bezier[0].x - bezier[3].x), y: bezier[0].y - bezier[1].y - (bezier[0].y - bezier[3].y)))
                    bezier[1].x *= len * k
                    bezier[1].y *= len * k
                    bezier[1].x += bezier[0].x
                    bezier[1].y += bezier[0].y
                    
                    bezier[2] = self.touchPoints[3].cgPointValue
                    
                    bezier[2] = self.normalizeVector(point: CGPoint(x: (bezier[3].x - bezier[2].x)  - (bezier[3].x - bezier[0].x), y: (bezier[3].y - bezier[2].y)  - (bezier[3].y - bezier[0].y)))
                    bezier[2].x *= len * k
                    bezier[2].y *= len * k
                    bezier[2].x += bezier[3].x
                    bezier[2].y += bezier[3].y
                    
                    ctx?.move(to: CGPoint(x: bezier[0].x, y: bezier[0].y))
                    ctx?.addCurve(to: CGPoint(x: bezier[1].x, y: bezier[1].y), control1: CGPoint(x: bezier[2].x, y: bezier[2].y), control2: CGPoint(x: bezier[3].x, y: bezier[3].y))
                    self.touchPoints.remove(at: 0)
                }
                ctx?.strokePath()
                var prevPoint = touch.previousLocation(in: self)
                prevPoint = fromUItoQuartz(point: prevPoint, frameSize: self.bounds.size)
                if let sz = size {
                    prevPoint = scalePoint(point: prevPoint, previousSize: self.bounds.size, currentSize: sz)
                }
                self.fillTileWithTwoPoints(begin: touchPoint, end: prevPoint)
            }
        }
        // Was tilesFilled changed?
        if tempFilled != self.tilesFilled {
            self.imageMaskFilledDelegate?.imageMaskView(maskView: self, clearPercent: Float(self.procentofImageMasked()))
        }
        
        if let cgImg = ctx?.makeImage() {
            return UIImage(cgImage: cgImg)
        }
        return nil
    }
    
    /// Filling tile with one ellipse.
    ///
    /// - Parameter point: ellipse point.
    func fillTileWithPoint(_ point: CGPoint) {
        var x: size_t
        var y: size_t
        
        var pt = point
        
        if let mskMatrix = self.maskedMatrix?.max, let img = self.image {
            pt.x = max(min(pt.x, img.size.width - 1), 0)
            pt.y = max(min(pt.y, img.size.height - 1), 0)
            x  = Int(pt.x * CGFloat(mskMatrix.x) / img.size.width)
            y = Int(pt.y * CGFloat(mskMatrix.y) / img.size.height)
            let value = self.maskedMatrix?.valueForCoordinates(x: x, y: y)
            if value == 0 {
                self.maskedMatrix?.setCharacterValue(value: CChar(1), x: x, y: y)
                self.tilesFilled += 1
            }
        }
    }
    
    /// Filling tile with line
    ///
    /// - Parameters:
    ///   - begin: line start point.
    ///   - end: line end point.
    func fillTileWithTwoPoints(begin: CGPoint, end: CGPoint) {
        var incrementerForx: CGFloat
        var incrementerFory: CGFloat
        if let img = self.image {
            incrementerForx = (begin.x < end.x ? 1 : -1) * img.size.width / CGFloat(tilesX)
            incrementerFory = (begin.y < end.y ? 1 : -1) * img.size.height / CGFloat(tilesY)
            var i = begin
            while(i.x <= max(begin.x, end.x) && i.y <= max(begin.y, end.y) && i.x >= min(begin.x, end.x) && i.y >= min(begin.y, end.y)) {
                self.fillTileWithPoint(i)
                i.x += incrementerForx
                i.y += incrementerFory
            }
            self.fillTileWithPoint(end)
        }
    }
    
    func normalizeVector(point: CGPoint) -> CGPoint {
        var p = point
        let len = sqrt(point.x*point.x + point.y*point.y)
        if (len == 0) {
            return CGPoint.zero
        }
        p.x /= len
        p.y /= len
        return p
    }
    
}

