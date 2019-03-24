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
 The mandelbrot set is the set of complex numbers `c` for which the function `f_c(z) = z^2 + c` does not diverge.
 But you don't hvae to be good at math or understand the previous sentence. All you have to know is that it's a complex mathematical conzept which looks really cool.
*/

/*:
 - Experiment:
 Explore the mandelbrot set:
    * Click `Run My Code`
    * Explore the mandelbrot set by piching and panning.

*/

/*:
 - Note: When your done exploring the mandelbrot set, go to the next page to customize the colors.
*/

let settings = Settings.mandelbrot()

settings.sendToLiveView()
