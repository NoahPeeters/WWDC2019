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

/*:
 - Experiment:
    Try to change the control points. You can choose your own colors and change the number.
    If you want to you can add additional control points.
*/

/*:
 - Important:
    Make sure that all numbers are in between 0.0 and 1.0 and that one control point has the value 0 and another one 1 to achieve good results.
*/

let settings = Settings.mandelbrot(
    colorPaletteGenerator: LinearInterpolationColorPaletteGenerator(
        colorControlPoints: [
            (0.00, #colorLiteral(red: 0, green: 0.02745098039, blue: 0.3921568627, alpha: 1)),
            (0.16, #colorLiteral(red: 0.1254901961, green: 0.4196078431, blue: 0.7960784314, alpha: 1)),
            (0.42, #colorLiteral(red: 0.9294117647, green: 1, blue: 1, alpha: 1)),
            (0.64, #colorLiteral(red: 1, green: 0.6666666667, blue: 0, alpha: 1)),
            (0.89, #colorLiteral(red: 0, green: 0.007843137255, blue: 0, alpha: 1)),
            (1.00, #colorLiteral(red: 0, green: 0, blue: 0.2745098039, alpha: 1))
]))

settings.sendToLiveView()
