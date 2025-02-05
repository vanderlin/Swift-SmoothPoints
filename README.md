# SmoothPoints 🖊️✨

**UIKit drawing app** with smooth interpolation methods for rendering curves.

## Features 🚀

-   **Interpolation Methods:** 🏗️
    Cubic, Hermite, Bezier, Catmull-Rom

## Demo 🎥

<p align="center">
![SmoothPoints Demo](https://github.com/vanderlin/Swift-SmoothPoints/blob/main/spline.gif?raw=true)
</p>

## Usage 🛠️

```swift
func getPointAtPct(pct:Float, points:[CGPoint]) -> CGPoint {

    let num:Int = points.count - 1

    let indexf = Float(num) * pct
    let indexi = floor(indexf)

    let f = indexf - indexi

    var p0:CGPoint, p1:CGPoint, p2:CGPoint, p3:CGPoint = .zero

    if shouldClose {
        let i = Int(indexi)

        p0 = points[i % num]
        p1 = points[(i + 1) % num]
        p2 = points[(i + 2) % num]
        p3 = points[(i + 3) % num]
    }
    else {
        p0 = points[clamp(Int(indexi-1), min: 0, max: num)]
        p1 = points[Int(indexi)]
        p2 = points[clamp(Int(indexi+1), min: 0, max: num)]
        p3 = points[clamp(Int(indexi+2), min: 0, max: num)]
    }

    let t = CGFloat(f)

    switch interpolationMethod {
    case .linear:
        return cubic(p0: p0, p1: p1, p2: p2, p3: p3, t:t)
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
    let steps = 10 * simplePoints.count
    for i in 0...steps {

        let t = Float(i) / Float(steps)

        let point = getPointAtPct(pct: t, points: simplePoints)

        resampled.append(point)
    }

    smoothedPoints = resampled
    setNeedsDisplay()
}
```
