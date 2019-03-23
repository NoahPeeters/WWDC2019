//
//  HueColorPaletteGenerator.swift
//  Book_Sources
//
//  Created by Noah Peeters on 23.03.19.
//

import UIKit

public struct HueColorPaletteGenerator: ColorPaletteGenerator {
    let hueFactor: CGFloat

    public init(hueFactor: CGFloat = 1) {
        self.hueFactor = hueFactor
    }

    public func generatePalette(forIterations iterations: [CGFloat]) -> [PixelData] {
        return iterations.map {
            PixelData(color: UIColor(hue: $0 * hueFactor, saturation: 1, brightness: 1, alpha: 1))
        }
    }
}
