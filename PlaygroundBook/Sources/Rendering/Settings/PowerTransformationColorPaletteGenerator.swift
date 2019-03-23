//
//  PowerTransformationColorPaletteGenerator.swift
//  Book_Sources
//
//  Created by Noah Peeters on 23.03.19.
//

import UIKit

public struct PowerTransformationColorPaletteGenerator: ColorPaletteGenerator {
    private let iterationExponent: CGFloat
    private let chained: ColorPaletteGenerator

    public init(iterationExponent: CGFloat, chained: ColorPaletteGenerator) {
        self.iterationExponent = iterationExponent
        self.chained = chained
    }

    public func generatePalette(forIterations iterations: [CGFloat]) -> [PixelData] {
        return chained.generatePalette(forIterations: iterations.map {
            pow($0, iterationExponent)
        })
    }
}
