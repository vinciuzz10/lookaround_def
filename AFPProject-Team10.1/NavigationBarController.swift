//
//  NavigationBarController.swift
//  AFPProject-Team10.1
//
//  Created by antonello avella on 19/02/21.
//

import UIKit

class NavigationBarController: UINavigationController {

    @IBOutlet weak var navBar: UINavigationBar!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navBar.layer.shadowColor = UIColor.systemGray2.cgColor
        self.navBar.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        self.navBar.layer.shadowRadius = 4.0
        self.navBar.layer.shadowOpacity = 1.0

        // Do any additional setup after loading the view.
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
