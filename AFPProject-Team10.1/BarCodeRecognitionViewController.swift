//
//  BarCodeRecognitionViewController.swift
//  AFPProject-Team10.1
//
//  Created by Vincenzo Di Napoli on 24/04/21.
//

import UIKit
import AVFoundation


// MARK: -ScannerClass

class Scanner: NSObject {
    
    private var viewController: UIViewController
    private var captureSession: AVCaptureSession?
    private var codeOutputHandler: (_ code: String) -> Void
    
    init(withViewController viewController: UIViewController, view: UIView, codeOutputHandler: @escaping (String) -> Void) {
        self.viewController = viewController
        self.codeOutputHandler = codeOutputHandler
        
        super.init()
        
        if let captureSession = self.createCaptureSession() {
            self.captureSession = captureSession
            let previewLayer = self.createPreviewLayer(withCaptureSession: captureSession, view: view)
            view.layer.addSublayer(previewLayer)
        }
    }
    
    func createCaptureSession() -> AVCaptureSession? {
        let captureSession = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return nil
        }
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            let metaDataOutput = AVCaptureMetadataOutput()
            
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }
            else {
                return nil
            }
            
            if captureSession.canAddOutput(metaDataOutput) {
                captureSession.addOutput(metaDataOutput)
                
                if let viewController = self.viewController as? AVCaptureMetadataOutputObjectsDelegate {
                    metaDataOutput.setMetadataObjectsDelegate(viewController, queue: DispatchQueue.main)
                    metaDataOutput.metadataObjectTypes = self.metaObjectTypes()
                }
            }
            else {
                return nil
            }
        } catch {
            return nil
        }
        
        return captureSession
    }
    
    private func metaObjectTypes() -> [AVMetadataObject.ObjectType] {
        return [
            .qr, .code128, .code39, .code39Mod43, .code93, .ean13, .ean8, .interleaved2of5, .itf14, .pdf417, .upce
        ]
    }
    
    private func createPreviewLayer(withCaptureSession captureSession: AVCaptureSession, view: UIView) -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        return previewLayer
    }
    
    func startSession() {
        guard let captureSession = self.captureSession else {
            return
        }

        if !captureSession.isRunning {
            captureSession.startRunning()
            print("Session start")
        }
        
    }
    
    func stopSession() {
        guard let captureSession = self.captureSession else {
            return
        }
        
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    public func scannerDelegate(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        self.stopSession()
        
        if let metaDataObject = metadataObjects.first {
            guard let readableObject = metaDataObject as? AVMetadataMachineReadableCodeObject else {
                return
            }
            
            guard let stringValue = readableObject.stringValue else {
                return
            }
            
            self.codeOutputHandler(stringValue)
        }
    }
    
}


// MARK: -ViewControllerClass

class BarCodeRecognitionViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    private var captureSession: AVCaptureSession?

    private var scanner: Scanner?
    private var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.scanner = Scanner(withViewController: self, view: self.view, codeOutputHandler: self.handleCode)
        
        if let scanner = self.scanner {
            scanner.startSession()
        }
    }
    
    func handleCode(code: String) {
//        self.url = URL(string: "https://world.openfoodfacts.org/api/v0/product/" + code + ".json")!
        self.url = URL(string: "https://world.openfoodfacts.org/api/v0/product/8076809536721.json")!
        
        performSegue(withIdentifier: "showBarCodeResult", sender: nil)
    }

    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        self.scanner?.scannerDelegate(output, didOutput: metadataObjects, from: connection)
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
        case "showBarCodeResult":
            let dstview = segue.destination as! BarCodeResultViewController
            dstview.url = self.url
            
        default: print(#function)
        }
    }

}
