//
//  AddViewController.swift
//  Recognizer
//
//  Created by AdamZJK on 18/05/2017.
//  Copyright © 2017 AdamZJK. All rights reserved.
//

import UIKit
import Socket

var serverIpAddr: String?


class AddViewController: UIViewController {
    //MARK: Properties
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var ipTextField: UITextField!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.isEnabled = false
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "background")!)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Actions
    
    
    @IBAction func continueAction(_ sender: UIButton) {
        serverIpAddr = ipTextField.text
        if serverIpAddr == nil || serverIpAddr == "" {
            serverIpAddr = "0.0.0.0"
        }
        do {
            let sckt = try Socket.create()
            try sckt.setReadTimeout(value: 1)
            try sckt.setWriteTimeout(value: 1)
            try sckt.connect(to: serverIpAddr!, port: 23334)
            sckt.close()
        } catch  {
            let alert = UIAlertController(title: "Error",
                                          message: "Connot Connect to " + serverIpAddr!,
                                          preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Abort",
                                          style: UIAlertActionStyle.destructive,
                                          handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        let alert = UIAlertController(title: "Pass!",
                                      message: "Server Alive and Functional",
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: UIAlertActionStyle.default,
                                      handler: nil))
        doneButton.isEnabled = true
        self.present(alert, animated: true, completion: nil)
    }
}




