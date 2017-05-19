//
//  RecogViewController.swift
//  Recognizer
//
//  Created by AdamZJK on 18/05/2017.
//  Copyright © 2017 AdamZJK. All rights reserved.
//

import UIKit
import Socket
import MobileCoreServices
import SwiftSocket

func connectAndSentImage(image:UIImage, ip:String!) -> UIImage?{
    let imageData = UIImageJPEGRepresentation(image, 0.3)
    var newImg = UIImage()
    do{

        // 1, sent image
        let tcpSocket = try Socket.create()
        try tcpSocket.connect(to: ip, port: 23333)
        try tcpSocket.write(from: imageData!)
        print("sent")

        
        // 3, retrive image
        var img_buffer = Data(capacity: 1024*1024)
        var img_total = Data(capacity: 4*1024*1024)
        try tcpSocket.setReadTimeout(value: 1000)
        repeat{
            let byte_read = try tcpSocket.read(into: &img_buffer)
            if byte_read != 0 {
                print("Recv bytes ", byte_read)
                img_total.append(img_buffer)
                img_buffer = Data(capacity: 1024*1024)
            } else if img_total.count > 0 {
                break
            }
        }while true

        
        // 3, Set photoImageView to display the selected image.
        print("img_total = ", img_total.count)
        newImg = UIImage(data: img_total)!
    }catch{
        print(error)
        return nil
    }
    return newImg
}

class AlertController: UIViewController {
    
    func showAlert(title:String, message:String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: UIAlertControllerStyle.alert)
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    func dismissAlert(){
        self.dismiss(animated: true, completion: nil)
    }
}


class RecogViewController: UIViewController, UITextFieldDelegate,
UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    //MARK: Properties
    @IBOutlet weak var photoImageView: UIImageView!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss the picker if the user canceled.
        dismiss(animated: true, completion: nil)
    }
    

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // The info dictionary may contain multiple representations of the image. You want to use the original.
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
        //let alert = AlertController()
        //alert.showAlert(title: "Working on it", message: "App is communicating with server, this might take a few seconds...")
        
        print("Connect to " + serverIpAddr!)
        let newImg = connectAndSentImage(image: selectedImage, ip: serverIpAddr!)
        //alert.dismissAlert()
        
        
        // Set photoImageView to display the selected image.
        photoImageView.image = newImg
        
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: Actions
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        UIImageWriteToSavedPhotosAlbum(photoImageView.image!, self, nil, nil)
        let alert = UIAlertController(title: "Saved",
                                      message: "Check your image at your Photolibrary",
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: UIAlertActionStyle.default,
                                      handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    @IBAction func selectImageFromPhotoLibrary(_ sender: UITapGestureRecognizer) {
        
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Pickler source
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        optionMenu.popoverPresentationController?.sourceView = self.view
        
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { (alert : UIAlertAction!) in
            imagePickerController.sourceType = .camera
            imagePickerController.delegate = self
            self.present(imagePickerController, animated: true, completion: nil)
        }
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { (alert : UIAlertAction!) in
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.delegate = self
            self.present(imagePickerController, animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert : UIAlertAction!) in
        }
        optionMenu.addAction(takePhoto)
        optionMenu.addAction(sharePhoto)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }

}
