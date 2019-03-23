//
//  LinearInterpolationColorPaletteGenerator.swift
//  Book_Sources
//
//  Created by Noah Peeters on 23.03.19.
//

import UIKit

public struct LinearInterpolationColorPaletteGenerator: ColorPaletteGenerator {
    public typealias ColorControlPoint = (point: CGFloat, color: UIColor)

    let colorControlPoints: [ColorControlPoint]

    public init(colorControlPoints: [ColorControlPoint]) {
        self.colorControlPoints = colorControlPoints
    }

    public func generatePalette(forIterations iterations: [CGFloat]) -> [PixelData] {
        var colorIndex = 0

        return iterations.map {
            while $0 > colorControlPoints[colorIndex + 1].point {
                colorIndex += 1
            }

            let colorLow = colorControlPoints[colorIndex]
            let colorHigh = colorControlPoints[colorIndex + 1]
            let percentag = ($0 - colorLow.point)/(colorHigh.point - colorLow.point)

            return PixelData(color: interpolateColors(
                color1: colorLow.color,
                color2: colorHigh.color,
                percentage: percentag))
        }
    }
}

private func interpolateCGFloat(value1: CGFloat, value2: CGFloat, percentage: CGFloat) -> CGFloat {
    return value1 + (value2 - value1) * percentage
}

private func interpolateColors(color1: UIColor, color2: UIColor, percentage: CGFloat) -> UIColor {
    var hue1: CGFloat = 0
    var hue2: CGFloat = 0
    var saturation1: CGFloat = 0
    var saturation2: CGFloat = 0
    var brightness1: CGFloat = 0
    var brightness2: CGFloat = 0
    var alpha1: CGFloat = 0
    var alpha2: CGFloat = 0

    color1.getHue(&hue1, saturation: &saturation1, brightness: &brightness1, alpha: &alpha1)
    color2.getHue(&hue2, saturation: &saturation2, brightness: &brightness2, alpha: &alpha2)

    return UIColor(
        hue: interpolateCGFloat(value1: hue1, value2: hue2, percentage: percentage),
        saturation: interpolateCGFloat(value1: saturation1, value2: saturation2, percentage: percentage),
        brightness: interpolateCGFloat(value1: brightness1, value2: brightness2, percentage: percentage),
        alpha: interpolateCGFloat(value1: alpha1, value2: alpha2, percentage: percentage))
}
