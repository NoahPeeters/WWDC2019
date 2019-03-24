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
The julia set is quite similar to the mandelbrot set. But this the  `c` in `f_c(z) = z^2 + c` is a constant and you can choose it's value 🎉.
*/

/*:
 - Experiment: Try different values for the constant.
*/

let settings = Settings.juliaSet(
    constant: ComplexNumber(real: /*#-editable-code*/-0.8/*#-end-editable-code*/, imaginary: /*#-editable-code*/0.156/*#-end-editable-code*/))

settings.sendToLiveView()
