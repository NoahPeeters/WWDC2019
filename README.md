This is my submission for the WWDC 2019 scholarship.

The playground is an interactive demonstration of the mandelbrot and the julia set.

There are two branches:
 - master (which is the version I submitted)
 - metal

On the metal branch, I changed the rendering process to use metal, however, metal only supports 32-bit floats and not 64-bit floats which dramatically reduces the depth the set can be rendered at. Thats why I submitted the master (cpu render) version.
