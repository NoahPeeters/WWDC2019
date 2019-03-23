//
//  ColorPaletteGenerator.swift
//  Book_Sources
//
//  Created by Noah Peeters on 23.03.19.
//

import UIKit

public protocol ColorPaletteGenerator {
    func generatePalette(forIterations iterations: [CGFloat]) -> [PixelData]
}

extension ColorPaletteGenerator {
    internal func generatePalette(forMaxIterations maxIterations: Int) -> [PixelData] {
        return generatePalette(forIterations: (0..<maxIterations).map { CGFloat($0)/CGFloat(maxIterations) })
    }
}
