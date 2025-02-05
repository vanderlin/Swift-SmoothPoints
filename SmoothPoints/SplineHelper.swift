//
//  Spline.swift
//  SmoothPoints
//
//  Created by Todd Vanderlin on 2/5/25.
//

import Foundation
import UIKit
import CoreGraphics

func clamp<T: Comparable>(_ value: T, min minValue: T, max maxValue: T) -> T {
    return min(max(value, minValue), maxValue)
}

// MARK: - Hermite Interpolation (with tension & bias)
func hermiteInterpolate(y0: CGFloat, y1: CGFloat, y2: CGFloat, y3: CGFloat, mu: CGFloat, tension: CGFloat, bias: CGFloat) -> CGFloat {
    let mu2 = mu * mu
    let mu3 = mu2 * mu
    
    let m0 = ((y1 - y0) * (1 + bias) * (1 - tension) / 2) + ((y2 - y1) * (1 - bias) * (1 - tension) / 2)
    let m1 = ((y2 - y1) * (1 + bias) * (1 - tension) / 2) + ((y3 - y2) * (1 - bias) * (1 - tension) / 2)

    let a0 =  2 * mu3 - 3 * mu2 + 1
    let a1 =      mu3 - 2 * mu2 + mu
    let a2 =      mu3 -     mu2
    let a3 = -2 * mu3 + 3 * mu2
    
    return (a0 * y1) + (a1 * m0) + (a2 * m1) + (a3 * y2)
}

func hermite(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, t: CGFloat, tension: CGFloat, bias: CGFloat) -> CGPoint {
    let x = hermiteInterpolate(y0: p0.x, y1: p1.x, y2: p2.x, y3: p3.x, mu: t, tension: tension, bias: bias)
    let y = hermiteInterpolate(y0: p0.y, y1: p1.y, y2: p2.y, y3: p3.y, mu: t, tension: tension, bias: bias)
    return CGPoint(x: x, y: y)
}

// MARK: - Cubic Interpolation
func cubicInterpolate(y0: CGFloat, y1: CGFloat, y2: CGFloat, y3: CGFloat, mu: CGFloat) -> CGFloat {
    let mu2 = mu * mu
    let a0 = y3 - y2 - y0 + y1
    let a1 = y0 - y1 - a0
    let a2 = y2 - y0
    let a3 = y1
    
    return a0 * mu * mu2 + a1 * mu2 + a2 * mu + a3
}

func cubic(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, t: CGFloat) -> CGPoint {
    let x = cubicInterpolate(y0: p0.x, y1: p1.x, y2: p2.x, y3: p3.x, mu: t)
    let y = cubicInterpolate(y0: p0.y, y1: p1.y, y2: p2.y, y3: p3.y, mu: t)
    return CGPoint(x: x, y: y)
}

// MARK: - Cubic Bézier Interpolation
func cubicBezier(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, t: CGFloat) -> CGPoint {
    let t2 = t * t
    let t3 = t2 * t
    
    var point = CGPoint.zero
    point.x = t3 * (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) / 6
    point.x += t2 * (3 * p0.x - 6 * p1.x + 3 * p2.x) / 6
    point.x += t * (-3 * p0.x + 3 * p2.x) / 6
    point.x += (p0.x + 4 * p1.x + p2.x) / 6

    point.y = t3 * (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) / 6
    point.y += t2 * (3 * p0.y - 6 * p1.y + 3 * p2.y) / 6
    point.y += t * (-3 * p0.y + 3 * p2.y) / 6
    point.y += (p0.y + 4 * p1.y + p2.y) / 6
    
    return point
}

// MARK: - Catmull-Rom Interpolation
func catmullRom(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, t: CGFloat) -> CGPoint {
    let t2 = t * t
    let t3 = t2 * t
    
    var point = CGPoint.zero
    point.x = t3 * (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) / 2
    point.x += t2 * (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) / 2
    point.x += t * (-p0.x + p2.x) / 2
    point.x += p1.x

    point.y = t3 * (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) / 2
    point.y += t2 * (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) / 2
    point.y += t * (-p0.y + p2.y) / 2
    point.y += p1.y

    return point
}

// MARK: - Linear
func interpolateLinear(p0: CGPoint, p1: CGPoint, t: CGFloat) -> CGPoint {
    return CGPoint(
        x: p0.x + (p1.x - p0.x) * t,
        y: p0.y + (p1.y - p0.y) * t
    )
}

func distance(_ p0: CGPoint, _ p1: CGPoint) -> CGFloat {
    return hypot(p1.x - p0.x, p1.y - p0.y)
}

func resampleByPixels(points: [CGPoint], spacing: CGFloat) -> [CGPoint] {
    guard points.count > 1 else { return points }

    var resampledPoints: [CGPoint] = [points.first!] // Start with the first point
    var accumulatedDistance: CGFloat = 0.0

    for i in 1..<points.count {
        let p0 = points[i - 1]
        let p1 = points[i]
        
        let segmentLength = distance(p0, p1)
        
        if segmentLength + accumulatedDistance >= spacing {
            var t: CGFloat = (spacing - accumulatedDistance) / segmentLength
            while t <= 1.0 {
                let newPoint = interpolateLinear(p0: p0, p1: p1, t: t)
                resampledPoints.append(newPoint)
                t += spacing / segmentLength
            }
            accumulatedDistance = (segmentLength + accumulatedDistance).truncatingRemainder(dividingBy: spacing)
        } else {
            accumulatedDistance += segmentLength
        }
    }
    
    guard let f = points.last else { return resampledPoints }
    resampledPoints.append(f)

    return resampledPoints
}

// MARK: - simplification algorithm.
class Simplify {
    static func simplifyRadialDistance(_ points: [CGPoint], tolerance: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }
        
        var newPoints: [CGPoint] = [points.first!]
        var prevPoint = points.first!
        
        for point in points {
            let distance = hypot(point.x - prevPoint.x, point.y - prevPoint.y)
            if distance > tolerance {
                newPoints.append(point)
                prevPoint = point
            }
        }
        
        if newPoints.last != points.last {
            newPoints.append(points.last!)
        }
        
        return newPoints
    }
    
    static func simplifyDouglasPeucker(_ points: [CGPoint], tolerance: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }
        
        var maxDist: CGFloat = 0
        var index = 0
        let start = points.first!
        let end = points.last!
        
        for i in 1..<points.count - 1 {
            let distance = perpendicularDistance(from: points[i], toLineStart: start, toLineEnd: end)
            if distance > maxDist {
                maxDist = distance
                index = i
            }
        }
        
        if maxDist > tolerance {
            let left = simplifyDouglasPeucker(Array(points[0...index]), tolerance: tolerance)
            let right = simplifyDouglasPeucker(Array(points[index...]), tolerance: tolerance)
            return left + right.dropFirst()
        } else {
            return [start, end]
        }
    }
    
    private static func perpendicularDistance(from point: CGPoint, toLineStart start: CGPoint, toLineEnd end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        if dx == 0, dy == 0 { return hypot(point.x - start.x, point.y - start.y) }
        
        let t = ((point.x - start.x) * dx + (point.y - start.y) * dy) / (dx * dx + dy * dy)
        let projection = CGPoint(x: start.x + t * dx, y: start.y + t * dy)
        
        return hypot(point.x - projection.x, point.y - projection.y)
    }
    
    static func simplify(_ points: [CGPoint], tolerance: CGFloat = 3.0, highQuality: Bool = false) -> [CGPoint] {
        if points.count <= 2 { return points }
        
        let reducedPoints = highQuality ? points : simplifyRadialDistance(points, tolerance: tolerance)
        return simplifyDouglasPeucker(reducedPoints, tolerance: tolerance)
    }
}
