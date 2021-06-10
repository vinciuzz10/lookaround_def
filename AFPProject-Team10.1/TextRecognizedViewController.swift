//
//  ViewControllerImagePicked.swift
//  prova_textrecognition
//
//  Created by Vincenzo Di Napoli on 10/05/21.
//

import UIKit
import Vision
import AVFoundation


class TextRecognizedViewController: UIViewController {
    
    var object: UIImage!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    
    private var text: String?
    
    private var request = VNRecognizeTextRequest(completionHandler: nil)
    
    var synthetizer = AVSpeechSynthesizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textView.accessibilityElementsHidden = true
        // Do any additional setup after loading the view.
        self.imageView.image = object
        TextRecognitionViewController.flag = 1
        setupVisionTextRecognizeImage(image: self.object)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.synthetizer.stopSpeaking(at: .immediate)
    }
    
    private func setupVisionTextRecognizeImage(image: UIImage?) {
        var text = ""
        
        request = VNRecognizeTextRequest(completionHandler: { (request,error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {fatalError("Received Invalid Observation")}
                
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else {
                    print("No Candidate")
                    continue
                }
                text += "\(topCandidate.string) "
                
                DispatchQueue.main.async {
                    self.textView.text = text
                }
            }
            self.speak(text)
        })
        
        
//        request.customWords = ["cust0m"]
//        request.minimumTextHeight = 0.03125
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["it_IT","en-US"]
        request.usesLanguageCorrection = true
        
        let requests = [request]
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let img = image?.cgImage else { fatalError("Missing image to scan")}
            let handle = VNImageRequestHandler(cgImage: img, options: [:])
            
            try? handle.perform(requests)
        }
        
    }
    
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "it-IT")
        utterance.rate = 0.4
        
        self.synthetizer.speak(utterance)
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
