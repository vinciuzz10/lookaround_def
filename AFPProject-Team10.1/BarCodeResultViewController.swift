//
//  BarCodeResultViewController.swift
//  AFPProject-Team10.1
//
//  Created by Vincenzo Di Napoli on 21/05/21.
//

import UIKit

class BarCodeResultViewController: UIViewController {
    
    var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
            let item: Product = try! JSONDecoder().decode(Product.self, from: data)
            print(item.code + "\n" + item.product.product_name_it + "+\n" + item.product.generic_name)
            print(item.product.ingredients_text_it + "\n" + item.product.ingredients_text_en)
        }.resume()

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
    let generic_name: String
    let product_name_it: String
    let ingredients_text_it: String
    let ingredients_text_en: String
}
