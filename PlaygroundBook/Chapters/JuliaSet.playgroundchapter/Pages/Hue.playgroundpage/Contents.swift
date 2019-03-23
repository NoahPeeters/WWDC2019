//#-hidden-code
//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  The Swift file containing the source code edited by the user of this playground book.
//

import UIKit
import PlaygroundSupport

//#-end-hidden-code

let settings = Settings.juliaSet(
    constant: ComplexNumber(real: -0.8, imaginary: 0.156),
    colorPaletteGenerator: PowerTransformationColorPaletteGenerator(
        iterationExponent: 0.2,
        chained: HueColorPaletteGenerator(hueFactor: 5)))

settings.sendToLiveView()
