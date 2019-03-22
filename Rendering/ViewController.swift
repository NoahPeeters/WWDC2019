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

        calculationQueue.maxConcurrentOperationCount = 8

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

    private let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    private let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
    private var scaleFactor: Double = 200
    private var fastMode = false
    private var centerX: Double = 0
    private var centerY: Double = 0

    func shouldRenderFast(recognizer: UIGestureRecognizer) -> Bool {
        return [UISwipeGestureRecognizer.State.began, .changed, .possible].contains(recognizer.state)
    }

    @objc func pinchGestureRecognizerChanged(recognizer: UIPinchGestureRecognizer) {
        let oldScaleFactor = scaleFactor
        scaleFactor *= Double(recognizer.scale)

        let center = recognizer.location(in: view)

        let xDistance = Double(center.x - view.bounds.midX)
        centerX -= xDistance / scaleFactor - xDistance / oldScaleFactor
        let yDistance = Double(center.y - view.bounds.midY)
        centerY -= yDistance / scaleFactor - yDistance / oldScaleFactor
        recognizer.scale = 1

        fastMode = shouldRenderFast(recognizer: recognizer)
        render()
    }

    @objc func panGestureRecognizerChanged(recognizer: UIPanGestureRecognizer) {
        let movement = recognizer.translation(in: view)
        recognizer.setTranslation(.zero, in: view)
        centerX -= Double(movement.x) / scaleFactor
        centerY -= Double(movement.y) / scaleFactor
        fastMode = shouldRenderFast(recognizer: recognizer)
        render()
    }

    let backgrogroundThread = DispatchQueue(label: "Worker")
    let calculationQueue = OperationQueue()

    func render() {
        guard !fastMode || calculationQueue.operationCount == 0 else {
            return
        }

        calculationQueue.cancelAllOperations()

        let sizeFactor: CGFloat = fastMode ? 10 : 1
        let width = Int(view.bounds.width / sizeFactor)
        let height = Int(view.bounds.height / sizeFactor)
        let totalSize = height * width
        var pixels = Array(repeating: PixelData.zero, count: totalSize)

        calculationQueue.addOperation { [self] in
            for index in 0..<totalSize {
                let x = index % width
                let y = index / width

                let number = ComplexNumber(
                    real: CGFloat(x - width / 2) * CGFloat(sizeFactor) / CGFloat(self.scaleFactor) + CGFloat(self.centerX),
                    imaginary: CGFloat(y - height / 2) * CGFloat(sizeFactor) / CGFloat(self.scaleFactor) + CGFloat(self.centerY))

                pixels[index] = self.mapping.apply(to: number)
            }

            let providerRef = CGDataProvider(
                data: NSData(bytes: &pixels, length: pixels.count * MemoryLayout<PixelData>.size)
            )!

            let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * MemoryLayout<PixelData>.size,
                space: self.rgbColorSpace,
                bitmapInfo: self.bitmapInfo,
                provider: providerRef,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent)!

            DispatchQueue.main.async {
                self.imageView.image = UIImage(cgImage: image)
            }
        }
    }

    let mapping = Mapper.id.map { (number: ComplexNumber) -> CGFloat in
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

struct Mapper<Input, Output> {
    typealias Function = (Input) -> Output

    private let mapping: Function

    private init(mapping: @escaping Function) {
        self.mapping = mapping
    }

    func apply(to value: Input) -> Output {
        return mapping(value)
    }

    func map<MappedOutput>(mapping: @escaping (Output) -> MappedOutput) -> Mapper<Input, MappedOutput> {
        return Mapper<Input, MappedOutput>() {
            return mapping(self.apply(to: $0))
        }
    }

    static func map(mapping: @escaping Function) -> Mapper {
        return Mapper(mapping: mapping)
    }
}

extension Mapper where Input == Output {
    static var id: Mapper<Input, Output> { return Mapper<Input, Output>() { $0 } }
}

extension Mapper where Output == CGFloat {
    func toHueColor() -> Mapper<Input, UIColor> {
        return map { UIColor(hue: $0, saturation: 1, brightness: $0 < 1 ? 1 : 0, alpha: 1) }
    }
}

extension Mapper where Output == UIColor {
    func toPixelData() -> Mapper<Input, PixelData> {
        return map { PixelData(color: $0) }
    }
}
