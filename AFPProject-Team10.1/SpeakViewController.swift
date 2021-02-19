//
//  SpeakViewController.swift
//  AFPProject-Team10.1
//
//  Created by antonello avella on 18/02/21.
//

import UIKit
import Speech
import AudioToolbox

extension UITextView {
    func centerVertically() {
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
}

class SpeakViewController: UIViewController,  SFSpeechRecognizerDelegate,  UITextViewDelegate  {

    @IBOutlet weak var micImage: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()

    let labels = ["person", "bicycle", "car", "motorbike", "aeroplane", "bus", "train", "truck", "boat", "traffic light", "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat", "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket", "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair", "sofa", "pottedplant", "bed", "diningtable", "toilet", "tvmonitor", "laptop", "mouse", "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink", "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush"]
    
    
    
    // MARK: View Controller Lifecycle
    
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.becomeFirstResponder()
        self.textView.delegate = self
        self.textView.layer.cornerRadius = 20
        textView.clipsToBounds = false
        textView.layer.shadowColor = UIColor.systemGray2.cgColor
        textView.layer.shadowOpacity=0.4
        textView.layer.shadowOffset = CGSize(width: 3, height: 3)
        
        // Disable the record buttons until authorization has been granted.
        
       
        label.text = "Shake device to start recording"
    }
    
    // We are willing to become first responder to get shake motion
    public override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    // Enable detection of shake motion
    public override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            shaked()
        }
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.text = "I'm your assistant"
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        let utterance = AVSpeechUtterance(string: "What are you searching for? " + label.text!)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        
        let synthetizer = AVSpeechSynthesizer()
        synthetizer.speak(utterance)
        
        defer {
            disableAVSession()
        }
        // Configure the SFSpeechRecognizer object already
        // stored in a local member variable.
        speechRecognizer.delegate = self
        
        // Asynchronously make the authorization request.
        SFSpeechRecognizer.requestAuthorization { authStatus in
            
            // Divert to the app's main thread so that the UI
            // can be updated.
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.label.text! = "Shake device to start recording"
                case .denied:
                    self.label.text! = "User denied access to speech recognition"
                case .restricted:
                    self.label.text! = "Speech recognition restricted on this device"
                    
                case .notDetermined:
                    self.label.text! = "Speech recognition restricted on this device"
                    
                default:
                    self.label.text! = "Speech recognition restricted on this device"
                }
            }
        }
    }
    
    private func startRecording() throws {
        
        // Cancel the previous task if it's running.
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        // Configure the audio session for the app.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        
        // Keep speech recognition data on device
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                self.textView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.label.text! = "Shake device to start recording"
            }
        }
        
        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Let the user know to start talking.
        textView.text = "Go ahead, I'm listening"
    }
    
    
    
    // MARK: Interface Builder actions
    
    func shaked() {
        if audioEngine.isRunning {
            
            
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: .default, options: .defaultToSpeaker)
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("audioSession properties weren't set because of an error.")
            }
            audioEngine.stop()
            recognitionRequest?.endAudio()
            //            textView.text! = " "
            self.label.text! = "Stopping"
            
            if labels.contains(textView.text.lowercased()) {
                let utterance = AVSpeechUtterance(string: "I will search for a " + textView.text!)
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                utterance.rate = 0.5
                
                let synthetizer = AVSpeechSynthesizer()
                
                let _: () = DispatchQueue.main.async {
                    synthetizer.speak(utterance)
                }
                do {
                    disableAVSession()
                }
                performSegue(withIdentifier: "showSearch", sender: nil)
            }
            else{
                if self.textView.text! == "Go ahead, I'm listening" {
                    let utterance = AVSpeechUtterance(string: "I didn't understand, please try again")
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    utterance.rate = 0.5
                    
                    let synthetizer = AVSpeechSynthesizer()
                    synthetizer.speak(utterance)
                }
                else {
                    let utterance = AVSpeechUtterance(string: "I cannot recognize " + textView.text! + ". Please try again")
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    utterance.rate = 0.5
                    
                    let synthetizer = AVSpeechSynthesizer()
                    
                    let _: () = DispatchQueue.main.async {
                        synthetizer.speak(utterance)
                    }
                    do {
                        disableAVSession()
                    }
                }
            }
            
        } else {
            micImage.tintColor = UIColor.systemPink
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            do {
                try startRecording()
                self.label.text! = "Shake device to stop recording"
            } catch {
                self.label.text! = "Recording not available"
            }
        }
    }
    private func disableAVSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't disable.")
        }
    }

    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        
        case  "showSearch":
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            micImage.tintColor = UIColor.systemGray2
            let dstview = segue.destination as! VisionObjectRecognitionViewController
            dstview.object = self.textView.text
        
        default: print(#function)
        }
    }
}
