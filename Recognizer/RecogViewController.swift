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
        return nil
    }
    return newImg
}

func sendFeedbackByUDP(score:Int!, ip:String!){
    do {
        let udpSocket = try Socket.create(family: .inet, type: .datagram, proto: .udp)
        let serverAddr = Socket.createAddress(for: ip, on: 23335)
        try udpSocket.write(from: String(score), to: serverAddr!)
    } catch {
        print(error)
    }
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
    
    
    // Speech Recognizer
    var speechRecognitionResults = String()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechRecognizer?.delegate = self as? SFSpeechRecognizerDelegate

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
        let score = ratingControl.rating
        sendFeedbackByUDP(score: score, ip: serverIpAddr)
        let alert = UIAlertController(title: "Thanks",
                                      message: "Our object detection model wil be improved with the help of your feedback",
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: UIAlertActionStyle.default,
                                      handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func voiceButtonPressed(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            self.voiceButton.isEnabled = false
            voiceTextLabel.text = self.speechRecognitionResults;
            ratingControl.sentimentAnalysisAndAdjustScore(text: self.speechRecognitionResults)
//            let alert = UIAlertController(title: "Message",
//                                          message: self.speechRecognitionResults,
//                                          preferredStyle: UIAlertControllerStyle.alert)
//            alert.addAction(UIAlertAction(title: "nice!",
//                                          style: UIAlertActionStyle.default,
//                                          handler: nil))
//            self.present(alert, animated: true, completion: nil)
            self.voiceButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            self.voiceButton.setTitle("Stop Recording", for: .normal)
        }
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
        
        // clear feedback
        voiceTextLabel.text = "";
        ratingControl.rating = 0;
    }
}



