//
//  Function.swift
//  Book_Sources
//
//  Created by Noah Peeters on 23.03.19.
//

import UIKit

public struct Function<Input, Output> {
    public typealias MapFunction = (Input) -> Output

    private let mapping: MapFunction

    private init(mapping: @escaping MapFunction) {
        self.mapping = mapping
    }

    public func apply(to value: Input) -> Output {
        return mapping(value)
    }

    public func map<MappedOutput>(mapping: @escaping (Output) -> MappedOutput) -> Function<Input, MappedOutput> {
        return Function<Input, MappedOutput>() {
            return mapping(self.apply(to: $0))
        }
    }

    public static func map(mapping: @escaping MapFunction) -> Function {
        return Function(mapping: mapping)
    }
}

extension Function where Input == Output {
    public static var id: Function<Input, Output> { return Function<Input, Output>() { $0 } }
}

extension Function where Output == CGFloat {
    public func toHueColor() -> Function<Input, UIColor> {
        return map { UIColor(hue: $0, saturation: 1, brightness: $0 < 1 ? 1 : 0, alpha: 1) }
    }
}

extension Function where Output == UIColor {
    public func toPixelData() -> Function<Input, PixelData> {
        return map { PixelData(color: $0) }
    }
}

