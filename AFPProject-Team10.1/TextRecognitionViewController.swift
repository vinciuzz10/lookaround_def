//
//  ViewController.swift
//  prova_textrecognition
//
//  Created by Vincenzo Di Napoli on 10/05/21.
//

import UIKit
import VisionKit

class TextRecognitionViewController: UIViewController {

    static var flag = 0
    private var imagePassing: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureDocumentView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if TextRecognitionViewController.flag == 1 {
            self.navigationController?.popViewController(animated: true)
        }
        TextRecognitionViewController.flag = 0
    }
    
    func configureDocumentView() {
        let scanningDocumentVC = VNDocumentCameraViewController()
        scanningDocumentVC.delegate = self
        self.present(scanningDocumentVC, animated: true, completion: nil)
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
            
        case "showDocDetected":
            let dstview = segue.destination as! TextRecognizedViewController
            print(imagePassing!)
            dstview.object = self.imagePassing
//            dstview.imageView.image = self.imagePassing!
            
        default: print(#function)
        }
    }
}

extension TextRecognitionViewController: VNDocumentCameraViewControllerDelegate {
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        for pageNumber in 0..<scan.pageCount {
            let image = scan.imageOfPage(at: pageNumber)
            self.imagePassing = image
            performSegue(withIdentifier: "showDocDetected", sender: nil)
//            print(imagePassing)
        }
        controller.dismiss(animated: true, completion: nil)
    }

}
