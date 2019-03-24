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

//: Here you can change which colors are used.

//: - Experiment: Try to change the `iterationExponent` and `hueFactor` and find out what they do.

//: - Important: After each change you have to click `Run My Code` again.

//: - Note: Go to the next page to find a new way to color the mandelbrot set.

let settings = Settings.mandelbrot(
    colorPaletteGenerator: PowerTransformationColorPaletteGenerator(
        iterationExponent: 0.2,
        chained: HueColorPaletteGenerator(hueFactor: 5)))

settings.sendToLiveView()
