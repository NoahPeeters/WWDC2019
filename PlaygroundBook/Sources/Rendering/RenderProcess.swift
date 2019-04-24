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
    private let scaling: BDouble
    private let center: ComplexNumber
    private let settings: Settings

    private(set) internal var isStopped = false

    internal init(width: Int, height: Int, scaling: BDouble, center: ComplexNumber, settings: Settings) {
        self.width = width
        self.height = height
        self.scaling = scaling
        self.center = center
        self.settings = settings

        calculationQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
    }

    internal func stop() {
        guard !isStopped else { return }
        isStopped = true
        calculationQueue.cancelAllOperations()
    }

    private var cachedPixels: [PixelData]?
    private var cachedPixelsWidth: Int = 0
    private var cachedPixelsHeight: Int = 0

    internal func start(samplingFactor: Int = 16, callback: @escaping (UIImage) -> Void) {
        print("Start \(samplingFactor)")
        let cgSamplingFactor = BDouble(samplingFactor)

        let samplingHeight = height / samplingFactor
        let samplingWidth = width / samplingFactor

        let totalSize = samplingHeight * samplingWidth
        var pixels = Array(repeating: PixelData.zero, count: totalSize)

        guard totalSize > 0 else { return }

        for y in 0..<samplingHeight {
            let startIndex = y * samplingWidth

            calculationQueue.addOperation {
                var localPixels = Array(repeating: PixelData.zero, count: samplingWidth)
                for x in 0..<samplingWidth {
                    guard !self.isStopped else { return }

                    if let cachedPixels = self.cachedPixels, y % 2 == 0, x % 2 == 0, x/2 < self.cachedPixelsWidth, y/2 < self.cachedPixelsHeight {
                        localPixels[x] = cachedPixels[y/2*self.cachedPixelsWidth + x/2]
                    } else {
                        let number = ComplexNumber(
                            real: BDouble(x - samplingWidth / 2) * cgSamplingFactor / self.scaling + self.center.real,
                            imaginary: BDouble(y - samplingHeight / 2) * cgSamplingFactor / self.scaling + self.center.imaginary)

                        localPixels[x] = self.calculateColor(forNumber: number)
                    }
                }

                self.syncQueue.sync {
                    pixels.replaceSubrange(startIndex..<startIndex + samplingWidth, with: localPixels)
                }
            }
        }

        DispatchQueue.global().async {
            self.calculationQueue.waitUntilAllOperationsAreFinished()
            self.cachedPixels = pixels
            self.cachedPixelsWidth = samplingWidth
            self.cachedPixelsHeight = samplingHeight

            guard !self.isStopped else { return }

            if samplingFactor > 1 {
                self.start(samplingFactor: samplingFactor / 2, callback: callback)
            } else {
                self.isStopped = true
            }

            let providerRef = CGDataProvider(
                data: NSData(bytes: &pixels, length: totalSize * MemoryLayout<PixelData>.size)
            )!

            let image = CGImage(
                width: samplingWidth,
                height: samplingHeight,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: samplingWidth * MemoryLayout<PixelData>.size,
                space: RenderProcess.rgbColorSpace,
                bitmapInfo: RenderProcess.bitmapInfo,
                provider: providerRef,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent)!

            DispatchQueue.main.async {
                callback(UIImage(cgImage: image))
            }
        }
    }

    func calculateColor(forNumber number: ComplexNumber) -> PixelData {
        var current = number
        var iterations = 0

        while (iterations < settings.maxIterations && current.real * current.real + current.imaginary * current.imaginary <= 2 * 2) {
            current = current * current + (settings.juliaSetConstant ?? number)
            iterations += 1
        }

        return settings.iterationPixelData[iterations]
    }
}
