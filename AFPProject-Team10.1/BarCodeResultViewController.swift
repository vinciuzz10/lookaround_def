//
//  BarCodeResultViewController.swift
//  AFPProject-Team10.1
//
//  Created by Vincenzo Di Napoli on 21/05/21.
//

import UIKit
import AVFoundation

class BarCodeResultViewController: UIViewController {
    
    var url: URL?
    var item: Product?
    
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var productImage: UIImageView!
    
    private let synthetizer = AVSpeechSynthesizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BarCodeRecognitionViewController.barCodeFlag = 1
        self.productNameLabel.adjustsFontSizeToFitWidth = true

//         Do any additional setup after loading the view.
        URLSession.shared.dataTask(with: self.url!) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                // Handle Error
                print("Errore")
                return
            }
            guard let response = response else {
                // Handle Empty Response
                print("Empty response")
                return
            }
            guard let data = data else {
                // Handle Empty Data
                print("Empty data")
                return
            }
            // Handle Decode Data into Model
//            do {
                self.item = try? JSONDecoder().decode(Product.self, from: data)
                
            
                DispatchQueue.main.sync {
                    
                    if let productNameIt = self.item?.product.product_name_it {
                        self.productNameLabel.text = productNameIt
                    }
                    else if let productName = self.item?.product.product_name{
                        self.productNameLabel.text = productName
                    }
                    else if let genericName = self.item?.product.generic_name{
                        self.productNameLabel.text = genericName
                    }
                    else {
                        self.productNameLabel.text = "Prodotto Non Trovato"
                        self.speak(self.productNameLabel.text! + ". Riprova.")
                        return
                    }
                    
                    if let imageUrl = self.item?.product.image_url {
                        self.productImage.load(url: URL.init(string: imageUrl)!)
                    }

                    if let ingredients = self.item?.product.ingredients_text_it {
                        self.speak(self.productNameLabel.text! + ". Agita per conoscere gli ingredienti")
                    }
                    else {
                        self.speak(self.productNameLabel.text!)
                    }
                    
                }
//            } catch {
//                print(error)
//                DispatchQueue.main.sync {
//                    self.productNameLabel.text = "Prodotto non trovato."
//                    self.speak(self.productNameLabel.text! + ". Riprova.")
//                }
//                return
//            }
            
        }.resume()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.synthetizer.stopSpeaking(at: .immediate)
    }
    
    func speak(_ text: String) {
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "it-IT")
        utterance.rate = 0.5
        
        self.synthetizer.speak(utterance)
    }

    public override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            if let ingredients = self.item?.product.ingredients_text_it {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                speak(ingredients)
            }
        }
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

struct Product: Codable {
    
    let code: String
    let product: Properties
}

struct Properties: Codable {
    let product_name_it: String
    let ingredients_text_it: String
    let image_url: String
    let generic_name: String
    let product_name: String
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
