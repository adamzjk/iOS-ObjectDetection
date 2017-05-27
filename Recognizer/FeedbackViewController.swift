//
//  FeedbackViewController.swift
//  Recognizer
//
//  Created by AdamZJK on 26/05/2017.
//  Copyright © 2017 AdamZJK. All rights reserved.
//

import UIKit



class FeedbackViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        if selectedOriginalImage != nil{
            imageView.image = selectedOriginalImage;
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
