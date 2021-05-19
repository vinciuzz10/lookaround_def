//
//  SpeakViewController.swift
//  AFPProject-Team10.1
//
//

import UIKit
import Speech
import AudioToolbox

class SpeakViewController: UIViewController,  SFSpeechRecognizerDelegate {

    @IBOutlet weak var micImage: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textView: UITextView!

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "it-IT"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthetizer = AVSpeechSynthesizer()
	
	let session = AVAudioSession.sharedInstance()
    
    
    //modificare in dictionary
    let labels = ["person": "persona", "bicycle": "bicicletta", "car": "macchina", "motorbike": "moto", "aeroplane": "aereo", "bus": "bus", "train": "treno", "truck": "trattore", "boat": "barca", "traffic light" : "semaforo", "fire hydrant": "idrante", "stop sign" : "segnale di stop", "parking meter": "parchimetro", "bench": "panchina", "bird": "uccello", "cat": "gatto", "dog": "cane", "horse": "cavallo", "sheep": "pecora", "cow": "mucca", "elephant": "elefante", "bear": "orso", "zebra": "zebra", "giraffe": "giraffa", "backpack": "zaino", "umbrella": "ombrello", "handbag": "borsa", "tie": "cravatta", "suitcase": "valigia", "frisbee": "frisbee", "skis": "sci", "snowboard": "snowboard", "sports ball": "palla", "kite": "aquilone", "baseball bat": "mazza da baseball", "baseball glove": "guanto da baseball", "skateboard": "skateboard", "surfboard": "tavola da surf", "tennis racket": "racchetta", "bottle": "bottiglia", "wine glass": "bicchiere", "cup": "tazza", "fork": "forchetta", "knife": "coltello", "spoon": "cucchiaio", "bowl": "ciotola", "banana": "banana", "apple": "mela", "sandwich": "panino", "orange": "arancia", "broccoli": "broccoli", "carrot": "carota", "hot dog": "hot dog", "pizza": "pizza", "donut": "ciambella", "cake": "torta", "chair": "sedia", "sofa": "divano", "pottedplant": "pianta", "bed": "letto", "diningtable": "tavolo", "toilet": "water", "tvmonitor": "televisione", "laptop": "computer", "mouse": "mouse", "remote": "telecomando", "keyboard": "tastiera", "cell phone": "cellulare", "microwave": "microonde", "oven": "forno", "toaster": "tostapane", "sink": "lavandino", "refrigerator": "frigorifero", "book": "libro", "clock": "orologio", "vase":"vaso", "scissors": "forbici","teddy bear": "pupazzo", "hair drier": "phon", "toothbrush": "spazzolino"]
    
    let userDefaults = UserDefaults.standard
    
	var denied = true
    var firstTime = true
    var objectDetected: String?
    
    // MARK: View Controller Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.becomeFirstResponder()
        self.textView.layer.cornerRadius = 20
        textView.clipsToBounds = false
        textView.layer.shadowColor = UIColor.systemGray2.cgColor
        textView.layer.shadowOpacity=0.4
        textView.layer.shadowOffset = CGSize(width: 3, height: 3)

        label.text = "Agita il dispositivo per iniziare a registrare"
        
        textView.accessibilityElementsHidden = true
        
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
        textView.text = "Sono il tuo assistente."
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
		
        if userDefaults.bool(forKey: "alreadyOpenApp") {
            speak("Come posso aiutarti?" + label.text!)
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
                    self.label.text! = "Agita il dispositivo per iniziare a registrare"
					self.denied = false
                    if !self.userDefaults.bool(forKey: "alreadyOpenApp") {
                        self.userDefaults.setValue(true, forKey: "alreadyOpenApp")
                        self.tutorial()
                    }
                case .denied:
                    self.label.text! = "L'utente ha negato l'accesso al riconoscimento vocale"
                case .restricted:
                    self.label.text! = "Riconoscimento vocale negato su questo dispositivo"
				case .notDetermined:
                    self.label.text! = "Riconoscimento vocale negato su questo dispositivo"
                default:
                    self.label.text! = "Riconoscimento vocale negato su questo dispositivo"
                }
            }
        }
    }
    
	func showAlert(){
		// Create new Alert
		let dialogMessage = UIAlertController(title: "Alert", message: "Garantire l'accesso al Microfono e al Riconoscimento Vocale nelle Impostazioni.", preferredStyle: .alert)
		// Create OK button with action handler
		let settingsAction = UIAlertAction(title: "Impostazioni", style: .default) { (_) -> Void in
			let settingsUrl = NSURL(string: UIApplication.openSettingsURLString)
			if settingsUrl != nil {
				UIApplication.shared.open(settingsUrl! as URL)
			}
		}
		
		let cancelAction = UIAlertAction(title: "Cancella", style: .default, handler: nil)
		dialogMessage.addAction(settingsAction)
		dialogMessage.addAction(cancelAction)

		//Add OK button to a dialog message
		// Present Alert to
		self.present(dialogMessage, animated: true, completion: nil)
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
                
                self.label.text! = "Agita il dispositivo per iniziare a registrare"
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
        textView.text = "Vai avanti, ti sto ascoltando."
    }
    

    
    // MARK: Interface Builder actions
    
    func shaked() {
        if (session.responds(to: #selector(AVAudioSession.requestRecordPermission(_:)))) {
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    do {
                        try  self.session.setCategory(AVAudioSession.Category.playAndRecord, mode: .default, options: .defaultToSpeaker)
                        try self.session.setActive(true, options: .notifyOthersOnDeactivation)
                        
                    }
                    catch {
                        print("Couldn't set Audio session category")
                    }
                } else{
                    self.denied = true
                }
            })
        }
		if denied {
			showAlert()
			return
		}
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
            
            if textView.text.lowercased().contains("testo") {
                speak("Proveró a leggere un testo.")
                
                performSegue(withIdentifier: "readText", sender: nil)
            }
            else if textView.text.lowercased().contains("vestiti") || textView.text.lowercased().contains("vestito") {
                speak("Ti aiuteró a scegliere i vestiti.")
                
                performSegue(withIdentifier: "recognizeClothes", sender: nil)
            }
            else if textView.text.lowercased().contains("codice a barre") || textView.text.lowercased().contains("barcode") {
                speak("Ti aiuteró a identificare un codice a barre.")
                
                performSegue(withIdentifier: "recognizeBarCode", sender: nil)
            }
            else if labels.values.contains(textView.text.lowercased()) {
                speak("Sto cercando " + textView.text!)
                
                performSegue(withIdentifier: "showSearch", sender: nil)
            }
            else{
                var flag = 0
                labels.values.forEach { (s) in
                    if textView.text.contains(s) {
                        flag = 1
                        self.objectDetected = s
                        speak("Sto cercando " + s)
                        
                        performSegue(withIdentifier: "showSearch", sender: nil)
                        return
                    }
                }
                if flag == 1 {
                    return
                }
                if self.textView.text! == "Vai avanti, ti sto ascoltando" {
                    speak("Non ho capito. Riprova.")
                }
                else {
                    speak("Non riesco ad aiutarti. Riprova per favore.")
                }
            }
        } else {
            self.synthetizer.stopSpeaking(at: .immediate)
            micImage.tintColor = UIColor.systemPink
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            do {
                try startRecording()
                self.label.text! = "Agita il dispositivo per fermare la registrazione."
            } catch {
                self.label.text! = "Registrazione non disponibile."
            }
        }
    }
	

    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        
        case  "showSearch":
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            micImage.tintColor = UIColor.systemGray2
            let dstview = segue.destination as! VisionObjectRecognitionViewController
        
            for key in labels.keys {
                if labels[key] == self.objectDetected {
                    dstview.object = key
                    break
                }
            }

        default: print(#function)
        }
    }
    
    func tutorial() {
        speak("Per chiedere aiuto agita il dispositivo e esponi la tua richiesta. Agita nuovamente per confermare. Puoi riconoscere oggetti, testo, vestiti e codici a barre.")
    }
    
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "it-IT")
        utterance.rate = 0.5
        
        self.synthetizer.speak(utterance)
    }
    
    func updateTextFont() {
        if (textView.text.isEmpty || textView.bounds.size.equalTo(CGSize.zero)) {
            return;
        }

        let textViewSize = textView.frame.size;
        let fixedWidth = textViewSize.width;
        let expectSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT)));

        var expectFont = textView.font;
        if (expectSize.height > textViewSize.height) {
            while (textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT))).height > textViewSize.height) {
                expectFont = textView.font!.withSize(textView.font!.pointSize - 1)
                textView.font = expectFont
            }
        }
        else {
            while (textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT))).height < textViewSize.height) {
                expectFont = textView.font;
                textView.font = textView.font!.withSize(textView.font!.pointSize + 1)
            }
            textView.font = expectFont;
        }
    }
}

