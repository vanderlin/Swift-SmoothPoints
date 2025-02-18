//
//  SmoothDrawingView.swift
//  SmoothPoints
//
//  Created by Todd Vanderlin on 2/5/25.
//

import UIKit

enum InterpolationMethod: String, CaseIterable {
    case linear = "Linear"
    case cubic = "Cubic"
    case hermite = "Hermite"
    case bezier = "Bezier"
    case catmullRom = "Catmull-Rom"
}

class SmoothDrawingView: UIView {
    private var points: [CGPoint] = []
    private var simplePoints: [CGPoint] = []
    private var smoothedPoints: [CGPoint] = []
    
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    private var timef: CGFloat = 0.0
    
    var interpolationMethod:InterpolationMethod = .linear {
        didSet {
            updatePath()
        }
    }
    var tolerance:CGFloat = 5.0 {
        didSet {
            updatePath()
        }
    }
    var resampledSpace:CGFloat = 50.0 {
        didSet {
            updatePath()
        }
    }
    var shouldClose:Bool = false {
        didSet {
            updatePath()
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        displayLink?.invalidate() // Ensure no duplicate CADisplayLink instances
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .default)
        startTime = CACurrentMediaTime()
    }
    
    @objc private func updateAnimation() {
        timef = CGFloat(CACurrentMediaTime() - startTime) * 0.5
        updatePath()
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: self)
        
        if gesture.state == .began {
            points.removeAll()
        }
        startTime = CACurrentMediaTime()
        points.append(point)
        updatePath()
    }
    
    func getPointAtPct(pct:Float, points:[CGPoint]) -> CGPoint {
        
        guard points.count > 3 else { return .zero }

        
        let num:Int = points.count - 1
        
        let indexf = Float(num) * pct
        let indexi = min(Int(floor(indexf)), num - 1)
        
        let f = indexf - Float(indexi)
        
        var p0:CGPoint, p1:CGPoint, p2:CGPoint, p3:CGPoint = .zero
        
        if shouldClose {
            let i = Int(indexi)
            
            p0 = points[i % num]
            p1 = points[(i + 1) % num]
            p2 = points[(i + 2) % num]
            p3 = points[(i + 3) % num]
        }
        else {
            
            let i = indexi
            p0 = points[clamp(i-1, min: 0, max: num-1)]
            p1 = points[i]
            p2 = points[clamp(i+1, min: 0, max: num)]
            p3 = points[clamp(i+2, min: 0, max: num)]
        }
        
        let t = CGFloat(f)
       
        
        switch interpolationMethod {
        case .linear:
            return interpolateLinear(p0: p1, p1: p2, t: t)
        case .cubic:
            return cubic(p0: p0, p1: p1, p2: p2, p3: p3, t: t)
        case .hermite:
            return hermite(p0: p0, p1: p1, p2: p2, p3: p3, t: t, tension: 1.0, bias: 1.0)
        case .bezier:
            return cubicBezier(p0: p0, p1: p1, p2: p2, p3: p3, t: t)
        case .catmullRom:
            return catmullRom(p0: p0, p1: p1, p2: p2, p3: p3, t: t)
        }
    }
    
    func updatePath() {
        guard points.count > 3 else { return }
       
        simplePoints = Simplify.simplify(points, tolerance: tolerance)
        
        var resampled:[CGPoint] = []
        let steps = max(10, simplePoints.count * 10)
        for i in 0...steps {
            
            let t = Float(i) / Float(steps)
            
            let point = getPointAtPct(pct: t, points: simplePoints)
            
            resampled.append(point)
        }
        
        smoothedPoints = resampleByPixels(points: resampled, spacing: resampledSpace)
        
        setNeedsDisplay()
    }
    
    func drawLine(ctx:CGContext, points:[CGPoint]) {
        guard let firstPoint = points.first else { return }
        ctx.move(to: firstPoint)
        for pt in points {
            ctx.addLine(to: pt)
        }
        ctx.strokePath()
    }
    
    func drawDots(ctx:CGContext, points:[CGPoint], radius:CGFloat = 10.0, filled:Bool = true) {
        let r = radius
        for pt in points {
            ctx.addEllipse(in: CGRect(x: pt.x-r/2, y: pt.y-r/2, width: r, height: r))
        }
        filled ? ctx.fillPath() : ctx.strokePath()
    }
    override func draw(_ rect: CGRect) {
        
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        ctx.setLineWidth(1)
        ctx.setStrokeColor(UIColor.black.cgColor)
        drawLine(ctx: ctx, points: points)
        
        ctx.setStrokeColor(UIColor.green.cgColor)
        ctx.setStrokeColor(UIColor.black.cgColor)
        drawDots(ctx: ctx, points: simplePoints, radius: 15, filled: false)
       
        ctx.setLineWidth(3)
        ctx.setStrokeColor(UIColor.blue.cgColor)
        ctx.setFillColor(UIColor.blue.cgColor)
        drawDots(ctx: ctx, points: smoothedPoints, radius: 10.0)
        drawLine(ctx: ctx, points: smoothedPoints)
        
        
        let f = Float(0.5 + 0.5 * sin(timef * .pi))
        let pt = getPointAtPct(pct: f, points: smoothedPoints)
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.addEllipse(in: CGRect(x: pt.x-10, y: pt.y-10, width: 20, height: 20))
        ctx.fillPath()
        
    }
    
    deinit {
        displayLink?.invalidate()
        displayLink = nil
    }
}
