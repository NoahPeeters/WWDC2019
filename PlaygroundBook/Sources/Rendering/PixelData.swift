//
//  PixelData.swift
//  Book_Sources
//
//  Created by Noah Peeters on 23.03.19.
//

import UIKit

public struct PixelData: Codable {
    let alpha: UInt8
    let red: UInt8
    let green: UInt8
    let blue: UInt8

    public static let zero = PixelData(alpha: 0, red: 0, green: 0, blue: 0)
    public static let black = PixelData(alpha: 255, red: 0, green: 0, blue: 0)

    init(alpha: UInt8, red: UInt8, green: UInt8, blue: UInt8) {
        self.alpha = alpha
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(color: UIColor) {
        var alpha: CGFloat = 0
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        self.init(alpha: UInt8(alpha * 255), red: UInt8(red * 255), green: UInt8(green * 255), blue: UInt8(blue * 255))
    }
}
