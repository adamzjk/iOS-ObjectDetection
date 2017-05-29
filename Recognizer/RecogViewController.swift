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
import Speech

var selectedOriginalImage : UIImage?
var useSOINNmodel : Int = 0 ;
var error_message : String?

func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
    
    let scale = newWidth / image.size.width
    let newHeight = image.size.height * scale
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage
}



func connectAndSentImage(image:UIImage, ip:String!) -> UIImage?{
//    let image = resizeImage(image: image, targetSize: CGSizeFromString("{414.0,414.0}"));
    selectedOriginalImage = image;
    let imageData = UIImageJPEGRepresentation(image, 0.2)
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
        tcpSocket.readBufferSize = 1024*1024
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
        error_message = String(describing: error)
        return nil
    }
    return newImg
}

func connectAndSentSOINNimage(image:UIImage, ip:String!){
    selectedOriginalImage = image;
    let image = resizeImage(image: image, newWidth: 299)
    let imageData = UIImageJPEGRepresentation(image!, 0.8)
    do{
        // 1, sent image
        let tcpSocket = try Socket.create()
        try tcpSocket.connect(to: ip, port: 23333)
        try tcpSocket.write(from: imageData!)
        print("sent")
    } catch {
        print(error)
    }
}

func sendFeedbackByUDP(message:String!, ip:String!){
    do {
        if useSOINNmodel == 0{
            let udpSocket = try Socket.create(family: .inet, type: .datagram, proto: .udp)
            let serverAddr = Socket.createAddress(for: ip, on: 23335)
            try udpSocket.write(from: message, to: serverAddr!)
            print("send feedback " + message + " to 23335")
        } else {
            let udpSocket = try Socket.create(family: .inet, type: .datagram, proto: .udp)
            let serverAddr = Socket.createAddress(for: ip, on: 24678)
            try udpSocket.write(from: message, to: serverAddr!)
            print("send feedback " + message + " to 24678")
        }
    } catch {
        print("Send feedback Failed!")
        print(error)
    }
}

func receiveStringByUDP(ip:String!) -> String! {
    do {
        let udpSocket = try Socket.create(family: .inet, type: .datagram, proto: .udp)
        var data = Data()
        let _ = try udpSocket.listen(forMessage: &data, on: 23337)
        return String(bytes: data, encoding: .utf8)
    } catch  {
        print(error)
    }
    return "error, try again!"
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
    @IBOutlet weak var ratingControl: RatingControl!
    @IBOutlet weak var voiceButton: UIButton!
    @IBOutlet weak var voiceTextLabel: UILabel!
    @IBOutlet weak var feedbackButton: UIBarButtonItem!
    
    
    // Speech Recognizer
    var speechRecognitionResults = String()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var feedbackRecorded : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechRecognizer?.delegate = self as? SFSpeechRecognizerDelegate
        feedbackButton.isEnabled = false
        // create the alert
        let msg_str:String = "YOLO is a deep neural network for object detection while SOINN is an life-long learning model"
        let alert = UIAlertController(title: "Which Model to Use?",
                                      message: msg_str,
                                      preferredStyle: UIAlertControllerStyle.alert)
        
        // add the actions (buttons)
        alert.addAction(UIAlertAction(title: "Use SOINN", style: UIAlertActionStyle.default, handler: { action in
            useSOINNmodel = 1;
        }))
        alert.addAction(UIAlertAction(title: "Use YOLO", style: UIAlertActionStyle.default, handler: { action in
            useSOINNmodel = 0;
        }))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)

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
        if feedbackButton.isEnabled == true{
            print("Didn't send feedback, send default feedback")
            sendFeedbackByUDP(message: "none", ip: serverIpAddr)
        }
        
        // clear feedback
        voiceTextLabel.text = ""
        feedbackButton.isEnabled = true
        feedbackRecorded = 0
        ratingControl.rating = 0
        
        // The info dictionary may contain multiple representations of the image. You want to use the original.
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
        print("Connect to " + serverIpAddr!)
        
        if useSOINNmodel == 0 {
            let newImg = connectAndSentImage(image: selectedImage, ip: serverIpAddr!)
            photoImageView.image = newImg
            dismiss(animated: true, completion: nil)
        } else {
            photoImageView.image = selectedImage
            dismiss(animated: true, completion: nil)
            connectAndSentSOINNimage(image: selectedImage, ip: serverIpAddr!)
            let message = receiveStringByUDP(ip: serverIpAddr)
            voiceTextLabel.text = message
        }
    }
    
    //Speech Recognition
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.speechRecognitionResults = (result?.bestTranscription.formattedString)!
                self.voiceTextLabel.text = self.speechRecognitionResults;
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.voiceButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        self.voiceButton.isEnabled = available
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
    
    @IBAction func feedbackButtonPressed(_ sender: UIBarButtonItem) {
        if useSOINNmodel == 0 {
            let score = ratingControl.rating
            sendFeedbackByUDP(message: String(score), ip: serverIpAddr)
        } else {
            if feedbackRecorded == 0 {
                let alert = UIAlertController(title: "No Answer Found",
                                              message: "Please give us the real name of the object and help us improve our model.",
                                              preferredStyle: UIAlertControllerStyle.alert)
                alert.addTextField(configurationHandler: {(textField: UITextField!) in
                    textField.placeholder = "Enter text:"
                    textField.isSecureTextEntry = false // for password input
                })
                // 3. Grab the value from the text field, and print it when the user clicks OK.
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                    let message = alert!.textFields![0].text // Force unwrapping because we know it exists.
                    if message == nil{
                        return
                    }
                    print("use input by hand [feedback]=" + message!)
                    sendFeedbackByUDP(message: message, ip: serverIpAddr)
                }))
                self.present(alert, animated: true, completion: nil)
            } else {
                let words = voiceTextLabel.text!.components(separatedBy: " ")
                let message = words[words.count-1]
                sendFeedbackByUDP(message: message, ip: serverIpAddr)
            }
        }
        
        let alert = UIAlertController(title: "Thanks",
                                      message: "Our object detection model wil be improved with the help of your feedback",
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: UIAlertActionStyle.default,
                                      handler: nil))
        self.present(alert, animated: true, completion: nil)
        feedbackButton.isEnabled = false
    }
    
    @IBAction func voiceButtonPressed(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            self.voiceButton.isEnabled = false
            voiceTextLabel.text = self.speechRecognitionResults;
            if useSOINNmodel == 0{
                ratingControl.sentimentAnalysisAndAdjustScore(text: self.speechRecognitionResults)
            }
            self.voiceButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            self.voiceButton.setTitle("Stop Recording", for: .normal)
        }
        feedbackRecorded = 1
    }
    
    @IBAction func selectImageFromPhotoLibrary(_ sender: UITapGestureRecognizer) {
        
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        voiceTextLabel.text = nil
        
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



