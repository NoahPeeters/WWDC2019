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

//: Here you can experiment with other color with the julia set.

let settings = Settings.juliaSet(
    constant: ComplexNumber(real: /*#-editable-code*/-0.8/*#-end-editable-code*/, imaginary: /*#-editable-code*/0.156/*#-end-editable-code*/),
    colorPaletteGenerator: PowerTransformationColorPaletteGenerator(
        iterationExponent: /*#-editable-code*/0.2/*#-end-editable-code*/,
        chained: HueColorPaletteGenerator(hueFactor: /*#-editable-code*/5/*#-end-editable-code*/)))

settings.sendToLiveView()
