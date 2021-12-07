//
//  EditViewController.swift
//  SegmentCamera
//
//  Created by 間嶋大輔 on 2020/03/03.
//  Copyright © 2020 daisuke. All rights reserved.
//

import UIKit
import Accelerate
import Photos


class EditViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIGestureRecognizerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        PreviewView.contentMode = .scaleAspectFit
        view.addSubview(PreviewView)
        let originalUIImage = UIImage(ciImage: OriginalImage)
        PreviewView.image = originalUIImage
        buttonAdding()
        buttonSetting()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isCamera! {
            maskImage = PortraitMatteImage!.resizeToSameSize(as: OriginalImage)
        } else {
            maskImage = PortraitMatteImage
        }
    }
    
    var isCamera:Bool?
    
    var PreviewView = UIImageView()
    
    var personView = UIImageView()
    
    var OriginalImage = CIImage()
    var PortraitMatteImage:CIImage?
    var HairMatteImage = CIImage()
    var SkinMatteImage = CIImage()
    var TeethMatteImage = CIImage()
    var maskImage:CIImage?
    
    var editedImage:CIImage?
    
    var backCIImage:CIImage?
    
    var blurCount = 0
    
    var AlphaButton = UIImageView()
    var BlurButton = UIImageView()
    var BlurLabel = UILabel()
    
    var ColorButton = UIImageView()
    var ColorLabel = UILabel()
    
    var backgroundView = UIView()
    var AlphaLabel = UILabel()
    
    var FiltersButton = UIImageView()
    var FilterLabel = UILabel()
    
    
    var currentOrientation:UIDeviceOrientation?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let orientation = UIDevice.current.orientation
        if orientation != currentOrientation {
            switch orientation {
            case .portrait:
                currentOrientation = .portrait
            case .landscapeLeft:
                currentOrientation = .landscapeLeft
            case .landscapeRight:
                currentOrientation = .landscapeRight
            default:
                currentOrientation = .portrait
            }
            buttonSetting()
        }
    }
    
    @IBAction func Undo(_ sender: UIBarButtonItem) {
        editedImage = OriginalImage
        PreviewView.frame = view.bounds
        PreviewView.image = UIImage(ciImage: OriginalImage)
        personView.removeFromSuperview()
        backCIImage = OriginalImage
        blurCount = 0
        BlurLabel.text = NSLocalizedString("Blur", comment: "")
        saveCase = .blur
        filterNumber = 0
        FilterLabel.text = "Filters"
    }
    
    var personImage:CIImage?
    private var spinner: UIActivityIndicatorView!

    @IBAction func Save(_ sender: UIBarButtonItem) {
        DispatchQueue.main.async {
            self.spinner = UIActivityIndicatorView(style: .large)
            self.spinner.color = UIColor.yellow
            self.view.addSubview(self.spinner)
            self.view.isUserInteractionEnabled = false
        }
        let context = CIContext()
        let cgImage = context.createCGImage(editedImage!, from: editedImage!.extent)
        let uiimage = UIImage(cgImage: cgImage!)
        var data:Data?
        
        switch saveCase {
        case .blur:
            data = uiimage.jpegData(compressionQuality: 1)
            savedNotice(uiimage)
        case .image:
            if view.bounds.width < view.bounds.height {
                let backSize = backCIImage?.extent
                let sameSizeAlphaImage = personImage!.adjustSameWidth(as: backCIImage!)
                var transX = CGFloat.zero
                var transY = CGFloat.zero
                transX = personView.frame.minX / PreviewView.frame.width
                transY = (PreviewView.bounds.height - personView.frame.maxY) / PreviewView.frame.height
                let transWidth = (personView.frame.width / PreviewView.frame.width)
                
                
                let transform = CGAffineTransform(scaleX: transWidth, y: transWidth)
                let scaledAlpha = sameSizeAlphaImage.transformed(by: transform)
                let translate = CGAffineTransform(translationX: transX * backSize!.width, y: transY * backSize!.height)
                let translatedAlpha = scaledAlpha.transformed(by: translate)
                let fil = CIFilter(name: "CISourceOverCompositing", parameters: ["inputImage" : translatedAlpha,
                                                                                 "inputBackgroundImage":backCIImage!])
                let composited = fil?.outputImage
                let ui = UIImage(ciImage: composited!)
                data = ui.jpegData(compressionQuality: 1)
                savedNotice(ui)
            } else {
                let backSize = backCIImage?.extent
                let sameSizeAlphaImage = personImage!.adjustSameHeight(as: backCIImage!)
                var transX = CGFloat.zero
                var transY = CGFloat.zero
                transX = personView.frame.minX / PreviewView.frame.width
                transY = (PreviewView.bounds.height - personView.frame.maxY) / PreviewView.frame.height
                let transHeight = (personView.frame.height / PreviewView.frame.height)
                let transform = CGAffineTransform(scaleX: transHeight, y: transHeight)
                let scaledAlpha = sameSizeAlphaImage.transformed(by: transform)
                let translate = CGAffineTransform(translationX: transX * backSize!.width, y: transY * backSize!.height)
                let translatedAlpha = scaledAlpha.transformed(by: translate)
                let fil = CIFilter(name: "CISourceOverCompositing", parameters: ["inputImage" : translatedAlpha,
                                                                                 "inputBackgroundImage":backCIImage!])
                let composited = fil?.outputImage
                let ui = UIImage(ciImage: composited!)
                data = ui.jpegData(compressionQuality: 1)
                savedNotice(ui)
            }
        case .imageAndFilter:
            if view.bounds.width < view.bounds.height {
                           let backSize = filteredBack.extent
                           let sameSizeAlphaImage = personImage!.adjustSameWidth(as: filteredBack)
                           var transX = CGFloat.zero
                           var transY = CGFloat.zero
                           transX = personView.frame.minX / PreviewView.frame.width
                           transY = (PreviewView.bounds.height - personView.frame.maxY) / PreviewView.frame.height
                           let transWidth = (personView.frame.width / PreviewView.frame.width)
                           
                           
                           let transform = CGAffineTransform(scaleX: transWidth, y: transWidth)
                           let scaledAlpha = sameSizeAlphaImage.transformed(by: transform)
                           let translate = CGAffineTransform(translationX: transX * backSize.width, y: transY * backSize.height)
                           let translatedAlpha = scaledAlpha.transformed(by: translate)
                           let fil = CIFilter(name: "CISourceOverCompositing", parameters: ["inputImage" : translatedAlpha,
                                                                                            "inputBackgroundImage":filteredBack])
                           let composited = fil?.outputImage
                           let ui = UIImage(ciImage: composited!)
                           data = ui.jpegData(compressionQuality: 1)
                           savedNotice(ui)
                       } else {
                           let backSize = filteredBack.extent
                           let sameSizeAlphaImage = personImage!.adjustSameHeight(as: filteredBack)
                           var transX = CGFloat.zero
                           var transY = CGFloat.zero
                           transX = personView.frame.minX / PreviewView.frame.width
                           transY = (PreviewView.bounds.height - personView.frame.maxY) / PreviewView.frame.height
                           let transHeight = (personView.frame.height / PreviewView.frame.height)
                           let transform = CGAffineTransform(scaleX: transHeight, y: transHeight)
                           let scaledAlpha = sameSizeAlphaImage.transformed(by: transform)
                           let translate = CGAffineTransform(translationX: transX * backSize.width, y: transY * backSize.height)
                           let translatedAlpha = scaledAlpha.transformed(by: translate)
                           let fil = CIFilter(name: "CISourceOverCompositing", parameters: ["inputImage" : translatedAlpha,
                                                                                            "inputBackgroundImage":filteredBack])
                           let composited = fil?.outputImage
                           let ui = UIImage(ciImage: composited!)
                           data = ui.jpegData(compressionQuality: 1)
                           savedNotice(ui)
                       }
        default:
            data = uiimage.pngData()
            savedNotice(uiimage)
        }
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    //                                          options.uniformTypeIdentifier = self.requestedPhotoSettings.processedFileType.map { $0.rawValue }
                    creationRequest.addResource(with: .photo, data: data!, options: options)
                }, completionHandler: { _, error in
                    if let error = error {
                        print("Error occurred while saving photo to photo library: \(error)")
                    }
                    DispatchQueue.main.async {
                    self.spinner.hidesWhenStopped = true
                        self.view.isUserInteractionEnabled = true
                    }

                }
                )
            } else {
                DispatchQueue.main.async {
                self.presentAlert("Please set photo library authorization in settings.")
                }
            }
        }
    }
    func presentAlert(_ title: String) {
        // Always present alert on main thread.
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title,
                                                    message: "",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK",
                                         style: .default)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    func savedNotice(_ edited:UIImage) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let noticeView: SavingNoticeViewController = storyBoard.instantiateViewController(withIdentifier: "notice") as! SavingNoticeViewController
        noticeView.editedImage = edited
        noticeView.originalImage = UIImage(ciImage: OriginalImage)
        noticeView.modalPresentationStyle = .overFullScreen
        noticeView.modalTransitionStyle = .crossDissolve
        
        self.present(noticeView, animated: false, completion: nil)
    }
    
    @objc func blur(){
        if saveCase == .image || saveCase == .imageAndFilter {
            BlurLabel.text = "\(blurCount + 1)"
            prepareBlur()
        } else {
            saveCase = .blur
            BlurLabel.text = "\(blurCount + 1)"
            prepareBlur()
        }
    }
    
    @objc func alpha(){
        saveCase = .alpha
        let alphaImage = OriginalImage.settingAlphaOne(in: CGRect.zero)
        let filter = CIFilter(name: "CIBlendWithMask", parameters: [
            kCIInputImageKey: OriginalImage,
            kCIInputBackgroundImageKey:alphaImage,
            kCIInputMaskImageKey:maskImage])
        editedImage = filter?.outputImage
        PreviewView.image = UIImage(ciImage: editedImage!)
        personView.removeFromSuperview()
    }
    
    
    @objc func Image(){
        blurCount = 0
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.image"]
        picker.allowsEditing = true
        self.present(picker, animated: true)
    }
    
    var filteredBack = CIImage()
    
    var filterNumber = 0
    
    @objc func Filters(){
        if saveCase == .alpha {return}
        if saveCase == .image {saveCase = .imageAndFilter}
        if backCIImage == nil, saveCase == .blur {
            backCIImage = OriginalImage
        }
        
        switch filterNumber {
        case 0:
            filteredBack = zoomBlur(center:CIVector(cgPoint: CGPoint(x:150, y:150)), amount:NSNumber(value: 20))
            FilterLabel.text = "zoom"
           
          
            
        case 1:
           filteredBack = bumpDistortion(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)),
                                              radius: NSNumber(value: Int((OriginalImage.extent.width))), scale: 3.0)
            FilterLabel.text = "bump"
           
        case 2:
             filteredBack = circleSplashDistortion(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)),
                                                      radius: NSNumber(value: 50))
            FilterLabel.text = "splash"
           
        case 3:
           filteredBack = circularWrap(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)),
                                            radius: NSNumber(value: 50),
                                            angle: NSNumber(value: 0))
            FilterLabel.text = "circular"
            
        case 4:
            filteredBack = Droste(inset0:  CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5 - 50,y:OriginalImage.extent.height * 0.5 - 10)), inset1: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5 + 10,y:OriginalImage.extent.height * 0.5 + 50)), strands: 3, periodicity: 10, rotation: 0, zoom: 2)
            FilterLabel.text = "droste"
            
        case 5:
            filteredBack = LightTunnel(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)), rotation:20, radius:20 )
            FilterLabel.text = "Tunnel"
            
        case 6:
             filteredBack = CICircularScreen(center:CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)),width:6,sharpness :0.7)
            FilterLabel.text = "Cular"
           
        case 7:
            filteredBack = DotScreen(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)), angle: 0,width: 6,sharpness: 0.7)
            FilterLabel.text = "Dot"
            
        case 8:
             filteredBack = LineScreen(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)),angle: 0,width: 10,sharpness: 0.7)
            FilterLabel.text = "Line"
            
        case 9:
            filteredBack = Pixellate(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)), scale:16 )
            FilterLabel.text = "Pixel"
            
            
        case 10:
           filteredBack = HexagonalPixellate(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)), scale:24)
            FilterLabel.text = "Hexagon"
            
        case 11:
            filteredBack = CIGloom(Radius: 10, Intensity: 1 )
            FilterLabel.text = "Gloom"
            
        case 12:
            filteredBack = CIEdgeWork(Radius: 3)
            FilterLabel.text = "EdgeWork"
            
        case 13:
           filteredBack = CIEdges(Intensity: 1)
            FilterLabel.text = "Edges"
          
        case 14:
            filteredBack = CICrystallize(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)), radius:20 )
            FilterLabel.text = "Crystal"
            
        case 15:
            filteredBack = CIComicEffect()
            FilterLabel.text = "Comic"
            
        case 16:
           filteredBack = CIPointillize(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)), radius:20)
            FilterLabel.text = "Point"
            
        case 17:
            filteredBack = CIEightfoldReflectedTile(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)), Angle: 0,Width: 100)
            FilterLabel.text = "Tile1"
            
        case 18:
           filteredBack = CIOpTile(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)), Scale: 2.80, Angle: 0,Width: 65)
            FilterLabel.text = "Tile6"
            
        case 19:
            filteredBack = CIParallelogramTile(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)), Angle: 0, AcuteAngle: 1.57,Width: 100)
            FilterLabel.text = "Tile7"
            
        case 20:
            filteredBack = LineOverlay(NRNoiseLevel:0.02,NRSharpness:1,EdgeIntensity: 0.1,Threshold: 0.5,Contrast: 50)
            FilterLabel.text = "LineOver"
        case 21:
            filteredBack = pencil()
            FilterLabel.text = "Pencil"
        case 22:
            filteredBack = pencilBlur()
            FilterLabel.text = "anime"
        case 23:
            filteredBack = lemon()
            FilterLabel.text = "lemon"
        case 24:
            filteredBack = red()
            FilterLabel.text = "melody"
        case 25:
            filteredBack = pink()
            FilterLabel.text = "pink"
        case 26:
            filteredBack = nega()
            FilterLabel.text = "nega"
        case 27:
            filteredBack = Posterize()
            FilterLabel.text = "Poster"
        case 28:
            filteredBack = blue()
            FilterLabel.text = "blue"
        case 29:
        filteredBack = green()
        FilterLabel.text = "green"
        case 30:
        filteredBack = pink2()
        FilterLabel.text = "pink2"
        case 31:
        filteredBack = mozaic()
        FilterLabel.text = "mozaic"
        
//        case 18:
//            filteredBack = CIFourfoldReflectedTile(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)), Angle: 0, AcuteAngle: 1.57,Width: 100)
//            FilterLabel.text = "Tile2"
//
//        case 19:
//            filteredBack = CIFourfoldRotatedTile(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)), Angle: 0,Width: 100)
//            FilterLabel.text = "Tile3"
//
//        case 20:
//            filteredBack = CIFourfoldTranslatedTile(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)), Angle: 0, AcuteAngle: 1.57,Width: 100)
//            FilterLabel.text = "Tile4"
//
//        case 21:
//            filteredBack = CIGlideReflectedTile(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)), Angle: 0,Width: 100)
//            FilterLabel.text = "Tile5"
//
//
//        case 24:
//           filteredBack = CISixfoldReflectedTile(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)), Angle: 0, Width: 100)
//            FilterLabel.text = "Tile9"
//
//        case 25:
//            filteredBack = CISixfoldRotatedTile(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)), Angle: 0, Width: 100)
//            FilterLabel.text = "Tile10"
//
//
//        case 26:
//            filteredBack = CITriangleTile(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)), Angle: 0, Width: 100)
//            FilterLabel.text = "Tile12"
//
//        case 27:
//            filteredBack = CITwelvefoldReflectedTile(center: CIVector(cgPoint: CGPoint(x:OriginalImage.extent.width * 0.5,y:OriginalImage.extent.height * 0.5)), Angle: 0, Width: 100)
//            FilterLabel.text = "Tile13"
        
        
//        case 29:
//            filterNumber += 1
            
            //            let filteredBack = CIPerspectiveTile(TopLeft: CIVector(x: 118, y: 484), TopRight: CIVector(x: 646, y: 507), BottomRight: CIVector(x: 548, y: 140), BottomLeft: CIVector(x: 155, y: 153))
            //            FilterLabel.text = "Tile8"
            //            let filter = CIFilter(name: "CIBlendWithMask", parameters: [
            //                kCIInputImageKey: OriginalImage,
            //                kCIInputBackgroundImageKey:filteredBack,
            //                kCIInputMaskImageKey:maskImage])
        //            editedImage = filter?.outputImage?.cropped(to: OriginalImage.extent)
//        case 30:
            //            let filteredBack = CITriangleKaleidoscope(Point: [150, 150], Size: 700, Rotation: -0.36, Decay: 0.85)
            //            FilterLabel.text = "Tile11"
            //            let filter = CIFilter(name: "CIBlendWithMask", parameters: [
            //                kCIInputImageKey: OriginalImage,
            //                kCIInputBackgroundImageKey:filteredBack,
            //                kCIInputMaskImageKey:maskImage])
            //            editedImage = filter?.outputImage?.cropped(to: OriginalImage.extent)
            filterNumber += 1
        default:
            filterNumber = 0
            FilterLabel.text = "Original"
            editedImage = OriginalImage
            PreviewView.image = UIImage(ciImage: OriginalImage)
        }
        
        
        if saveCase == .imageAndFilter {
            filteredBack = filteredBack.cropped(to: backCIImage!.extent)
            PreviewView.image = UIImage(ciImage: filteredBack)
        }else {
        let filter = CIFilter(name: "CIBlendWithMask", parameters: [
                           kCIInputImageKey: OriginalImage,
                           kCIInputBackgroundImageKey:filteredBack,
                           kCIInputMaskImageKey:maskImage])
        editedImage = filter?.outputImage?.cropped(to: OriginalImage.extent)
        PreviewView.image = UIImage(ciImage: editedImage!)
        }
        filterNumber += 1

    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage]  as? UIImage {
            var newImage = UIImage()
            switch pickedImage.imageOrientation.rawValue {
            case 1:
                newImage = imageRotatedByDegrees(oldImage: pickedImage, deg: 180)
            case 3:
                newImage = imageRotatedByDegrees(oldImage: pickedImage, deg: 90)
            default:
                newImage = pickedImage
            }
            
            
            PreviewView.image = newImage
            backCIImage = CIImage(image: newImage)
            saveCase = .image
            if view.bounds.width < view.bounds.height {
                let imageWidth = newImage.size.width
                let imageHeght = newImage.size.height
                let scale = PreviewView.bounds.width / imageWidth
                PreviewView.frame = CGRect(x: 0, y: view.center.y - (imageHeght * scale * 0.5), width: view.bounds.width, height: imageHeght * scale)
            } else {
                let imageWidth = newImage.size.width
                let imageHeght = newImage.size.height
                let scale = PreviewView.bounds.height / imageHeght
                PreviewView.frame = CGRect(x: view.center.x - (imageWidth * scale * 0.5), y: 0, width: imageWidth * scale, height: view.bounds.height)
            }
            
            let alphaImage = OriginalImage.settingAlphaOne(in: CGRect.zero).resizeToSameSize(as: OriginalImage)
            let filter = CIFilter(name: "CIBlendWithMask", parameters: [
                kCIInputImageKey: OriginalImage,
                kCIInputBackgroundImageKey:alphaImage,
                kCIInputMaskImageKey:maskImage])
            
            personImage = filter?.outputImage
            personView.image = UIImage(ciImage: personImage!)
            personView.contentMode = .scaleAspectFit
            
            let pan = UIPanGestureRecognizer(target: self, action: #selector(panPiece(_:)))
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(scalePiece(_:)))
            pan.delegate = self
            pinch.delegate = self
            
            view.addGestureRecognizer(pan)
            view.addGestureRecognizer(pinch)
            personView.isUserInteractionEnabled = true
            PreviewView.isUserInteractionEnabled = true
            PreviewView.addSubview(personView)
            
            if view.bounds.width < view.bounds.height {
                let personWidth = personView.image!.size.width
                let personHeght = personView.image!.size.height
                let personScale = view.bounds.width / personWidth
                personView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: personHeght * personScale)
            } else {
                let personWidth = personView.image!.size.width
                let personHeght = personView.image!.size.height
                let personScale = view.bounds.height / personHeght
                personView.frame = CGRect(x: 0, y: 0, width: personWidth * personScale, height: view.bounds.height)
            }
            picker.dismiss(animated: true, completion: nil)
        }
    }
    @objc func scalePiece(_ gestureRecognizer : UIPinchGestureRecognizer) {
        guard gestureRecognizer.view != nil else { return }
        if saveCase == .image || saveCase == .imageAndFilter{
            if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
                personView.transform = (personView.transform.scaledBy(x: gestureRecognizer.scale, y: gestureRecognizer.scale))
                gestureRecognizer.scale = 1.0
            }
        }
    }
    
    var initialCenter = CGPoint()
    
    @objc func panPiece(_ gestureRecognizer : UIPanGestureRecognizer) {
        guard gestureRecognizer.view != nil else {return}
        if saveCase == .image || saveCase == .imageAndFilter {
            let piece = personView
            let translation = gestureRecognizer.translation(in: piece.superview)
            if gestureRecognizer.state == .began {
                self.initialCenter = piece.center
            }
            if gestureRecognizer.state != .cancelled {
                let newCenter = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
                piece.center = newCenter
            }
            else {
                piece.center = initialCenter
            }
        }
    }
    func imageRotatedByDegrees(oldImage: UIImage, deg degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        if degrees == 90 {
            let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: oldImage.size.height, height: oldImage.size.width))
            let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
            rotatedViewBox.transform = t
            let rotatedSize: CGSize = rotatedViewBox.frame.size
            //Create the bitmap context
            UIGraphicsBeginImageContext(rotatedSize)
            let bitmap: CGContext = UIGraphicsGetCurrentContext()!
            //Move the origin to the middle of the image so we will rotate and scale around the center.
            bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            //Rotate the image context
            bitmap.rotate(by: (degrees * CGFloat.pi / 180))
            //Now, draw the rotated/scaled image into the context
            bitmap.scaleBy(x: 1.0, y: -1.0)
            bitmap.draw(oldImage.cgImage!, in: CGRect(x: -oldImage.size.height / 2, y: -oldImage.size.width / 2, width: oldImage.size.height, height: oldImage.size.width))
            let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return newImage
        } else {
            let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: oldImage.size.width, height: oldImage.size.height))
            let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
            rotatedViewBox.transform = t
            let rotatedSize: CGSize = rotatedViewBox.frame.size
            //Create the bitmap context
            UIGraphicsBeginImageContext(rotatedSize)
            let bitmap: CGContext = UIGraphicsGetCurrentContext()!
            //Move the origin to the middle of the image so we will rotate and scale around the center.
            bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            //Rotate the image context
            bitmap.rotate(by: (degrees * CGFloat.pi / 180))
            //Now, draw the rotated/scaled image into the context
            bitmap.scaleBy(x: 1.0, y: -1.0)
            bitmap.draw(oldImage.cgImage!, in: CGRect(x: -oldImage.size.width / 2, y: -oldImage.size.height / 2, width: oldImage.size.width, height: oldImage.size.height))
            let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return newImage
        }
    }
    
    var saveCase:SaveCase = .blur
    
    enum SaveCase {
        case blur
        case alpha
        case image
        case imageAndFilter
    }
    
    let machToSeconds: Double = {
        var timebase: mach_timebase_info_data_t = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        return Double(timebase.numer) / Double(timebase.denom) * 1e-9
    }()
    
    var format: vImage_CGImageFormat?
    var sourceBuffer: vImage_Buffer?
    lazy var context = CIContext()
    
    func prepareBlur(){
        if backCIImage == nil {
            backCIImage = OriginalImage
        }
        
        let context = CIContext()
        
        guard let originalCGImage = context.createCGImage(backCIImage!, from: backCIImage!.extent) else {
            return
        }
        guard
            let formatLocal = vImage_CGImageFormat(cgImage: originalCGImage) else {
                fatalError("Unable to get color space")
        }
        format = formatLocal
        
        guard
            var sourceImageBuffer = try? vImage_Buffer(cgImage: originalCGImage),
            
            var scaledBuffer = try? vImage_Buffer(width: Int(sourceImageBuffer.width / 4),
                                                  height: Int(sourceImageBuffer.height / 4),
                                                  bitsPerPixel: format!.bitsPerPixel) else {
                                                    fatalError("Can't create source buffer.")
        }
        vImageScale_ARGB8888(&sourceImageBuffer,
                             &scaledBuffer,
                             nil,
                             vImage_Flags(kvImageNoFlags))
        sourceBuffer = scaledBuffer
        
        applyBlur()
    }
    
    let hannWindow: [Float] = {
        return vDSP.window(ofType: Float.self,
                           usingSequence: .hanningDenormalized,
                           count: kernelLength ,
                           isHalfWindow: false)
    }()
    
    lazy var kernel1D: [Int16] = {
        let stride = vDSP_Stride(1)
        var multiplier = pow(Float(Int16.max), 0.25)
        
        let hannWindow1D = vDSP.multiply(multiplier, hannWindow)
        
        return vDSP.floatingPointToInteger(hannWindow1D,
                                           integerType: Int16.self,
                                           rounding: vDSP.RoundingMode.towardNearestInteger)
    }()
    lazy var kernel2D: [Int16] = {
        let stride = vDSP_Stride(1)
        
        var hannWindow2D = [Float](repeating: 0,
                                   count: kernelLength * kernelLength)
        
        cblas_sger(CblasRowMajor,
                   Int32(kernelLength), Int32(kernelLength),
                   1, kernel1D.map { return Float($0) },
                   1, kernel1D.map { return Float($0) },
                   1,
                   &hannWindow2D,
                   Int32(kernelLength))
        
        return vDSP.floatingPointToInteger(hannWindow2D,
                                           integerType: Int16.self,
                                           rounding: vDSP.RoundingMode.towardNearestInteger)
    }()
    var destinationBuffer = vImage_Buffer()
    func applyBlur() {
        do {
            destinationBuffer = try vImage_Buffer(width: Int(sourceBuffer!.width),
                                                  height: Int(sourceBuffer!.height),
                                                  bitsPerPixel: format!.bitsPerPixel)
        } catch {
            return
        }
        
        
        switch blurCount {
        case 0:
            hann2D()
        case 1:
            hann1D()
        case 2:
            box()
        case 3:
            tent()
        case 4:
            box()
        case 5:
            tent()
        default:
            box()
        }
        blurCount += 1
        
        switch saveCase {
        case .blur:
            if let result = try? destinationBuffer.createCGImage(format: format!) {
                backCIImage = CIImage(cgImage: result).resizeToSameSize(as: OriginalImage)
                let filter = CIFilter(name: "CIBlendWithMask", parameters: [
                    kCIInputImageKey: OriginalImage,
                    kCIInputBackgroundImageKey:backCIImage,
                    kCIInputMaskImageKey:maskImage])
                if isCamera! {
                    editedImage = filter?.outputImage
                } else {
                    editedImage = filter?.outputImage?.cropped(to: OriginalImage.extent)
                }
                PreviewView.image = UIImage(ciImage: editedImage!)
            }
        case .image,.imageAndFilter:
            saveCase = .image
            if let result = try? destinationBuffer.createCGImage(format: format!) {
                let ciimage = CIImage(cgImage: result).resizeToSameSize(as: backCIImage!)
                backCIImage = ciimage
                
                PreviewView.image = UIImage(ciImage: backCIImage!)
            }
        default:
            break
        }
        
        
        destinationBuffer.free()
    }
    
    @IBAction func PostButton(_ sender: UIBarButtonItem) {
        postToSNS()
    }
    func postToSNS(){
        if saveCase == .image {
            if view.bounds.width < view.bounds.height {
                let backSize = backCIImage?.extent
                let sameSizeAlphaImage = personImage!.adjustSameWidth(as: backCIImage!)
                var transX = CGFloat.zero
                var transY = CGFloat.zero
                transX = personView.frame.minX / PreviewView.frame.width
                transY = (PreviewView.bounds.height - personView.frame.maxY) / PreviewView.frame.height
                let transWidth = (personView.frame.width / PreviewView.frame.width)
                
                
                let transform = CGAffineTransform(scaleX: transWidth, y: transWidth)
                let scaledAlpha = sameSizeAlphaImage.transformed(by: transform)
                let translate = CGAffineTransform(translationX: transX * backSize!.width, y: transY * backSize!.height)
                let translatedAlpha = scaledAlpha.transformed(by: translate)
                let fil = CIFilter(name: "CISourceOverCompositing", parameters: ["inputImage" : translatedAlpha,
                                                                                 "inputBackgroundImage":backCIImage!])
                editedImage = fil?.outputImage
            } else {
                let backSize = backCIImage?.extent
                let sameSizeAlphaImage = personImage!.adjustSameHeight(as: backCIImage!)
                var transX = CGFloat.zero
                var transY = CGFloat.zero
                transX = personView.frame.minX / PreviewView.frame.width
                transY = (PreviewView.bounds.height - personView.frame.maxY) / PreviewView.frame.height
                let transHeight = (personView.frame.height / PreviewView.frame.height)
                let transform = CGAffineTransform(scaleX: transHeight, y: transHeight)
                let scaledAlpha = sameSizeAlphaImage.transformed(by: transform)
                let translate = CGAffineTransform(translationX: transX * backSize!.width, y: transY * backSize!.height)
                let translatedAlpha = scaledAlpha.transformed(by: translate)
                let fil = CIFilter(name: "CISourceOverCompositing", parameters: ["inputImage" : translatedAlpha,
                                                                                 "inputBackgroundImage":backCIImage!])
                editedImage = fil?.outputImage
            }
        }
        let image = UIImage(ciImage: editedImage!)
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.popoverPresentationController?.sourceRect = self.view.bounds
        activityViewController.popoverPresentationController?.permittedArrowDirections = []
        present(activityViewController,animated: true,completion: nil)
    }
    
    override var shouldAutorotate: Bool {
        get {
            return false
        }
    }
}

let kernelLength = 51

extension CIImage {
    func resizeToSameSize(as anotherImage: CIImage) -> CIImage {
        let size1 = extent.size
        let size2 = anotherImage.extent.size
        let transform = CGAffineTransform(scaleX: size2.width / size1.width, y: size2.height / size1.height)
        return transformed(by: transform)
    }
    
    func adjustSameWidth(as anotherImage: CIImage) -> CIImage {
        let anotherSize = anotherImage.extent
        let originalSize = extent.size
        let originalAspectRatio = Float(originalSize.height) / Float(originalSize.width)
        let destinationHeight = Float(anotherSize.width) * originalAspectRatio
        let transform = CGAffineTransform(scaleX: anotherSize.width / originalSize.width, y: CGFloat(destinationHeight) / originalSize.height)
        return transformed(by: transform)
    }
    
    func adjustSameHeight(as anotherImage: CIImage) -> CIImage {
        let anotherSize = anotherImage.extent
        let originalSize = extent.size
        let originalAspectRatio = Float(originalSize.width) / Float(originalSize.height)
        let destinationWidth = Float(anotherSize.height) * originalAspectRatio
        let transform = CGAffineTransform(scaleX: CGFloat(destinationWidth) / originalSize.width, y: anotherSize.height / originalSize.height)
        return transformed(by: transform)
    }
}


