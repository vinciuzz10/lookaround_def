//
//  ClothesRecognitionViewController.swift
//  AFPProject-Team10.1
//
//  Created by Vincenzo Di Napoli on 24/04/21.
//

import UIKit
import AVFoundation
import Vision
import CoreML

class ClothesRecognitionViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageLabel: UILabel!
    
    var synthetizer = AVSpeechSynthesizer()
    
    var model: ClothesClassifier_2!
    
    override func viewWillAppear(_ animated: Bool) {
        do {
            let config = MLModelConfiguration()
            model = try ClothesClassifier_2(configuration: config)
        } catch { print("Errore nel caricamento del modello") }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        openCamera()
    }
    
    func openCamera() {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
        
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = .camera
        cameraPicker.allowsEditing = false
        
        present(cameraPicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        picker.dismiss(animated: true)
        
        guard let image = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            return
        }
        
        imageView.image = image
        print("Colore con getColor: " + getColor(image))
        
        let color = image.averageColor!
        print("Colore con media: " + color.accessibilityName)
        
        guard let ciImage = CIImage(image: image) else {
             return
        }

        guard let modelml = try? VNCoreMLModel(for: model.model) else {
            return
        }
            
        // Create request for Vision Core ML model loaded
        let request = VNCoreMLRequest(model: modelml) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                let prediction = results.first else {
                    return
                }
                
                // Update the UI on main queue
                DispatchQueue.main.async { [weak self] in
                    self?.imageLabel.text = prediction.identifier
                    self!.speak(self!.imageLabel.text!)
                }
            }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                print(error)
            }
        }
    }

    func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }
    
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "it-IT")
        utterance.rate = 0.4
        
        self.synthetizer.speak(utterance)
    }
    
    func getColor(_ image: UIImage) -> String {
        var colorDict: [String: Int] = [:]

        var yCo = 1300
        var xCo = 0
        
        while yCo < Int(image.size.width)-1300 {
            while xCo < Int(image.size.height)-1800 {
                let pixelColor = image.getPixelColor(pos: CGPoint(x: xCo, y: yCo))
                colorDict[pixelColor.accessibilityName] = (colorDict[pixelColor.accessibilityName] ?? 0) + 1
                
                xCo += 20
            }
            yCo += 20
        }
//        for yCo in 500 ..< Int(image.size.width)-2500 {
//            for xCo in 1000 ..< Int(image.size.height)-1000 {
//                let pixelColor = image.getPixelColor(pos: CGPoint(x: xCo, y: yCo))
//                colorDict[pixelColor.accessibilityName] = (colorDict[pixelColor.accessibilityName] ?? 0) + 1
//            }
//        }
        
        let color = getMaxValue(colorDict)
        return color.0
    }
    
    func getMaxValue(_ dict: [String: Int]) -> (String,Int) {
        var mainColor = ("aaa",0)
        
        for element in dict {
            if element.value>mainColor.1 {
                mainColor = (element.key, element.value)
            }
        }
        return mainColor
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension UIImage {
    
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }

        let extentVector = CIVector(x: inputImage.extent.origin.x + 1950, y: inputImage.extent.origin.y + 1450, z: inputImage.extent.size.width - 1950, w: inputImage.extent.size.height - 1450)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
    
    func getPixelColor(pos: CGPoint) -> UIColor {

        let pixelData = self.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4

        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

}
