//
//  ViewController.swift
//  LiveCamera
//
//  Created by Phil Wright on 12/8/15.
//  Copyright © 2015 Touchopia, LLC. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var capturedImage: UIImageView!
    
    var captureSession: AVCaptureSession = AVCaptureSession()
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var prevZoomFactor: CGFloat = 1
    var backCamera: AVCaptureDevice?
    
    //MARK: - View Life Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(ViewController.pinch(sender:)))
        self.previewView.addGestureRecognizer(pinchRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        self.backCamera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        var error : NSError?
        var input: AVCaptureDeviceInput?
        
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
            
        } catch let e as NSError {
            input = nil
            error = e
            
            print("An error occurred \(error)")
        }
        
        if error == nil && captureSession.canAddInput(input) {
            captureSession.addInput(input)
            
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            
            if captureSession.canAddOutput(stillImageOutput) {
                captureSession.addOutput(stillImageOutput)
                
                if let layer = AVCaptureVideoPreviewLayer(session: captureSession) {
                    
                    layer.videoGravity = AVLayerVideoGravityResizeAspect
                    
                    layer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                    
                    previewView.layer.addSublayer(layer)
                    
                    previewLayer = layer
                }
                
                captureSession.startRunning()
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        if let layer = previewLayer {
            layer.frame = previewView.bounds
        } else {
            print("No Layer Created")
        }
    }
    
    func pinch(sender: UIPinchGestureRecognizer) {
        
        var zoomFactor = sender.scale * prevZoomFactor
        
        if sender.state == .ended {
            prevZoomFactor = zoomFactor >= 1 ? zoomFactor : 1
        }
        
        if let backCamera = self.backCamera {
            defer { backCamera.unlockForConfiguration() }
            
            do {
                try backCamera.lockForConfiguration()
                
                let maxZoomFactor = backCamera.activeFormat.videoMaxZoomFactor
                
                if (zoomFactor <= maxZoomFactor && zoomFactor > 1) {
                    backCamera.videoZoomFactor = zoomFactor
                }
            } catch {
                
            }
        }
    }
    
    //MARK: - Action Methods
    
    @IBAction func didPressTakePhoto(_ sender: UIButton) {
        
        guard let output = stillImageOutput else {
            print("No Output Detected")
            return
        }
        
        if let videoConnection = output.connection(withMediaType: AVMediaTypeVideo) {
            
            videoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
            
            output.captureStillImageAsynchronously(from: videoConnection, completionHandler: {(sampleBuffer, error) in
                
                if (sampleBuffer != nil) {
                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    
                    let dataProvider = CGDataProvider(data: imageData as! CFData)
                    
                    let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                    
                    let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
                    
                    self.capturedImage.image = image
                }
                
            })
        
        }
    }
    
}

