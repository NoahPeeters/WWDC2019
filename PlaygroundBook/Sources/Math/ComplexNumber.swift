//
//  ComplexNumber.swift
//  Book_Sources
//
//  Created by Noah Peeters on 23.03.19.
//

import UIKit

public struct ComplexNumber: Codable, Hashable {
    public let real: BDouble
    public let imaginary: BDouble

    public init(real: BDouble, imaginary: BDouble) {
        self.real = real
        self.imaginary = imaginary
    }
}

public func * (lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
    return ComplexNumber(
        real: lhs.real * rhs.real - lhs.imaginary * rhs.imaginary,
        imaginary: lhs.real * rhs.imaginary + lhs.imaginary * rhs.real)
}

public func + (lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
    return ComplexNumber(
        real: lhs.real + rhs.real,
        imaginary: lhs.imaginary + rhs.imaginary)
}

public func - (lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
    return ComplexNumber(
        real: lhs.real - rhs.real,
        imaginary: lhs.imaginary - rhs.imaginary)
}
