//
//  ViewController.swift
//  Rendering
//
//  Created by Noah Peeters on 20.03.19.
//  Copyright © 2019 Noah Peeters. All rights reserved.
//

import UIKit

public struct PixelData {
    let alpha: UInt8
    let red: UInt8
    let green: UInt8
    let blue: UInt8

    public static let zero = PixelData(alpha: 0, red: 0, green: 0, blue: 0)

    init(alpha: UInt8, red: UInt8, green: UInt8, blue: UInt8) {
        self.alpha = alpha
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(color: UIColor) {
        var alpha: CGFloat = 0
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        self.init(alpha: UInt8(alpha * 255), red: UInt8(red * 255), green: UInt8(green * 255), blue: UInt8(blue * 255))
    }
}

struct ComplexNumber {
    let real: CGFloat
    let imaginary: CGFloat
}

func * (lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
    return ComplexNumber(
        real: lhs.real * rhs.real - lhs.imaginary * rhs.imaginary,
        imaginary: lhs.real * rhs.imaginary + lhs.imaginary * rhs.real)
}

func + (lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
    return ComplexNumber(
        real: lhs.real + rhs.real,
        imaginary: lhs.imaginary + rhs.imaginary)
}

func - (lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
    return ComplexNumber(
        real: lhs.real - rhs.real,
        imaginary: lhs.imaginary - rhs.imaginary)
}

class ViewController: UIViewController {
    let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        let scaleGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchGestureRecognizerChanged))
        scaleGestureRecognizer.delegate = self
        view.addGestureRecognizer(scaleGestureRecognizer)

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerChanged))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)
    }

    override func viewLayoutMarginsDidChange() {
        render()
    }

    private var scaleFactor: CGFloat = 200
    private var fastMode = false
    private var center = CGPoint.zero

    func shouldRenderFast(recognizer: UIGestureRecognizer) -> Bool {
        return [UISwipeGestureRecognizer.State.began, .changed, .possible].contains(recognizer.state)
    }

    @objc func pinchGestureRecognizerChanged(recognizer: UIPinchGestureRecognizer) {
        let oldScaleFactor = scaleFactor
        scaleFactor *= recognizer.scale
        recognizer.scale = 1

        let scaleCenter = recognizer.location(in: view)

        let xDistance = scaleCenter.x - view.bounds.midX
        let yDistance = scaleCenter.y - view.bounds.midY

        center = CGPoint(
            x: center.x - xDistance / scaleFactor + xDistance / oldScaleFactor,
            y: center.y - yDistance / scaleFactor + yDistance / oldScaleFactor)

        fastMode = shouldRenderFast(recognizer: recognizer)
        render()
    }

    @objc func panGestureRecognizerChanged(recognizer: UIPanGestureRecognizer) {
        let movement = recognizer.translation(in: view)
        recognizer.setTranslation(.zero, in: view)

        center = CGPoint(
            x: center.x - movement.x / scaleFactor,
            y: center.y - movement.y / scaleFactor)
        fastMode = shouldRenderFast(recognizer: recognizer)
        render()
    }

    let backgrogroundThread = DispatchQueue(label: "Worker")
    var currentRunIsFastMode = false
    private var currentRenderProcess: RenderProcess?

    func render() {
        guard !fastMode || (currentRenderProcess?.isStopped ?? true) || !currentRunIsFastMode else {
            return
        }

        self.currentRenderProcess?.stop()
        self.currentRunIsFastMode = fastMode
        let sizeFactor: CGFloat = fastMode ? 6 : 1

        let renderProcess = RenderProcess(
            width: Int(view.bounds.width / sizeFactor),
            height: Int(view.bounds.height / sizeFactor),
            scaling: CGFloat(sizeFactor) / CGFloat(self.scaleFactor),
            center: center,
            function: function
        )
        self.currentRenderProcess = renderProcess

        renderProcess.start { image in
            self.imageView.image = image
        }
    }

    let function = Function.id.map { (number: ComplexNumber) -> CGFloat in
        var current = number
        let maxIterations = 1000
        var iterations = 0

        while (current.real * current.real + current.imaginary * current.imaginary <= 2 * 2 && iterations < maxIterations) {
            current = current * current + ComplexNumber(real: -0.8, imaginary: 0.156)
            iterations += 1
        }

        return pow(CGFloat(iterations) / CGFloat(maxIterations), 0.5)
    }.toHueColor().toPixelData()
}

extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}


class RenderProcess {
    private static let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    private static let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)

    private let calculationQueue = OperationQueue()
    private let width: Int
    private let height: Int
    private let scaling: CGFloat
    private let center: CGPoint
    private let function: Function<ComplexNumber, PixelData>
    private(set) var isStopped = false

    init(width: Int, height: Int, scaling: CGFloat, center: CGPoint, function: Function<ComplexNumber, PixelData>) {
        self.width = width
        self.height = height
        self.scaling = scaling
        self.center = center
        self.function = function
    }

    func stop() {
        guard !isStopped else { return }
        isStopped = true
        calculationQueue.cancelAllOperations()
    }

    func start(callback: @escaping (UIImage) -> Void) {
        let totalSize = height * width
        var pixels = Array(repeating: PixelData.zero, count: totalSize)

        for y in 0..<self.height {
            let startIndex = y * self.width

            calculationQueue.addOperation {
                for x in 0..<self.width {
                    guard !self.isStopped else { return }

                    let index = startIndex + x

                    let number = ComplexNumber(
                        real: CGFloat(x - self.width / 2) * self.scaling + self.center.x,
                        imaginary: CGFloat(y - self.height / 2) * self.scaling + self.center.y)

                    pixels[index] = self.function.apply(to: number)
                }
            }
        }

        DispatchQueue.global().async {
            self.calculationQueue.waitUntilAllOperationsAreFinished()

            guard !self.isStopped else { return }

            let providerRef = CGDataProvider(
                data: NSData(bytes: &pixels, length: pixels.count * MemoryLayout<PixelData>.size)
            )!

            let image = CGImage(
                width: self.width,
                height: self.height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: self.width * MemoryLayout<PixelData>.size,
                space: RenderProcess.rgbColorSpace,
                bitmapInfo: RenderProcess.bitmapInfo,
                provider: providerRef,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent)!

            DispatchQueue.main.async {
                callback(UIImage(cgImage: image))
                self.isStopped = true
            }

        }
    }
}


struct Function<Input, Output> {
    typealias MapFunction = (Input) -> Output

    private let mapping: MapFunction

    private init(mapping: @escaping MapFunction) {
        self.mapping = mapping
    }

    func apply(to value: Input) -> Output {
        return mapping(value)
    }

    func map<MappedOutput>(mapping: @escaping (Output) -> MappedOutput) -> Function<Input, MappedOutput> {
        return Function<Input, MappedOutput>() {
            return mapping(self.apply(to: $0))
        }
    }

    static func map(mapping: @escaping MapFunction) -> Function {
        return Function(mapping: mapping)
    }
}

extension Function where Input == Output {
    static var id: Function<Input, Output> { return Function<Input, Output>() { $0 } }
}

extension Function where Output == CGFloat {
    func toHueColor() -> Function<Input, UIColor> {
        return map { UIColor(hue: $0, saturation: 1, brightness: $0 < 1 ? 1 : 0, alpha: 1) }
    }
}

extension Function where Output == UIColor {
    func toPixelData() -> Function<Input, PixelData> {
        return map { PixelData(color: $0) }
    }
}
