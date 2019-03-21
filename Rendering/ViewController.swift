//
//  ViewController.swift
//  Rendering
//
//  Created by Noah Peeters on 20.03.19.
//  Copyright © 2019 Noah Peeters. All rights reserved.
//

import UIKit

public struct PixelData {
    var a: UInt8 = 255
    var r: UInt8
    var g: UInt8
    var b: UInt8
}

struct ComplexNumber {
    let real: Double
    let imaginary: Double
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

//    override func viewDidLayoutSubviews() {
//        for i in 0..<100 {
//            render()
//        }
//    }

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
        var pixels = Array(repeating: PixelData(a: 0, r: 0, g: 0, b: 0), count: width * height)

        let numberOfBlocks = 16
        let totalSize = height * width
        let size = totalSize / numberOfBlocks

        for i in 0..<numberOfBlocks {
            calculationQueue.addOperation { [self] in
                for index in i * size ..< (i + 1) * size {
                    let x = index % width
                    let y = index / width

                    let value = self.valuesMapper(number: ComplexNumber(
                        real: Double(x - width / 2) * Double(sizeFactor) / self.scaleFactor + self.centerX,
                        imaginary: Double(y - height / 2) * Double(sizeFactor) / self.scaleFactor + self.centerY))

                    pixels[index] = self.colorMapper(value: value)
                }
            }
        }

        backgrogroundThread.async { [self] in
            self.calculationQueue.waitUntilAllOperationsAreFinished()

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

    func colorMapper(value: Double) -> PixelData {
        if value == -1 {
            return PixelData(a: 255, r: 0, g: 0, b: 0)
        } else {
            return PixelData(a: 255, r: 127 + UInt8(value * 127), g: UInt8(value * 255), b: 0)
        }
    }

    func valuesMapper(number: ComplexNumber) -> Double {
        var current = number
        let maxIterations = 1000
        var iterations = 0

        while (current.real * current.real + current.imaginary * current.imaginary <= 2 * 2 && iterations < maxIterations) {
            current = current * current + number
            iterations += 1
        }

        if iterations == maxIterations {
            return -1
        }

        return pow(Double(iterations) / Double(maxIterations), 0.1)
    }
}

extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
