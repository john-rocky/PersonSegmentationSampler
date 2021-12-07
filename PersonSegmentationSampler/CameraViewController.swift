/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The app's primary view controller that presents the camera interface.
 */

import UIKit
import AVFoundation
import Photos
import Vision
import Accelerate

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate,AVCapturePhotoCaptureDelegate, AVCaptureMetadataOutputObjectsDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    private lazy var segmentationRequest:VNGeneratePersonSegmentationRequest = {
        let request = VNGeneratePersonSegmentationRequest(completionHandler: SegmentationCompletionHandler)
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        return request
    }()

    private var spinner: UIActivityIndicatorView!
    
    var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
    
    // MARK: View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CameraButton.isUserInteractionEnabled = false
        recordButton.isEnabled = false
        recordButton.isEnabled = false
        previewView.session = session
      
        
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
            
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            setupResult = .notAuthorized
        }
        sessionQueue.async {
            self.configureSession()
        }
        DispatchQueue.main.async {
            self.spinner = UIActivityIndicatorView(style: .large)
            self.spinner.color = UIColor.yellow
            self.previewView.addSubview(self.spinner)
        }
    }
    
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:
            exifOrientation = .down
        case UIDeviceOrientation.portrait:
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        buttonAdding()
        buttonSetting()
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session if setup succeeded.
                self.addObservers()
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                
            case .notAuthorized:
                DispatchQueue.main.async {
                    let changePrivacySetting = "AVCam doesn't have permission to use the camera, please change privacy settings"
                    let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                            style: .`default`,
                                                            handler: { _ in
                                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                          options: [:],
                                                                                          completionHandler: nil)
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                
            case .configurationFailed:
                DispatchQueue.main.async {
                    let alertMsg = "Alert message when something goes wrong during capture session configuration"
                    let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                self.removeObservers()
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if previewView != nil {
        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }
            
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
            }
        }
        buttonSetting()
    }
    
    
    @objc func imagePick(){
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.image"]
        self.present(picker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            var newImage = UIImage()
            switch pickedImage.imageOrientation.rawValue {
            case 1:
                newImage = imageRotatedByDegrees(oldImage: pickedImage, deg: 180)
            case 3:
                newImage = imageRotatedByDegrees(oldImage: pickedImage, deg: 90)
            default:
                newImage = pickedImage
            }
            
            if newImage.size.width < newImage.size.height {
                isVertical = true
            } else {
                isVertical = false
                
            }
            originalCIImage = CIImage(image: newImage)
            let handler = VNImageRequestHandler(ciImage: originalCIImage!,options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                try? handler.perform([self.segmentationRequest])
            }
            
            picker.dismiss(animated: true)
            DispatchQueue.main.async {
                self.recordButton.isUserInteractionEnabled = false
                self.HelpButton.isUserInteractionEnabled = false
                self.spinner.hidesWhenStopped = true
                self.spinner.center = CGPoint(x: self.previewView.frame.size.width / 2.0, y: self.previewView.frame.size.height / 2.0)
                self.spinner.startAnimating()
            }
        }
    }
    
    func SegmentationCompletionHandler(request:VNRequest?,error:Error?) {
        let result = request?.results?.first as! VNPixelBufferObservation
        let pixelBuffer = result.pixelBuffer
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer, options: [:])
        var translate = CGAffineTransform()
        var resize = CIImage()
        if  isVertical{
            resize = ciImage.resizeToSameHeight(as: originalCIImage!)
            translate = CGAffineTransform(translationX: -(resize.extent.width - (originalCIImage?.extent.width)!) * 0.5, y: 0)
        } else {
            resize = ciImage.resizeToSameWidth(as: originalCIImage!)
            translate = CGAffineTransform(translationX: 0, y: -(resize.extent.height - (originalCIImage?.extent.height)!) * 0.5)
        }
        let translatedBack =  resize.transformed(by: translate)
        PortraitMatteImage = translatedBack
        DispatchQueue.main.async {
            
        self.spinner.stopAnimating()
        self.recordButton.isUserInteractionEnabled = true
        self.HelpButton.isUserInteractionEnabled = true
            self.isCamera = false
            DispatchQueue.main.async {
                self.recordButton.isUserInteractionEnabled = true
            }
        self.performSegue(withIdentifier: "ShowEdit", sender: nil)

            }
    }
    
    var isVertical = true
    private var isCamera:Bool?
    
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
    // MARK: Session Management
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private let session = AVCaptureSession()
    private var isSessionRunning = false
    private var selectedSemanticSegmentationMatteTypes = [AVSemanticSegmentationMatte.MatteType]()
    
    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    private var setupResult: SessionSetupResult = .success
    
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    
    @IBOutlet private weak var previewView: PreviewView!
    
    // Call this on the session queue.
    /// - Tag: ConfigureSession
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        session.beginConfiguration()
        
        /*
         Do not create an AVCaptureMovieFileOutput when setting up the session because
         Live Photo is not supported when AVCaptureMovieFileOutput is added to the session.
         */
        session.sessionPreset = .photo
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera, if available, otherwise default to a wide angle camera.
            
            if let tripleCameraDevice = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
                defaultVideoDevice = tripleCameraDevice
            } else if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                // If a rear dual camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = dualWideCameraDevice
            } else if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                // If a rear dual camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = dualCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) {
                // If the rear wide angle camera isn't available, default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            } else {
                DispatchQueue.main.async {
                    self.presentAlert("This Device Not Supperted.")
                }
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                DispatchQueue.main.async {
                    self.presentAlert("Set up failed.")
                }
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            
            do {
                try videoDevice.lockForConfiguration()
                videoDevice.unlockForConfiguration()
            } catch {
                print(error)
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    /*
                     Dispatch video streaming to the main queue because AVCaptureVideoPreviewLayer is the backing layer for PreviewView.
                     You can manipulate UIView only on the main thread.
                     Note: As an exception to the above rule, it's not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                     
                     Use the window scene's orientation as the initial video orientation. Subsequent orientation changes are
                     handled by CameraViewController.viewWillTransition(to:with:).
                     */
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if self.windowOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: self.windowOrientation) {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    
                    self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                print("Couldn't add video device input to the session.")
                DispatchQueue.main.async {
                    self.presentAlert("Set up failed.")
                }
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            DispatchQueue.main.async {
                self.presentAlert("Set up failed.")
            }
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Add an audio input device.
        
        // Add the photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isDepthDataDeliveryEnabled = true
            photoOutput.isPortraitEffectsMatteDeliveryEnabled = true
            //            photoOutput.enabledSemanticSegmentationMatteTypes = [.hair,.skin,.teeth]
            //            selectedSemanticSegmentationMatteTypes = photoOutput.availableSemanticSegmentationMatteTypes
            photoOutput.maxPhotoQualityPrioritization = .quality
            depthDataDeliveryMode = .on
            portraitEffectsMatteDeliveryMode = .on
            photoQualityPrioritizationMode = .quality
            
        } else {
            print("Could not add photo output to the session")
            DispatchQueue.main.async {
                self.presentAlert("Set up failed.")
            }
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        session.commitConfiguration()
    }
    
    var metadataOutput = AVCaptureMetadataOutput()
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        print(output.availableMetadataObjectTypes)
        print(metadataObjects.first)
    }
    
    @IBAction private func resumeInterruptedSession(_ resumeButton: UIButton) {
        sessionQueue.async {
            /*
             The session might fail to start running, for example, if a phone or FaceTime call is still
             using audio or video. This failure is communicated by the session posting a
             runtime error notification. To avoid repeatedly failing to start the session,
             only try to restart the session in the error handler if you aren't
             trying to resume the session.
             */
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
            if !self.session.isRunning {
                DispatchQueue.main.async {
                    let message = NSLocalizedString("Unable to resume", comment: "Alert message when unable to resume the session running")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    self.resumeButton.isHidden = true
                }
            }
        }
    }
    
    private enum CaptureMode: Int {
        case photo = 0
        case movie = 1
    }
    
    @IBOutlet private weak var captureModeControl: UISegmentedControl!
    
    /// - Tag: EnableDisableModes
    
    // MARK: Device Configuration
    
    @IBOutlet private weak var cameraUnavailableLabel: UILabel!
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTripleCamera,.builtInDualWideCamera, .builtInDualCamera, .builtInTrueDepthCamera],
                                                                               mediaType: .video, position: .unspecified)
    
    /// - Tag: ChangeCamera
    @objc private func changeCamera() {
        CameraButton.isUserInteractionEnabled = false
        recordButton.isEnabled = false
        recordButton.isEnabled = false
        sessionQueue.async {
            let currentVideoDevice = self.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                if let tripleCameraDevice = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
                    preferredDeviceType = .builtInTripleCamera
                } else if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                    // If a rear dual camera is not available, default to the rear wide angle camera.
                    preferredDeviceType = .builtInDualWideCamera
                } else if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                    // If a rear dual camera is not available, default to the rear wide angle camera.
                    preferredDeviceType = .builtInDualCamera
                } else {
                    print("Default video device is unavailable.")
                    self.setupResult = .configurationFailed
                    self.session.commitConfiguration()
                    return
                }
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInTrueDepthCamera
                
            @unknown default:
                print("Unknown capture position. Defaulting to back, dual-camera.")
                preferredPosition = .back
                preferredDeviceType = .builtInDualWideCamera
            }
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil
            
            // First, seek a device with both the preferred position and device type. Otherwise, seek a device with only the preferred position.
            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                newVideoDevice = device
            } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    self.session.beginConfiguration()
                    
                    // Remove the existing device input first, because AVCaptureSession doesn't support
                    // simultaneous use of the rear and front cameras.
                    self.session.removeInput(self.videoDeviceInput)
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        NotificationCenter.default.removeObserver(self, name: .AVCaptureDeviceSubjectAreaDidChange, object: currentVideoDevice)
                        NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange), name: .AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput.device)
                        
                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        self.session.addInput(self.videoDeviceInput)
                    }
                    
                    /*
                     Set Live Photo capture and depth data delivery if it's supported. When changing cameras, the
                     `livePhotoCaptureEnabled` and `depthDataDeliveryEnabled` properties of the AVCapturePhotoOutput
                     get set to false when a video device is disconnected from the session. After the new video device is
                     added to the session, re-enable them on the AVCapturePhotoOutput, if supported.
                     */
                    self.photoOutput.isDepthDataDeliveryEnabled = true
                    self.photoOutput.isPortraitEffectsMatteDeliveryEnabled = true
                    //                    self.photoOutput.enabledSemanticSegmentationMatteTypes = [.hair,.skin,.teeth]
                    self.photoOutput.maxPhotoQualityPrioritization = .quality
                    
                    self.session.commitConfiguration()
                } catch {
                    print("Error occurred while creating video device input: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.CameraButton.isUserInteractionEnabled = true
                self.recordButton.isEnabled = true
            }
        }
    }
    
    @IBAction private func focusAndExposeTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let devicePoint = previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view))
        focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
        //        touchPoint = gestureRecognizer.location(in: gestureRecognizer.view)
        //        print("\ndiff",(floor(animalPointInView.x - touchPoint.x), floor(animalPointInView.y - touchPoint.y)))
    }
    
    private func focus(with focusMode: AVCaptureDevice.FocusMode,
                       exposureMode: AVCaptureDevice.ExposureMode,
                       at devicePoint: CGPoint,
                       monitorSubjectAreaChange: Bool) {
        
        sessionQueue.async {
            let device = self.videoDeviceInput.device
            do {
                try device.lockForConfiguration()
                
                /*
                 Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                 Call set(Focus/Exposure)Mode() to apply the new point of interest.
                 */
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    // MARK: Capturing Photos
    
    private let photoOutput = AVCapturePhotoOutput()
    
    /// - Tag: CapturePhoto
    private func capturePhoto() {
        /*
         Retrieve the video preview layer's video orientation on the main queue before
         entering the session queue. Do this to ensure that UI elements are accessed on
         the main thread and session configuration is done on the session queue.
         */
        
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        
        sessionQueue.async {
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            var photoSettings = AVCapturePhotoSettings()
            
            // Capture HEIF photos when supported. Enable auto-flash and high-resolution photos.
            if  self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            
            if self.videoDeviceInput.device.isFlashAvailable {
                switch self.flashMode {
                case .off:
                    photoSettings.flashMode = .off
                case .on:
                    photoSettings.flashMode = .on
                }
            }
            
            photoSettings.isHighResolutionPhotoEnabled = true
            if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
            }
            photoSettings.isDepthDataDeliveryEnabled = (self.depthDataDeliveryMode == .on
                && self.photoOutput.isDepthDataDeliveryEnabled)
            
            photoSettings.isPortraitEffectsMatteDeliveryEnabled = (self.portraitEffectsMatteDeliveryMode == .on
                && self.photoOutput.isPortraitEffectsMatteDeliveryEnabled)
            
            if photoSettings.isDepthDataDeliveryEnabled {
                if !self.photoOutput.availableSemanticSegmentationMatteTypes.isEmpty {
                    photoSettings.enabledSemanticSegmentationMatteTypes = self.selectedSemanticSegmentationMatteTypes
                }
            }
            photoSettings.photoQualityPrioritization = self.photoQualityPrioritizationMode
            // The photo output holds a weak reference to the photo capture delegate and stores it in an array to maintain a strong reference.
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    func willCapturePhotoAnimation(){
        DispatchQueue.main.async {
            self.previewView.videoPreviewLayer.opacity = 0
            UIView.animate(withDuration: 0.25) {
                self.previewView.videoPreviewLayer.opacity = 1
            }
        }
    }
    
    func photoProcessingHandler(_ animate:Bool){
        DispatchQueue.main.async {
            if animate {
                self.spinner.hidesWhenStopped = true
                self.spinner.center = CGPoint(x: self.previewView.frame.size.width / 2.0, y: self.previewView.frame.size.height / 2.0)
                self.spinner.startAnimating()
            } else {
                self.spinner.stopAnimating()
            }
        }
    }
    
    private enum DepthDataDeliveryMode {
        case on
        case off
    }
    
    private enum PortraitEffectsMatteDeliveryMode {
        case on
        case off
    }
    
    private enum TimerMode {
        case off
        case three
        case ten
    }
    
    private enum FlashMode {
        case on
        case off
    }
    
    private var flashMode:FlashMode = .off
    
    private var depthDataDeliveryMode: DepthDataDeliveryMode = .on
    
    private var portraitEffectsMatteDeliveryMode: PortraitEffectsMatteDeliveryMode = .on
    
    private var timerMode: TimerMode = .off
    
    @objc func timerSwitch(){
        switch timerMode {
        case .off:
            timerMode = .three
            TimerLabel.text = "3"
            
        case .three :
            timerMode = .ten
            TimerLabel.text = "10"
            
        case .ten:
            timerMode = .off
            TimerLabel.text = ""
            
        }
    }
    
    private var photoQualityPrioritizationMode: AVCapturePhotoOutput.QualityPrioritization = .quality
    
    var photoQualityPrioritizationSegControl: UISegmentedControl!
    
    // MARK: ItemSelectionViewControllerDelegate
    
    let semanticSegmentationTypeItemSelectionIdentifier = "SemanticSegmentationTypes"
    
    private var inProgressLivePhotoCapturesCount = 0
    
    //    @IBOutlet private weak var recordButton: UIButton!
    
    @IBOutlet private weak var resumeButton: UIButton!
    
    
    @objc func recordButtonTap(){
        switch timerMode {
        case .off:
            recordButton.isUserInteractionEnabled = false
            capturePhoto()
            
        case .three:
            recordButton.isUserInteractionEnabled = false
            var countDown = 3
            suggestAnimation("\(countDown)")
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (Timer) in
                countDown -= 1
                if countDown != 0{
                    self.suggestAnimation("\(countDown)")
                }
                if countDown == 0{
                    self.capturePhoto()
                    Timer.invalidate()
                }
            }
        case .ten:
            recordButton.isUserInteractionEnabled = false
            var countDown = 10
            suggestAnimation("\(countDown)")
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (Timer) in
                countDown -= 1
                if countDown != 0{
                    self.suggestAnimation("\(countDown)")
                }
                if countDown == 0{
                    self.capturePhoto()
                    Timer.invalidate()
                }
            }
        }
    }
    
    @objc func toggleFlash(){
        if flashMode == .on {
            flashMode = .off
            FlashButton.image = UIImage(systemName: "bolt.slash")
            
        } else {
            flashMode = .on
            FlashButton.image = UIImage(systemName: "bolt")
        }
    }
    
    // MARK: KVO and Notifications
    
    private var keyValueObservations = [NSKeyValueObservation]()
    /// - Tag: ObserveInterruption
    private func addObservers() {
        let keyValueObservation = session.observe(\.isRunning, options: .new) { _, change in
            guard let isSessionRunning = change.newValue else { return }
            
            DispatchQueue.main.async {
                // Only enable the ability to change camera if the device has more than one camera.
                self.CameraButton.isUserInteractionEnabled = isSessionRunning && self.videoDeviceDiscoverySession.uniqueDevicePositionsCount > 1
                
            }
        }
        keyValueObservations.append(keyValueObservation)
        
        let systemPressureStateObservation = observe(\.videoDeviceInput.device.systemPressureState, options: .new) { _, change in
            guard let systemPressureState = change.newValue else { return }
            self.setRecommendedFrameRateRangeForPressureState(systemPressureState: systemPressureState)
        }
        keyValueObservations.append(systemPressureStateObservation)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(subjectAreaDidChange),
                                               name: .AVCaptureDeviceSubjectAreaDidChange,
                                               object: videoDeviceInput.device)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionRuntimeError),
                                               name: .AVCaptureSessionRuntimeError,
                                               object: session)
        
        /*
         A session can only run when the app is full screen. It will be interrupted
         in a multi-app layout, introduced in iOS 9, see also the documentation of
         AVCaptureSessionInterruptionReason. Add observers to handle these session
         interruptions and show a preview is paused message. See the documentation
         of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
         */
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionWasInterrupted),
                                               name: .AVCaptureSessionWasInterrupted,
                                               object: session)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterruptionEnded),
                                               name: .AVCaptureSessionInterruptionEnded,
                                               object: session)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        
        for keyValueObservation in keyValueObservations {
            keyValueObservation.invalidate()
        }
        keyValueObservations.removeAll()
    }
    
    @objc
    func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }
    
    /// - Tag: HandleRuntimeError
    @objc
    func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        
        print("Capture session runtime error: \(error)")
        // If media services were reset, and the last start succeeded, restart the session.
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                } else {
                    DispatchQueue.main.async {
                        self.resumeButton.isHidden = false
                    }
                }
            }
        } else {
            resumeButton.isHidden = false
        }
    }
    
    /// - Tag: HandleSystemPressure
    private func setRecommendedFrameRateRangeForPressureState(systemPressureState: AVCaptureDevice.SystemPressureState) {
        /*
         The frame rates used here are only for demonstration purposes.
         Your frame rate throttling may be different depending on your app's camera configuration.
         */
        let pressureLevel = systemPressureState.level
        if pressureLevel == .serious || pressureLevel == .critical {
            do {
                try self.videoDeviceInput.device.lockForConfiguration()
                print("WARNING: Reached elevated system pressure level: \(pressureLevel). Throttling frame rate.")
                self.videoDeviceInput.device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 20)
                self.videoDeviceInput.device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 15)
                self.videoDeviceInput.device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        } else if pressureLevel == .shutdown {
            print("Session stopped running due to shutdown system pressure level.")
        }
    }
    
    /// - Tag: HandleInterruption
    @objc
    func sessionWasInterrupted(notification: NSNotification) {
        /*
         In some scenarios you want to enable the user to resume the session.
         For example, if music playback is initiated from Control Center while
         using AVCam, then the user can let AVCam resume
         the session running, which will stop music playback. Note that stopping
         music playback in Control Center will not automatically resume the session.
         Also note that it's not always possible to resume, see `resumeInterruptedSession(_:)`.
         */
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let reasonIntegerValue = userInfoValue.integerValue,
            let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
            
            var showResumeButton = false
            if reason == .audioDeviceInUseByAnotherClient || reason == .videoDeviceInUseByAnotherClient {
                showResumeButton = true
            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                // Fade-in a label to inform the user that the camera is unavailable.
                cameraUnavailableLabel.alpha = 0
                cameraUnavailableLabel.isHidden = false
                UIView.animate(withDuration: 0.25) {
                    self.cameraUnavailableLabel.alpha = 1
                }
            } else if reason == .videoDeviceNotAvailableDueToSystemPressure {
                print("Session stopped running due to shutdown system pressure level.")
            }
            if showResumeButton {
                // Fade-in a button to enable the user to try to resume the session running.
                resumeButton.alpha = 0
                resumeButton.isHidden = false
                UIView.animate(withDuration: 0.25) {
                    self.resumeButton.alpha = 1
                }
            }
        }
    }
    
    @objc
    func sessionInterruptionEnded(notification: NSNotification) {
        print("Capture session interruption ended")
        
        if !resumeButton.isHidden {
            UIView.animate(withDuration: 0.25,
                           animations: {
                            self.resumeButton.alpha = 0
            }, completion: { _ in
                self.resumeButton.isHidden = true
            })
        }
        if !cameraUnavailableLabel.isHidden {
            UIView.animate(withDuration: 0.25,
                           animations: {
                            self.cameraUnavailableLabel.alpha = 0
            }, completion: { _ in
                self.cameraUnavailableLabel.isHidden = true
            }
            )
        }
    }
    
    
    //MARK: - Buttons
    var CameraButton = UIImageView()
    var HelpButton = UIImageView()
    var recordingLabel = UILabel()
    var recordButton = UILabel()
    var recordingAnimationButton = UILabel()
    var soundButton = UIImageView()
    var soundLabel = UILabel()
    var TimerButton = UIImageView()
    var TimerLabel = UILabel()
    var FlashButton = UIImageView()
    var imagePickerButton = UIImageView()
    
    private func buttonSetting() {
        print(view.bounds.width)
        previewView.frame = view.bounds
        if view.bounds.width > view.bounds.height {
            let buttonHeight:CGFloat = view.bounds.width * 0.083
            recordButton.frame = CGRect(x:view.bounds.maxX - (buttonHeight * 1.75) , y: view.center.y - (buttonHeight * 0.5), width: buttonHeight, height: buttonHeight)
            recordingAnimationButton.frame = CGRect(x: buttonHeight * 0.05, y: buttonHeight * 0.05, width: buttonHeight * 0.9, height: buttonHeight * 0.9)
            imagePickerButton.frame = CGRect(x:view.bounds.maxX - (buttonHeight * 1.75)  , y: view.bounds.maxY - (buttonHeight), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            soundButton.frame = CGRect(x: (buttonHeight), y: view.bounds.maxY - buttonHeight, width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            HelpButton.frame =  CGRect(x:  view.bounds.maxX - (buttonHeight * 1.75), y: view.bounds.maxY - (buttonHeight), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            CameraButton.frame = CGRect(x: view.bounds.maxX - (buttonHeight * 1.75) , y: (buttonHeight * 0.5), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            TimerButton.frame = CGRect(x: (buttonHeight), y: buttonHeight * 0.5, width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            TimerLabel.frame = CGRect(x: (buttonHeight) * 1.5, y: buttonHeight * 0.5, width: buttonHeight * 0.5, height: buttonHeight * 0.5)

            HelpButton.frame = CGRect(x: (buttonHeight), y: buttonHeight * 1.5, width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            FlashButton.frame = CGRect(x: (buttonHeight), y: view.bounds.maxY - buttonHeight * 1.0, width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            
            recordButton.layer.cornerRadius = min(recordButton.frame.width, recordButton.frame.height) * 0.5
            recordingAnimationButton.layer.cornerRadius = min(recordingAnimationButton.frame.width, recordingAnimationButton.frame.height) * 0.5
        } else {
            let buttonHeight:CGFloat = view.bounds.height * 0.083
            recordButton.frame = CGRect(x: view.center.x - (buttonHeight * 0.5), y: view.bounds.maxY - (buttonHeight * 1.75), width: buttonHeight, height: buttonHeight)
            recordingAnimationButton.frame = CGRect(x: buttonHeight * 0.05, y: buttonHeight * 0.05, width: buttonHeight * 0.9, height: buttonHeight * 0.9)
            imagePickerButton.frame = CGRect(x: (buttonHeight * 0.5), y: view.bounds.maxY - (buttonHeight * 1.75), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            soundButton.frame = CGRect(x:   (buttonHeight * 0.5), y: (buttonHeight), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            soundLabel.frame = CGRect(x: (buttonHeight * 0.5), y: (buttonHeight * 1.3), width:  buttonHeight * 0.5, height:  buttonHeight * 0.5)
            CameraButton.frame = CGRect(x: view.bounds.maxX - (buttonHeight), y: view.bounds.maxY - (buttonHeight * 1.75), width: buttonHeight * 0.5, height: buttonHeight * 0.5)
            TimerButton.frame = CGRect(x: view.bounds.maxX - (buttonHeight), y: (buttonHeight), width:  buttonHeight * 0.5, height:  buttonHeight * 0.5)
            TimerLabel.frame = CGRect(x:  view.bounds.maxX - (buttonHeight), y: (buttonHeight * 1.5), width:  buttonHeight * 0.5, height:  buttonHeight * 0.5)
            HelpButton.frame = CGRect(x:  view.bounds.maxX - (buttonHeight * 2), y: (buttonHeight), width:  buttonHeight * 0.5, height:  buttonHeight * 0.5)
            FlashButton.frame = CGRect(x: buttonHeight * 0.5, y: (buttonHeight), width:  buttonHeight * 0.5, height:  buttonHeight * 0.5)

        }
        recordButton.layer.cornerRadius = min(recordButton.frame.width, recordButton.frame.height) * 0.5
        recordingAnimationButton.layer.cornerRadius = min(recordingAnimationButton.frame.width, recordingAnimationButton.frame.height) * 0.5
    }
    
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
    
    func suggestAnimation(_ text:String){
        let pinchSuggestLabel = UILabel()
        pinchSuggestLabel.frame = CGRect(x: view.bounds.width - 100, y: view.center.y + 100, width: 100, height: 100)
        
        pinchSuggestLabel.textAlignment = .center
        
        pinchSuggestLabel.adjustsFontSizeToFitWidth = true
        
        pinchSuggestLabel.text = NSLocalizedString(text, comment: "")
        pinchSuggestLabel.textColor = UIColor.white
        pinchSuggestLabel.font = .systemFont(ofSize: 100, weight: .bold)
        view.addSubview(pinchSuggestLabel)
        view.bringSubviewToFront(pinchSuggestLabel)
        
        pinchSuggestLabel.alpha = 0
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.1, delay: 0, options: [], animations: {
            pinchSuggestLabel.alpha = 1
        },completion: { (comp) in
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.75, delay: 0.15, options: [], animations: {
                pinchSuggestLabel.alpha = 0
            },completion: { comp in
                pinchSuggestLabel.removeFromSuperview()
            })
        })
    }
    
    private func buttonAdding(){
        
        CameraButton.image = UIImage(systemName: "arrow.2.circlepath")
        HelpButton.image = UIImage(systemName: "questionmark.circle")
        soundButton.image = UIImage(systemName: "speaker")
        soundLabel.text = NSLocalizedString("Shutter", comment: "")
        TimerButton.image = UIImage(systemName: "clock")
        TimerLabel.text = NSLocalizedString("", comment: "")
        imagePickerButton.image = UIImage(systemName: "photo")
        
        FlashButton.image = UIImage(systemName: "bolt.slash")
        TimerLabel.numberOfLines = 2
        FlashButton.tintColor = UIColor.white
        
        HelpButton.tintColor = UIColor.white
        CameraButton.tintColor = UIColor.white
        imagePickerButton.tintColor = UIColor.white
        TimerButton.tintColor = UIColor.white
        soundButton.tintColor = UIColor.white
        
        TimerLabel.textColor = UIColor.white
        TimerLabel.textAlignment = .center
        TimerLabel.adjustsFontSizeToFitWidth = true
        
        soundLabel.textColor = .white
        soundLabel.textAlignment = .center
        soundLabel.adjustsFontSizeToFitWidth = true
        
        recordingLabel.text = NSLocalizedString("Recording", comment: "")
        recordingLabel.textColor = UIColor.red
        recordingLabel.adjustsFontSizeToFitWidth = true
        
        recordButton.layer.backgroundColor = UIColor.clear.cgColor
        recordButton.layer.borderColor = UIColor.white.cgColor
        recordButton.layer.borderWidth = 4
        recordButton.clipsToBounds = true
        recordButton.layer.cornerRadius = min(recordButton.frame.width, recordButton.frame.height) * 0.5
        recordingAnimationButton.layer.cornerRadius = min(recordingAnimationButton.frame.width, recordingAnimationButton.frame.height) * 0.5
        
        recordingAnimationButton.layer.backgroundColor = UIColor.white.cgColor
        recordingAnimationButton.clipsToBounds = true
        recordingAnimationButton.layer.cornerRadius = min(recordingAnimationButton.frame.width, recordingAnimationButton.frame.height) * 0.5
        recordingAnimationButton.layer.borderWidth = 2
        recordingAnimationButton.layer.borderColor = UIColor.darkGray.cgColor
        
        let symbolConfig = UIImage.SymbolConfiguration(weight: .thin)
        
        CameraButton.preferredSymbolConfiguration = symbolConfig
        CameraButton.contentMode = .scaleAspectFill
        HelpButton.preferredSymbolConfiguration = symbolConfig
        HelpButton.contentMode = .scaleAspectFill
        TimerButton.contentMode = .scaleAspectFill
        TimerButton.preferredSymbolConfiguration = symbolConfig
        soundButton.contentMode = .scaleAspectFill
        soundButton.preferredSymbolConfiguration = symbolConfig
        FlashButton.contentMode = .scaleAspectFill
        FlashButton.preferredSymbolConfiguration = symbolConfig
        imagePickerButton.preferredSymbolConfiguration = symbolConfig
        imagePickerButton.contentMode = .scaleAspectFill
        view.addSubview(FlashButton)
        view.addSubview(CameraButton)
        view.addSubview(HelpButton)
        view.bringSubviewToFront(recordingLabel)
        view.bringSubviewToFront(HelpButton)
        view.bringSubviewToFront(CameraButton)
        view.addSubview(TimerButton)
        view.bringSubviewToFront(TimerButton)
        view.addSubview(TimerLabel)
        view.bringSubviewToFront(TimerLabel)
        view.addSubview(imagePickerButton)
        view.bringSubviewToFront(imagePickerButton)
        
        view.bringSubviewToFront(FlashButton)
        
        view.bringSubviewToFront(soundButton)
        view.addSubview(soundButton)
        view.addSubview(soundLabel)
        view.bringSubviewToFront(soundLabel)
        view.addSubview(recordButton)
        view.bringSubviewToFront(recordButton)
        recordButton.addSubview(recordingAnimationButton)
        recordingLabel.isHidden = true
        
        recordButton.isUserInteractionEnabled = true
        recordingAnimationButton.isUserInteractionEnabled = true
        HelpButton.isUserInteractionEnabled = true
        CameraButton.isUserInteractionEnabled = true
        FlashButton.isUserInteractionEnabled = true
        imagePickerButton.isUserInteractionEnabled = true
        
        TimerButton.isUserInteractionEnabled = true
        TimerLabel.isUserInteractionEnabled = true
        soundButton.isUserInteractionEnabled = true
        soundLabel.isUserInteractionEnabled = true
        let CameraButtonTap = UITapGestureRecognizer(target: self, action: #selector(changeCamera))
        CameraButton.addGestureRecognizer(CameraButtonTap)
        let helpTap = UITapGestureRecognizer(target: self, action: #selector(helpSegue))
        HelpButton.addGestureRecognizer(helpTap)
        let recordTap = UITapGestureRecognizer(target: self, action: #selector(recordButtonTap))
        recordButton.addGestureRecognizer(recordTap)
        let recordTap4Label = UITapGestureRecognizer(target: self, action: #selector(recordButtonTap))
        recordingAnimationButton.addGestureRecognizer(recordTap4Label)
        let soundTapGesture = UITapGestureRecognizer(target: self, action: #selector(sound))
        let soundTapGesture2 = UITapGestureRecognizer(target: self, action: #selector(sound))
        soundButton.addGestureRecognizer(soundTapGesture)
        soundLabel.addGestureRecognizer(soundTapGesture2)
        let flashTap = UITapGestureRecognizer(target: self, action: #selector(toggleFlash))
        FlashButton.addGestureRecognizer(flashTap)
        let timerTap = UITapGestureRecognizer(target: self, action: #selector(timerSwitch))
        TimerButton.addGestureRecognizer(timerTap)
        let pickerTap = UITapGestureRecognizer(target: self, action: #selector(imagePick))
        imagePickerButton.addGestureRecognizer(pickerTap)
        
        guard let path = Bundle.main.path(forResource: "meow", ofType: "mp3") else {
            print("音源ファイルが見つかりません")
            soundButton.removeFromSuperview()
            soundLabel.removeFromSuperview()
            return
        }
        do {
            try audioPlayer = AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
        } catch {
            print("playererror")
            soundButton.isHidden = true
            soundLabel.isHidden = true
        }
    }
    //    MARK: - Movie Rec
    var isRecording = false
    func recordingButtonStyling(){
        let buttonHeight = recordButton.bounds.height
        var time = 0
        if isRecording {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0, options: [], animations: {
                self.recordButton.layer.borderColor = UIColor.white.cgColor
                self.recordButton.alpha = 1
                
                self.recordingAnimationButton.frame = CGRect(x: buttonHeight * 0.25, y: buttonHeight * 0.25, width: buttonHeight * 0.5, height: buttonHeight * 0.5)
                self.recordingAnimationButton.layer.backgroundColor = UIColor.red.cgColor
                self.recordingAnimationButton.clipsToBounds = true
                self.recordingAnimationButton.layer.cornerRadius = min(self.recordingAnimationButton.frame.width, self.recordingAnimationButton.frame.height) * 0.1
                self.recordingAnimationButton.layer.borderColor = UIColor.red.cgColor
                self.recordingAnimationButton.alpha = 1
            }, completion: { comp in
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1.0, delay: 1.0, options: [], animations: {
                    self.recordingLabel.alpha = 0
                    time += 1
                },completion:  { (comp) in
                    UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 1.0, delay: 1.0, options: [], animations: {
                        self.recordingLabel.alpha = 1
                    })
                })
            })
        } else {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0, options: [], animations: {
                self.recordButton.layer.borderColor = UIColor.white.cgColor
                self.recordButton.alpha = 1.0
                
                self.recordingAnimationButton.frame = CGRect(x: buttonHeight * 0.05, y: buttonHeight * 0.05, width: buttonHeight * 0.9, height: buttonHeight * 0.9)
                self.recordingAnimationButton.layer.backgroundColor = UIColor.white.cgColor
                self.recordingAnimationButton.clipsToBounds = true
                self.recordingAnimationButton.layer.cornerRadius = min(self.recordingAnimationButton.frame.width, self.recordingAnimationButton.frame.height) * 0.5
                self.recordingAnimationButton.layer.borderColor = UIColor.darkGray.cgColor
                self.recordingAnimationButton.alpha = 1.0
            }, completion: nil)
        }
    }
    
    @objc private func helpSegue(){
        
        performSegue(withIdentifier: "ShowHelp", sender: nil)
    }
    
    enum SoundMode {
        case shutter
        case silent
        case meow
        case bow
    }
    
    var soundMode:SoundMode = .shutter
    var soundType:String = "shutter"
    var audioPlayer:AVAudioPlayer?
    
    @objc func sound(){
        switch soundMode {
        case .shutter:
            soundLabel.text = "Silent"
            soundMode = .silent
            soundType = "silent"
            
        case .silent:
            soundLabel.text = "Meow"
            soundMode = .meow
            soundType = "audio"
            
            guard let path = Bundle.main.path(forResource: "meow", ofType: "mp3") else {
                print("音源ファイルが見つかりません")
                return
            }
            do {
                try audioPlayer = AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            } catch {
                print("playererror")
            }
        case .meow:
            soundLabel.text = "Bow"
            soundMode = .bow
            soundType = "audio"
            
            guard let path = Bundle.main.path(forResource: "puppy", ofType: "mp3") else {
                print("音源ファイルが見つかりません")
                return
            }
            do {
                try audioPlayer = AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            } catch {
                print("playererror")
            }
        case .bow:
            soundLabel.text = "Shutter"
            soundMode = .shutter
            soundType = "shutter"
            
        }
    }
    private var maxPhotoProcessingTime: CMTime?
    //MARK:- Blur
    
    func shutterSound(){
        switch soundType {
        case "shutter":
            print("")
        case "silent":
            AudioServicesDisposeSystemSoundID(1108)
        case "audio":
            AudioServicesDisposeSystemSoundID(1108)
            self.audioPlayer?.play()
        default:
            break
        }
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    }
    
    /// - Tag: WillCapturePhoto
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        willCapturePhotoAnimation()
        shutterSound()
        
        guard let maxPhotoProcessingTime = maxPhotoProcessingTime else {
            return
        }
        
        // Show a spinner if processing time exceeds one second.
        let oneSecond = CMTime(seconds: 1, preferredTimescale: 1)
        if maxPhotoProcessingTime > oneSecond {
            photoProcessingHandler(true)
        }
    }
    
    lazy var context = CIContext()
    private var semanticSegmentationMatteDataArray = [Data]()
    private var photoData: Data?
    private var portraitEffectsMatteData: Data?
    private(set) var requestedPhotoSettings: AVCapturePhotoSettings?
    
    
    func handleMatteData(_ photo: AVCapturePhoto, ssmType: AVSemanticSegmentationMatte.MatteType) {
        
        // Find the semantic segmentation matte image for the specified type.
        guard var segmentationMatte = photo.semanticSegmentationMatte(for: ssmType) else { return }
        
        // Retrieve the photo orientation and apply it to the matte image.
        if let orientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32,
            let exifOrientation = CGImagePropertyOrientation(rawValue: orientation) {
            // Apply the Exif orientation to the matte image.
            segmentationMatte = segmentationMatte.applyingExifOrientation(exifOrientation)
        }
        
        var imageOption: CIImageOption!
        
        // Switch on the AVSemanticSegmentationMatteType value.
        switch ssmType {
        case .hair:
            imageOption = .auxiliarySemanticSegmentationHairMatte
        case .skin:
            imageOption = .auxiliarySemanticSegmentationSkinMatte
        case .teeth:
            imageOption = .auxiliarySemanticSegmentationTeethMatte
        default:
            print("This semantic segmentation type is not supported!")
            return
        }
        
        guard let perceptualColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return }
        
        // Create a new CIImage from the matte's underlying CVPixelBuffer.
        let ciImage = CIImage( cvImageBuffer: segmentationMatte.mattingImage,
                               options: [imageOption: true,
                                         .colorSpace: perceptualColorSpace])
        
        // Get the HEIF representation of this image.
        guard let imageData = context.heifRepresentation(of: ciImage,
                                                         format: .RGBA8,
                                                         colorSpace: perceptualColorSpace,
                                                         options: [.depthImage: ciImage]) else { return }
        
        // Add the image data to the SSM data array for writing to the photo library.
        semanticSegmentationMatteDataArray.append(imageData)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        DispatchQueue.main.async {
            self.spinner.hidesWhenStopped = true
            self.spinner.center = CGPoint(x: self.previewView.frame.size.width / 2.0, y: self.previewView.frame.size.height / 2.0)
            self.spinner.startAnimating()
        }
    }
    
    /// - Tag: DidFinishProcessingPhoto
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        photoProcessingHandler(false)
        
        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            photoData = photo.fileDataRepresentation()
            originalCIImage = CIImage(data: photoData!)
            let photoOriention = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32
            switch photoOriention {
            case 6:
                originalCIImage = originalCIImage?.oriented(.right)
            case 1:
                break
            case 3:
                originalCIImage = originalCIImage?.oriented(.down)
            default:
                originalCIImage = originalCIImage?.oriented(.right)
            }
        }
        
//        originalCIImage = CIImage(image: newImage)
        let handler = VNImageRequestHandler(ciImage: originalCIImage!,options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([self.segmentationRequest])
        }
        
        
//        // A portrait effects matte gets generated only if AVFoundation detects a face.
//        if var portraitEffectsMatte = photo.portraitEffectsMatte {
//            if let orientation = photo.metadata[ String(kCGImagePropertyOrientation) ] as? UInt32 {
//                portraitEffectsMatte = portraitEffectsMatte.applyingExifOrientation(CGImagePropertyOrientation(rawValue: orientation)!)
//            }
//            let portraitEffectsMattePixelBuffer = portraitEffectsMatte.mattingImage
//            let portraitEffectsMatteImage = CIImage( cvImageBuffer: portraitEffectsMattePixelBuffer, options: [ .auxiliaryPortraitEffectsMatte: true ] )
//
//            guard let perceptualColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
//                portraitEffectsMatteData = nil
//                return
//            }
//            portraitEffectsMatteData = context.heifRepresentation(of: portraitEffectsMatteImage,
//                                                                  format: .RGBA8,
//                                                                  colorSpace: perceptualColorSpace,
//                                                                  options: [.portraitEffectsMatteImage: portraitEffectsMatteImage])
//            PortraitMatteImage = CIImage(data: portraitEffectsMatteData!)
//        } else {
//            portraitEffectsMatteData = nil
//        }
//
//        for semanticSegmentationType in output.enabledSemanticSegmentationMatteTypes {
//            guard var segmentationMatte = photo.semanticSegmentationMatte(for: semanticSegmentationType) else { return }
//
//            // Retrieve the photo orientation and apply it to the matte image.
//            if let orientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32,
//                let exifOrientation = CGImagePropertyOrientation(rawValue: orientation) {
//                // Apply the Exif orientation to the matte image.
//                segmentationMatte = segmentationMatte.applyingExifOrientation(exifOrientation)
//            }
//
//            var imageOption: CIImageOption!
//            guard let perceptualColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return }
//
//            // Switch on the AVSemanticSegmentationMatteType value.
//            switch semanticSegmentationType {
//            case .hair:
//                imageOption = .auxiliarySemanticSegmentationHairMatte
//                let ciImage = CIImage( cvImageBuffer: segmentationMatte.mattingImage,
//                                       options: [imageOption: true,
//                                                 .colorSpace: perceptualColorSpace])
//
//                // Get the HEIF representation of this image.
//                guard let imageData = context.heifRepresentation(of: ciImage,
//                                                                 format: .RGBA8,
//                                                                 colorSpace: perceptualColorSpace,
//                                                                 options: [.depthImage: ciImage]) else { return }
//
//                // Add the image data to the SSM data array for writing to the photo library.
//                semanticSegmentationMatteDataArray.append(imageData)
//                HairMatteImage = CIImage(data: imageData)
//            case .skin:
//                imageOption = .auxiliarySemanticSegmentationSkinMatte
//                let ciImage = CIImage( cvImageBuffer: segmentationMatte.mattingImage,
//                                       options: [imageOption: true,
//                                                 .colorSpace: perceptualColorSpace])
//
//                // Get the HEIF representation of this image.
//                guard let imageData = context.heifRepresentation(of: ciImage,
//                                                                 format: .RGBA8,
//                                                                 colorSpace: perceptualColorSpace,
//                                                                 options: [.depthImage: ciImage]) else { return }
//
//                // Add the image data to the SSM data array for writing to the photo library.
//                semanticSegmentationMatteDataArray.append(imageData)
//                SkinMatteImage = CIImage(data: imageData)
//
//            case .teeth:
//                imageOption = .auxiliarySemanticSegmentationTeethMatte
//                let ciImage = CIImage( cvImageBuffer: segmentationMatte.mattingImage,
//                                       options: [imageOption: true,
//                                                 .colorSpace: perceptualColorSpace])
//
//                // Get the HEIF representation of this image.
//                guard let imageData = context.heifRepresentation(of: ciImage,
//                                                                 format: .RGBA8,
//                                                                 colorSpace: perceptualColorSpace,
//                                                                 options: [.depthImage: ciImage]) else { return }
//
//                // Add the image data to the SSM data array for writing to the photo library.
//                semanticSegmentationMatteDataArray.append(imageData)
//                TeethMatteImage = CIImage(data: imageData)
//
//            default:
//                print("This semantic segmentation type is not supported!")
//                return
//            }
//
//
//            // Create a new CIImage from the matte's underlying CVPixelBuffer.
//
//        }
        
        
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowEdit" {
            if let evc = segue.destination as? EditViewController {
                if originalCIImage != nil {
                    evc.OriginalImage = originalCIImage!
                    evc.editedImage = originalCIImage!
                }
                if PortraitMatteImage != nil {
                    evc.PortraitMatteImage = PortraitMatteImage!
                }
                if HairMatteImage != nil {
                    evc.HairMatteImage = HairMatteImage!
                }
                if SkinMatteImage != nil {
                    evc.SkinMatteImage = SkinMatteImage!
                }
                if TeethMatteImage != nil {
                    evc.TeethMatteImage = TeethMatteImage!
                }
                evc.isCamera = self.isCamera
                
                originalCIImage = nil
                PortraitMatteImage = nil
                HairMatteImage = nil
                SkinMatteImage = nil
                TeethMatteImage = nil
            }
        }
    }
    
    var originalCIImage:CIImage?
    var PortraitMatteImage:CIImage?
    var HairMatteImage:CIImage?
    var SkinMatteImage:CIImage?
    var TeethMatteImage:CIImage?
    
    /// - Tag: DidFinishCapture
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        
        guard let photoData = photoData else {
            print("No photo data resource")
            return
        }
        
//        DispatchQueue.main.async {
//            self.recordButton.isUserInteractionEnabled = true
//        }
        
//        if self.PortraitMatteImage != nil{
//            DispatchQueue.main.async {
//                self.spinner.stopAnimating()
//                self.isCamera = true
//                self.performSegue(withIdentifier: "ShowEdit", sender: nil)
//            }
//        } else {
//            self.presentAlert("No people found")
//        }
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    options.uniformTypeIdentifier = self.requestedPhotoSettings?.processedFileType.map { $0.rawValue }
                    creationRequest.addResource(with: .photo, data: photoData, options: options)
                }, completionHandler: { _, error in
                    if let error = error {
                        print("Error occurred while saving photo to photo library: \(error)")
                    }
                }
                )
            } else {
                self.presentAlert("photo saving failed.")
            }
        }
    }
}

extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }
    
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}


extension AVCaptureDevice.DiscoverySession {
    var uniqueDevicePositionsCount: Int {
        
        var uniqueDevicePositions = [AVCaptureDevice.Position]()
        
        for device in devices where !uniqueDevicePositions.contains(device.position) {
            uniqueDevicePositions.append(device.position)
        }
        
        return uniqueDevicePositions.count
    }
}
