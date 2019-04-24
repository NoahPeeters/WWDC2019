//
//  Settings.swift
//  Book_Sources
//
//  Created by Noah Peeters on 23.03.19.
//

import Foundation
//import PlaygroundSupport

public final class Settings: Codable {
    let juliaSetConstant: ComplexNumber?
    let maxIterations: Int
    let iterationPixelData: [PixelData]

    private init(juliaSetConstant: ComplexNumber?, maxIterations: Int, colorPaletteGenerator: ColorPaletteGenerator) {
        self.juliaSetConstant = juliaSetConstant
        self.maxIterations = maxIterations

        self.iterationPixelData = colorPaletteGenerator.generatePalette(forMaxIterations: maxIterations) + [PixelData.black]
    }

    public static func mandelbrot(maxIterations: Int = 1000, colorPaletteGenerator: ColorPaletteGenerator = HueColorPaletteGenerator()) -> Settings {
        return Settings(juliaSetConstant: nil, maxIterations: maxIterations, colorPaletteGenerator: colorPaletteGenerator)
    }

    public static func juliaSet(constant: ComplexNumber, maxIterations: Int = 1000, colorPaletteGenerator: ColorPaletteGenerator = HueColorPaletteGenerator()) -> Settings {
        return Settings(juliaSetConstant: constant, maxIterations: maxIterations, colorPaletteGenerator: colorPaletteGenerator)
    }

//    public func sendToLiveView() {
//        let page = PlaygroundPage.current
//        let proxy = page.liveView as! PlaygroundRemoteLiveViewProxy
//
//        guard let encoded = try? JSONEncoder().encode(self) else { return }
//
//        proxy.send(.data(encoded))
//    }
//
//    static func decode(message: PlaygroundValue) throws -> Settings {
//        guard case let .data(data) = message else {
//            throw DecodingError.invalidPlaygroundValueType
//        }
//
//        return try JSONDecoder().decode(Settings.self, from: data)
//    }

    enum DecodingError: Error {
        case invalidPlaygroundValueType
    }
}
