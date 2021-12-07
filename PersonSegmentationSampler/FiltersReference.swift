//
//  FiltersReference.swift
//  Blur
//
//  Created by 間嶋大輔 on 2020/03/07.
//  Copyright © 2020 daisuke. All rights reserved.
//

import Foundation
import CoreImage

extension EditViewController {
    
    func zoomBlur(center inputCenter:CIVector,amount inputAmount:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CIZoomBlur", parameters: [kCIInputImageKey: backCIImage,
                                                               kCIInputCenterKey : inputCenter,
                                                               kCIInputAmountKey:inputAmount])
        let out = filter?.outputImage
        return out!
    }
    
    func bumpDistortion(center inputCenter:CIVector,radius inputRadius:NSNumber,scale inputScale:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CIBumpDistortion", parameters: [kCIInputImageKey: backCIImage,
                                                               kCIInputCenterKey : inputCenter,
                                                               kCIInputRadiusKey:inputRadius,
                                                               kCIInputScaleKey:inputScale])
        let out = filter?.outputImage
        return out!
    }
    
    func circleSplashDistortion(center inputCenter:CIVector,radius inputRadius:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CICircleSplashDistortion", parameters: [kCIInputImageKey: backCIImage,
                                                               kCIInputCenterKey : inputCenter,
                                                               kCIInputRadiusKey:inputRadius])
        let out = filter?.outputImage
        return out!
    }
    
    func circularWrap(center inputCenter:CIVector,radius inputRadius:NSNumber,angle inputAngle:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CICircularWrap", parameters: [kCIInputImageKey: backCIImage,
                                                               kCIInputCenterKey : inputCenter,
                                                               kCIInputRadiusKey:inputRadius,
                                                               kCIInputAngleKey:inputAngle])
        let out = filter?.outputImage
        return out!
    }
    
    func Droste(inset0 inputInsetPoint0:CIVector,inset1 inputInsetPoint1:CIVector,strands inputStrands:NSNumber,periodicity inputPeriodicity:NSNumber,rotation inputRotation:NSNumber,zoom inputZoom:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CIDroste", parameters: [kCIInputImageKey: backCIImage,
                                                               "inputInsetPoint0" : inputInsetPoint0,
                                                               "inputInsetPoint1"  : inputInsetPoint1,
                                                               "inputStrands"  : inputStrands,
                                                               "inputPeriodicity"  : inputPeriodicity,
                                                               "inputRotation"  : inputRotation,
                                                               "inputZoom"  : inputZoom])
        let out = filter?.outputImage
        return out!
    }
    
    func LightTunnel(center inputCenter:CIVector,rotation inputRotation:NSNumber,radius inputRadius:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CILightTunnel", parameters: [kCIInputImageKey: backCIImage,
                                                               kCIInputCenterKey : inputCenter,
                                                               "inputRotation":inputRotation,
                                                               kCIInputRadiusKey:inputRadius])
        let out = filter?.outputImage
        return out!
    }
    
    func CICircularScreen(center inputCenter:CIVector,width inputWidth:NSNumber,sharpness inputSharpness:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CICircularScreen", parameters: [kCIInputImageKey: backCIImage,
                                                               kCIInputCenterKey : inputCenter,
                                                               kCIInputWidthKey:inputWidth,
                                                               kCIInputSharpnessKey:inputSharpness])
        let out = filter?.outputImage
        return out!
    }
    
    func DotScreen(center inputCenter:CIVector,angle inputAngle:NSNumber,width inputWidth:NSNumber,sharpness inputSharpness:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CIDotScreen", parameters: [kCIInputImageKey: backCIImage,
                                                               kCIInputCenterKey : inputCenter,
                                                               kCIInputAngleKey:inputAngle,
                                                               kCIInputWidthKey:inputWidth,
                                                               kCIInputSharpnessKey:inputSharpness])
        let out = filter?.outputImage
        return out!
    }
    
    func LineScreen(center inputCenter:CIVector,angle inputAngle:NSNumber,width inputWidth:NSNumber,sharpness inputSharpness:NSNumber) -> CIImage {
          let filter = CIFilter(name: "CILineScreen", parameters: [kCIInputImageKey: backCIImage,
                                                                 kCIInputCenterKey : inputCenter,
                                                                 kCIInputAngleKey:inputAngle,
                                                                 kCIInputWidthKey:inputWidth,
                                                                 kCIInputSharpnessKey:inputSharpness])
          let out = filter?.outputImage
          return out!
      }
    
    func Pixellate(center inputCenter:CIVector,scale inputScale:NSNumber) -> CIImage {
          let filter = CIFilter(name: "CIPixellate", parameters: [kCIInputImageKey: backCIImage,
                                                                 kCIInputCenterKey : inputCenter,
                                                                 kCIInputScaleKey:inputScale])
          let out = filter?.outputImage
          return out!
      }
    
    func LineOverlay(NRNoiseLevel inputNRNoiseLevel:NSNumber,NRSharpness inputNRSharpness:NSNumber, EdgeIntensity inputEdgeIntensity:NSNumber,Threshold inputThreshold:NSNumber,Contrast inputContrast:NSNumber) -> CIImage {
          let filter = CIFilter(name: "CILineOverlay", parameters: [kCIInputImageKey: backCIImage,
                                                                 "inputNRNoiseLevel" : inputNRNoiseLevel,
                                                                 "inputNRSharpness" : inputNRSharpness,
                                                                 "inputEdgeIntensity" : inputEdgeIntensity,
                                                                 "inputThreshold" : inputThreshold,
                                                                 "inputContrast" : inputContrast])
          let out = filter?.outputImage
          return out!
      }
    
    func HexagonalPixellate(center inputCenter:CIVector,scale inputScale:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CIPixellate", parameters: [kCIInputImageKey: backCIImage,
                                                               kCIInputCenterKey : inputCenter,
                                                               kCIInputScaleKey:inputScale])
        let out = filter?.outputImage
        return out!
    }
    
    func CIGloom(Radius inputRadius:NSNumber,Intensity inputIntensity:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CIGloom", parameters: [kCIInputImageKey: backCIImage,
                                                               kCIInputRadiusKey : inputRadius,
                                                               kCIInputIntensityKey:inputIntensity])
        let out = filter?.outputImage
        return out!
    }
    
    func CIEdgeWork(Radius inputRadius:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CIEdgeWork", parameters: [kCIInputImageKey: backCIImage,
                                                               kCIInputRadiusKey : inputRadius])
        let out = filter?.outputImage
        return out!
    }
    
    func CIEdges(Intensity inputIntensity:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CIEdges", parameters: [kCIInputImageKey: backCIImage,
                                                               kCIInputIntensityKey:inputIntensity])
        let out = filter?.outputImage
        return out!
    }
    
    func CICrystallize(center inputCenter:CIVector,radius inputRadius:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CICrystallize", parameters: [kCIInputImageKey: backCIImage,
                                                               kCIInputCenterKey : inputCenter,
                                                               kCIInputRadiusKey:inputRadius])
        let out = filter?.outputImage
        return out!
    }
    
    func CIComicEffect() -> CIImage {
        let filter = CIFilter(name: "CIComicEffect", parameters: [kCIInputImageKey: backCIImage])
        let out = filter?.outputImage
        return out!
    }

    func CIPointillize(center inputCenter:CIVector,radius inputRadius:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CIPointillize", parameters: [kCIInputImageKey: backCIImage,
        kCIInputCenterKey : inputCenter,
        kCIInputRadiusKey:inputRadius])
        let out = filter?.outputImage
        return out!
    }
    
    func CIEightfoldReflectedTile(center inputCenter:CIVector,Angle inputAngle:NSNumber,Width inputWidth:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CIEightfoldReflectedTile",  parameters: [kCIInputImageKey: backCIImage,
                                                                        kCIInputCenterKey : inputCenter,
                                                                        kCIInputAngleKey:inputAngle,
                                                                        kCIInputWidthKey:inputWidth])
        let out = filter?.outputImage
        return out!
    }
    
    func CIFourfoldReflectedTile(center inputCenter:CIVector,Angle inputAngle:NSNumber,AcuteAngle inputAcuteAngle:NSNumber,Width inputWidth:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CIFourfoldReflectedTile",  parameters: [kCIInputImageKey: backCIImage,
                                                                        kCIInputCenterKey : inputCenter,
                                                                        kCIInputAngleKey:inputAngle,
                                                                        "inputAcuteAngle":inputAcuteAngle,
                                                                        kCIInputWidthKey:inputWidth])
        let out = filter?.outputImage
        return out!
    }
    
    func CIFourfoldRotatedTile(center inputCenter:CIVector,Angle inputAngle:NSNumber,Width inputWidth:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CIFourfoldRotatedTile",  parameters: [kCIInputImageKey: backCIImage,
                                                                        kCIInputCenterKey : inputCenter,
                                                                        kCIInputAngleKey:inputAngle,
                                                                        kCIInputWidthKey:inputWidth])
        let out = filter?.outputImage
        return out!
    }
    
    func CIFourfoldTranslatedTile(center inputCenter:CIVector,Angle inputAngle:NSNumber,AcuteAngle inputAcuteAngle:NSNumber,Width inputWidth:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CIFourfoldTranslatedTile",  parameters: [kCIInputImageKey: backCIImage,
                                                                        kCIInputCenterKey : inputCenter,
                                                                        kCIInputAngleKey:inputAngle,
                                                                        "inputAcuteAngle":inputAcuteAngle,
                                                                        kCIInputWidthKey:inputWidth])
        let out = filter?.outputImage
        return out!
    }
    
    func CIGlideReflectedTile(center inputCenter:CIVector,Angle inputAngle:NSNumber,Width inputWidth:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CIGlideReflectedTile",  parameters: [kCIInputImageKey: backCIImage,
                                                                        kCIInputCenterKey : inputCenter,
                                                                        kCIInputAngleKey:inputAngle,
                                                                        kCIInputWidthKey:inputWidth])
        let out = filter?.outputImage
        return out!
    }
    
    func CIOpTile(center inputCenter:CIVector,Scale inputScale:NSNumber,Angle inputAngle:NSNumber,Width inputWidth:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CIOpTile",  parameters: [kCIInputImageKey: backCIImage,
                                                                        kCIInputCenterKey : inputCenter,
                                                                        kCIInputScaleKey:inputScale,
                                                                        kCIInputAngleKey:inputAngle,
                                                                        kCIInputWidthKey:inputWidth])
        let out = filter?.outputImage
        return out!
    }
    
    func CIParallelogramTile(center inputCenter:CIVector,Angle inputAngle:NSNumber,AcuteAngle inputAcuteAngle:NSNumber,Width inputWidth:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CIParallelogramTile",  parameters: [kCIInputImageKey: backCIImage,
                                                                        kCIInputCenterKey : inputCenter,
                                                                        kCIInputAngleKey:inputAngle,
                                                                        "inputAcuteAngle":inputAcuteAngle,
                                                                        kCIInputWidthKey:inputWidth])
        let out = filter?.outputImage
        return out!
    }
    
    func CIPerspectiveTile(TopLeft inputTopLeft:CIVector,TopRight inputTopRight:CIVector,BottomRight inputBottomRight:CIVector,BottomLeft inputBottomLeft:CIVector) -> CIImage {
        let filter = CIFilter(name: "CIPerspectiveTile",  parameters: ["inputTopLeft": inputTopLeft,
                                                                       "inputTopRight": inputTopRight,
                                                                      "inputBottomRight": inputBottomRight,
                                                                       "inputBottomLeft": inputBottomLeft])
        let out = filter?.outputImage
        return out!
    }
    
    func CISixfoldReflectedTile(center inputCenter:CIVector,Angle inputAngle:NSNumber,Width inputWidth:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CISixfoldReflectedTile",  parameters: [kCIInputImageKey: backCIImage,
                                                                        kCIInputCenterKey : inputCenter,
                                                                        kCIInputAngleKey:inputAngle,
                                                                        kCIInputWidthKey:inputWidth])
        let out = filter?.outputImage
        return out!
    }
    
    func CISixfoldRotatedTile(center inputCenter:CIVector,Angle inputAngle:NSNumber,Width inputWidth:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CISixfoldRotatedTile",  parameters: [kCIInputImageKey: backCIImage,
                                                                        kCIInputCenterKey : inputCenter,
                                                                        kCIInputAngleKey:inputAngle,
                                                                        kCIInputWidthKey:inputWidth])
        let out = filter?.outputImage
        return out!
    }
    
    func CITriangleKaleidoscope(Point inputPoint:CIVector,Size inputSize:NSNumber,Rotation inputRotation:NSNumber,Decay inputDecay:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CITriangleKaleidoscope",  parameters: ["inputPoint": inputPoint,
                                                                       "inputSize": inputSize,
                                                                      "inputRotation": inputRotation,
                                                                       "inputDecay": inputDecay])
        let out = filter?.outputImage
        return out!
    }
    
    func CITriangleTile(center inputCenter:CIVector,Angle inputAngle:NSNumber,Width inputWidth:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CITriangleTile",  parameters: [kCIInputImageKey: backCIImage,
                                                                        kCIInputCenterKey : inputCenter,
                                                                        kCIInputAngleKey:inputAngle,
                                                                        kCIInputWidthKey:inputWidth])
        let out = filter?.outputImage
        return out!
    }
    
    func CITwelvefoldReflectedTile(center inputCenter:CIVector,Angle inputAngle:NSNumber,Width inputWidth:NSNumber) -> CIImage {
        let filter = CIFilter(name: "CITwelvefoldReflectedTile",  parameters: [kCIInputImageKey: backCIImage,
                                                                        kCIInputCenterKey : inputCenter,
                                                                        kCIInputAngleKey:inputAngle,
                                                                        kCIInputWidthKey:inputWidth])
        let out = filter?.outputImage
        return out!
    }
    
    func pencil() -> CIImage{
         let grayFilter = CIFilter(name: "CIPhotoEffectNoir", parameters: [kCIInputImageKey : backCIImage!])
                   let gray = grayFilter?.outputImage
                   
                   let invertFilter =  CIFilter(name: "CIColorInvert", parameters: [kCIInputImageKey : gray!])
                   let invert = invertFilter?.outputImage
                   
                   let gausianBlur = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputImageKey : invert!,
                                                                                   kCIInputRadiusKey:10.0])
                   let blur = gausianBlur?.outputImage
                   
                   let blurInvertFilter = CIFilter(name: "CIColorInvert", parameters: [kCIInputImageKey : blur!])
                   let blurInvert = blurInvertFilter?.outputImage
                   
                   let dividFilter = CIFilter(name: "CIDivideBlendMode", parameters: [kCIInputImageKey : blurInvert!,
                                                                                      kCIInputBackgroundImageKey:gray!])
                   let divid = dividFilter?.outputImage
        return divid!
    }
    
    func pencilBlur() -> CIImage {
        let penciled = pencil()
        let edge = CIFilter(name: "CIEdges", parameters: [kCIInputImageKey : backCIImage!,
            kCIInputIntensityKey:1.0])?.outputImage!
        let gausianBlur = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputImageKey : backCIImage!,
            kCIInputRadiusKey:20.0])?.outputImage!
        let comp = CIFilter(name: "CIBlendWithMask", parameters: [kCIInputImageKey :gausianBlur,
        kCIInputBackgroundImageKey:edge,
            "inputMaskImage":penciled])?.outputImage
        return comp!
    }
    
    func lemon() -> CIImage {
        let lemoned = CIFilter(name: "CIFalseColor", parameters: [kCIInputImageKey : backCIImage!,
        "inputColor0":CIColor.blue,
        "inputColor1":CIColor.yellow])?.outputImage
        return lemoned!
    }
    
    func red() -> CIImage {
        let lemoned = CIFilter(name: "CIFalseColor", parameters: [kCIInputImageKey : backCIImage!,
        "inputColor0":CIColor.red,
        "inputColor1":CIColor.white])?.outputImage
        return lemoned!
    }
    
    func pink() -> CIImage {
        let lemoned = CIFilter(name: "CIFalseColor", parameters: [kCIInputImageKey : backCIImage!,
        "inputColor0":CIColor.magenta,
        "inputColor1":CIColor.white])?.outputImage
        return lemoned!
    }
    
    func nega() -> CIImage {
       let invert =  CIFilter(name: "CIColorInvert", parameters: [kCIInputImageKey : backCIImage])?.outputImage
        return invert!
    }
    
    func Posterize() -> CIImage {
        let posterize =  CIFilter(name: "CIColorPosterize", parameters: [kCIInputImageKey : backCIImage,
        "inputLevels":6])?.outputImage
        return posterize!

    }
    
    func blue() -> CIImage {
        let colored =  CIFilter(name: "CIWhitePointAdjust", parameters: [kCIInputImageKey : backCIImage!,
        "inputColor":CIColor.blue])?.outputImage
        return colored!
    }
    
    func green() -> CIImage {
        let colored =  CIFilter(name: "CIWhitePointAdjust", parameters: [kCIInputImageKey : backCIImage!,
        "inputColor":CIColor.green])?.outputImage
        return colored!
    }
    
    func pink2() -> CIImage {
        let colored =  CIFilter(name: "CIWhitePointAdjust", parameters: [kCIInputImageKey : backCIImage!,
                                                                         "inputColor":CIColor.magenta])?.outputImage
        return colored!
    }
     
    func mozaic()-> CIImage{
        let originalSize = backCIImage?.extent.size
        let uiimage = UIImage(ciImage: backCIImage!)
        let resized = uiimage.resize(size: CGSize(width: 32, height: 32))
        let rescaled = resized?.resize(size: originalSize!)
        let rescaledCIImage = CIImage(image: rescaled!)
        return rescaledCIImage!
    }
}

import UIKit
extension UIImage {
func resize(size _size: CGSize) -> UIImage? {
    let widthRatio = _size.width / size.width
    let heightRatio = _size.height / size.height
    let ratio = widthRatio < heightRatio ? widthRatio : heightRatio

    let resizedSize = CGSize(width: size.width * ratio, height: size.height * ratio)

    UIGraphicsBeginImageContext(resizedSize)
    draw(in: CGRect(origin: .zero, size: resizedSize))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return resizedImage
}
}
