//
//  Shader.metal
//  Book_Sources
//
//  Created by Noah Peeters on 24.03.19.
//

#include <metal_stdlib>

using namespace metal;

template<typename T> struct ComplexNumber {
    T real;
    T imaginary;

    ComplexNumber(T real, T imaginary): real(real), imaginary(imaginary) {}

    T squaredMagnitute() const {
        return (real * real) + (imaginary * imaginary);
    }

    ComplexNumber<T> operator*(const thread ComplexNumber<T>& other) const {
        return ComplexNumber(real * other.real - imaginary * other.imaginary,
                             real * other.imaginary + imaginary * other.real);
    }

    ComplexNumber<T> operator+(const thread ComplexNumber<T>& other) const {
        return ComplexNumber(real + other.real,
                             imaginary + other.imaginary);
    }
};

kernel void mandelbrotShader(texture2d<float, access::write> output [[texture(0)]],
                             uint2 upos [[thread_position_in_grid]],
                             const device float4& centerPoint [[buffer(0)]]) {

    uint width = output.get_width();
    uint height = output.get_height();

    if (upos.x >= width || upos.y >= height) {
        return;
    }

//    output.write(float4(float(upos.x) / 1000.0, 0, 0, 1), upos);

    ComplexNumber<float> start(float(int(upos.x) - int(width/2)) / centerPoint.z - centerPoint.x, float(int(upos.y) - int(height/2)) / centerPoint.z - centerPoint.y);
    ComplexNumber<float> z = start;

    for (int i = 0; i < 100; i++) {
        if (z.squaredMagnitute() > 4) {
            output.write(float4(float(i)/100.0, 0, 0, 1), upos);
            return;
        }

        z = z * z + start;
    }

    output.write(float4(0, 0, 0, 1), upos);
}
