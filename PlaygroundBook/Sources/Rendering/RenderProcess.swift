//
//  RenderProcess.swift
//  Book_Sources
//
//  Created by Noah Peeters on 23.03.19.
//

import UIKit

internal class RenderProcess {
    private static let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    private static let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)

    private let calculationQueue = OperationQueue()
    private let syncQueue = DispatchQueue(label: "SyncQueue")
    private let width: Int
    private let height: Int
    private let scaling: CGFloat
    private let center: CGPoint
    private let function: Function<ComplexNumber, PixelData>
    private(set) internal var isStopped = false

    internal init(width: Int, height: Int, scaling: CGFloat, center: CGPoint, function: Function<ComplexNumber, PixelData>) {
        self.width = width
        self.height = height
        self.scaling = scaling
        self.center = center
        self.function = function

        calculationQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
    }

    internal func stop() {
        guard !isStopped else { return }
        isStopped = true
        calculationQueue.cancelAllOperations()
    }

    internal func start(callback: @escaping (UIImage) -> Void) {
        let totalSize = height * width
        var pixels = Array(repeating: PixelData.zero, count: totalSize)

        guard totalSize > 0 else { return }

        for y in 0..<self.height {
            let startIndex = y * self.width

            calculationQueue.addOperation {
                var localPixels = Array(repeating: PixelData.zero, count: self.width)
                for x in 0..<self.width {
                    guard !self.isStopped else { return }

                    let number = ComplexNumber(
                        real: CGFloat(x - self.width / 2) * self.scaling + self.center.x,
                        imaginary: CGFloat(y - self.height / 2) * self.scaling + self.center.y)

                    localPixels[x] = self.function.apply(to: number)
                }

                self.syncQueue.sync {
                    pixels.replaceSubrange(startIndex..<startIndex + self.width, with: localPixels)
                }
            }
        }

        DispatchQueue.global().async {
            self.calculationQueue.waitUntilAllOperationsAreFinished()

            guard !self.isStopped else { return }

            let providerRef = CGDataProvider(
                data: NSData(bytes: &pixels, length: totalSize * MemoryLayout<PixelData>.size)
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
