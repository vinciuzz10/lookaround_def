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

    let labelDictionary = ["t-shirt":"Maglietta", "pants":"Pantaloni", "hat":"Cappello", "longsleeve":"Maglia a maniche lunghe", "shorts":"Pantaloncini", "undershirt":"Canottiera", "shoes":"Scarpe", "skirt":"Gonna", "blazer":"Giacca", "blouse":"Camicia da donna", "dress":"Vestito da donna", "body":"Body", "hoodie":"Felpa", "outwear":"Giubbotto", "polo":"Polo", "shirt":"Camicia", "top":"Top", "jeans":"Jeans", "anorak":"Giacca a vento", "bomber":"Bomber", "button-down":"Camicia", "caftan":"Caftan", "capris":"Pinocchietto", "cardigan":"Cardigan", "chinos":"Pantalone", "coat":"Cappotto", "culottes":"Pantalone a zampa d'elefante", "cutoffs":"Pantaloncino da donna", "flannel":"Camicia di flanella", "gaucos":"Pantaloni", "halter":"Top", "henley":"Maglia", "jacket":"Giubbotto", "jeggins":"Jeggins", "jersey":"Maglietta sportiva", "jodhurs":"Pantaloni", "joggers":"Pantaloni di tuta", "jumpsuit":"Salopette", "kimono":"Kimono", "leggings":"Leggings", "parka":"Parka", "peacoat":"Cappotto", "poncho":"Poncho", "robe":"Vestaglia", "romper":"Vestitino", "sarong":"Sarong", "sweater":"Maglione", "sweatpants":"Pantaloni di tuta", "sweatshorts":"Pantaloncini sportivi", "tank":"Canottiera", "tee":"Maglietta", "trunks":"Costume a pantaloncino", "turtleneck":"Maglia a collo alto"]
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageLabel: UILabel!
    @IBOutlet weak var colorLabel: UILabel!
    
    var synthetizer = AVSpeechSynthesizer()
    
    var model: ClothesClassifier!
    
    override func viewWillAppear(_ animated: Bool) {
        do {
            let config = MLModelConfiguration()
            model = try ClothesClassifier(configuration: config)
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
        
        self.colorLabel.text = getColor(image).capitalized(with: .current)
        
        let scaledImage = image.scalePreservingAspectRatio(targetSize: CGSize(width: 300, height: 300))
        imageView.image = scaledImage
        
        guard let ciImage = CIImage(image: scaledImage) else {
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
                let clothesName = prediction.identifier.lowercased()
                self?.imageLabel.text = self!.labelDictionary[clothesName]
                self!.speak(self!.imageLabel.text! + ". Colore: " + self!.colorLabel.text!)
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
    
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )

        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        
        return scaledImage
    }

}
