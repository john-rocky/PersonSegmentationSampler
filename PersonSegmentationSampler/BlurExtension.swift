/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Extension of iOS view controller that implements blur techniques.
*/

import Accelerate

extension EditViewController {
    
    func hann1D() {
        let startTime = mach_absolute_time()
        
        let divisor = kernel1D.map { Int32($0) }.reduce(0, +)
        
        // Vertical pass.
        vImageConvolve_ARGB8888(&sourceBuffer!,
                                &destinationBuffer,
                                nil,
                                0, 0,
                                &kernel1D,
                                UInt32(kernelLength),   // Height
                                1,                      // Width
                                divisor,
                                nil,
                                vImage_Flags(kvImageEdgeExtend))
        
        // Horizontal pass.
        vImageConvolve_ARGB8888(&destinationBuffer,
                                &destinationBuffer,
                                nil,
                                0, 0,
                                &kernel1D,
                                1,                      // Height
                                UInt32(kernelLength),   // Width
                                divisor,
                                nil,
                                vImage_Flags(kvImageEdgeExtend))
        
        let endTime = mach_absolute_time()
        print("hann1D", (machToSeconds * Double(endTime - startTime)))
    }
    
    func hann2D() {
        let divisor = kernel2D.map { Int32($0) }.reduce(0, +)
        
        let startTime = mach_absolute_time()
        
        vImageConvolve_ARGB8888(&sourceBuffer!,
                                &destinationBuffer,
                                nil,
                                0, 0,
                                &kernel2D,
                                UInt32(kernelLength),
                                UInt32(kernelLength),
                                divisor,
                                nil,
                                vImage_Flags(kvImageEdgeExtend))
        
        let endTime = mach_absolute_time()
        print("hann2D", (machToSeconds * Double(endTime - startTime)))
    }
    
    func tent() {
        let startTime = mach_absolute_time()
        vImageTentConvolve_ARGB8888(&sourceBuffer!,
                                    &destinationBuffer,
                                    nil,
                                    0, 0,
                                    UInt32(kernelLength),
                                    UInt32(kernelLength),
                                    nil,
                                    vImage_Flags(kvImageEdgeExtend))
        
        let endTime = mach_absolute_time()
        print("  tent", (machToSeconds * Double(endTime - startTime)))
    }
    
    func box() {
        let startTime = mach_absolute_time()
        
        vImageBoxConvolve_ARGB8888(&sourceBuffer!,
                                   &destinationBuffer,
                                   nil,
                                   0, 0,
                                   UInt32(kernelLength),
                                   UInt32(kernelLength),
                                   nil,
                                   vImage_Flags(kvImageEdgeExtend))
        
        let endTime = mach_absolute_time()
        print("   box", (machToSeconds * Double(endTime - startTime)))
    }
    
    func multi() {
        let startTime = mach_absolute_time()
        
        let radius = kernelLength / 2
        let diameter = (radius * 2) + 1
        
        let kernels: [[Int16]] = (1 ... 4).map { index in
            var kernel = [Int16](repeating: 0,
                                 count: diameter * diameter)
            
            for x in 0 ..< diameter {
                for y in 0 ..< diameter {
                    if hypot(Float(radius - x), Float(radius - y)) < Float(radius / index) {
                        kernel[y * diameter + x] = 1
                    }
                }
            }
            
            return kernel
        }
        
        var divisors = kernels.map { return Int32($0.reduce(0, +)) }
        var biases: [Int32] = [0, 0, 0, 0]
        var backgroundColor: UInt8 = 0
        
        kernels[0].withUnsafeBufferPointer { zeroPtr in
            kernels[1].withUnsafeBufferPointer { onePtr in
                kernels[2].withUnsafeBufferPointer { twoPtr in
                    kernels[3].withUnsafeBufferPointer { threePtr in
                        
                        var kernels = [zeroPtr.baseAddress, onePtr.baseAddress,
                                       twoPtr.baseAddress, threePtr.baseAddress]
                        
                        _ = kernels.withUnsafeMutableBufferPointer { kernelsPtr in
                            vImageConvolveMultiKernel_ARGB8888(&sourceBuffer!,
                                                               &destinationBuffer,
                                                               nil,
                                                               0, 0,
                                                               kernelsPtr.baseAddress!,
                                                               UInt32(diameter), UInt32(diameter),
                                                               &divisors,
                                                               &biases,
                                                               &backgroundColor,
                                                               vImage_Flags(kvImageEdgeExtend))
                        }
                    }
                }
            }
        }
        
        let endTime = mach_absolute_time()
        print(" multi", (machToSeconds * Double(endTime - startTime)))
    }
}

/* The following kernel, which is based on a Hann window, is suitable for use with an integer format. This is not used in the demo app. */

let kernel2D: [Int16] = [
    0,    0,    0,      0,      0,      0,      0,
    0,    2025, 6120,   8145,   6120,   2025,   0,
    0,    6120, 18496,  24616,  18496,  6120,   0,
    0,    8145, 24616,  32761,  24616,  8145,   0,
    0,    6120, 18496,  24616,  18496,  6120,   0,
    0,    2025, 6120,   8145,   6120,   2025,   0,
    0,    0,    0,      0,      0,      0,      0
]

let kernel1D: [Int16] = [0, 45, 136, 181, 136, 45, 0]
