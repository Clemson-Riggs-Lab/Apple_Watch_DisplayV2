//
//  ViewController.swift
//  MUSC-Anesthesia
//
//  Created by Nicolas Threatt and Daniel O'Brien on 6/19/18.
//  Copyright © 2018 Riggs Lab. All rights reserved.
//

import UIKit
import WatchConnectivity

//Used to get date for timing and logging
extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
        //RESOLVED CRASH HERE
    }
    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    }
}

extension ViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
//this is for the time selector
extension UIToolbar {
    
    func ToolbarPiker(mySelect : Selector) -> UIToolbar {
        
        let toolBar = UIToolbar()
        
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor.black
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: mySelect)
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        toolBar.setItems([ spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        return toolBar
    }
}

//this is the main class
class ViewController: UIViewController, WCSessionDelegate {
    var session: WCSession!

    //Buttons and labels, connected to the storyboard
    @IBOutlet weak var dateButtonOut: UIButton!
    @IBOutlet weak var dateText: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var labelSecond: UILabel!
    @IBOutlet weak var inputTimeField: UITextField!
    @IBAction func InputTimeBox(_ sender: Any) {}
    @IBOutlet weak var InputTimeBoxField: UITextField!
    @IBOutlet weak var labelMinute: UILabel!
    @IBOutlet weak var labelMillisecond: UILabel!
    
    weak var timer: Timer?
    var startTime: Double = 0
    //var time: Double = 0
    var elapsed: Double = 0
    var status: Bool = false
    //var goTime: Double = 0
    
    let date = Date()
    let expirationDate = Date()
    var components = DateComponents()
    let calendar = Calendar.current
    
    var sendString: String = ""
    //var sendHour: Int = 0
    //var sendMin: Int = 0
    var sendTimeString: String = ""
   // var sendSecString: String = ""
    
    var receivedDataString: String = ""
    var fileLogStartDate = Date()



    @objc func updateCounter() {
       self.labelMillisecond.text = "\(Date())"
    }
    
    
    func start() {
        startTime = Date().timeIntervalSinceReferenceDate - elapsed
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)

        // Set Start/Stop button to true
        status = true
        
        components.setValue(2, for: .second)
       //  let expirationDate = Calendar.current.date(byAdding: components, to: date)
    }
    
    //here we do the writing to text file
    //this could use a bit of work probably but it works
    func writeToFile(clearData: Bool){
        do {
            //filename based on date
            let fileNameString =  "Log_\(Date()).txt"
            
            
            // get the documents folder url
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                // create the destination url for the text file to be saved
                //let fileURL = documentDirectory.appendingPathComponent("WatchOutputLog.txt")
                let fileURL = documentDirectory.appendingPathComponent(fileNameString)

                
                let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
                let url = NSURL(fileURLWithPath: path)
                
                //for checking for file
                if let pathComponent = url.appendingPathComponent(fileNameString) {
                    let filePath = pathComponent.path
                    let fileManager = FileManager.default
                    
                    if (fileManager.fileExists(atPath: filePath) && clearData == false) {
                        print("FILE FOUND")
                        if let fileUpdater = try? FileHandle(forUpdating: fileURL) {
                            // function which when called will cause all updates to start from end of the file
                            fileUpdater.seekToEndOfFile()
                            // which lets the caller move editing to any position within the file by supplying an offset
                            fileUpdater.write(receivedDataString.data(using: .utf8)!)

                            //Once we convert our new content to data and write it, we close the file and that’s it!
                            fileUpdater.closeFile()
                        }
                    }
                    else {
                        print("WRITING NEW FILE")
                        let text = "This is a log file. \n \n \n" + receivedDataString;
                        // writing to disk
                        // Note: if you set atomically to true it will overwrite the file if it exists without a warning
                        try text.write(to: fileURL, atomically: true, encoding: .utf8)
                        
                    }
                } else {
                    print("FILE PATH NOT AVAILABLE")
                }
            }
        } catch {
            print("error:", error)
        }
    }
    
    //this var is updated with the recieved log text
    @IBOutlet weak var returnDataField: UITextView!
    @IBOutlet weak var returnData: UILabel!


    //button to send the time to watch
    @IBOutlet weak var SendTimeButton: UIButton!
    @IBAction func sendMessageToWatch(_ sender: Any) {
        
        sendTimeString = InputTimeBoxField.text!

        //change button
        self.SendTimeButton.backgroundColor = UIColor.green;
        self.SendTimeButton.setTitle("Sent \(sendTimeString)", for: .normal)
        
        
        if (sendTimeString.isEmpty){
            sendTimeString = "input time"
        }
        //send messages to watch
        session.sendMessage(["a":sendTimeString], replyHandler: nil, errorHandler: nil)
    }
    
        
    var lastMessage: CFAbsoluteTime = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        
        InputTimeBoxField.delegate = self
        
        // Do any additional setup after loading the view, typically from a nib.
        if (WCSession.isSupported()) {
            self.session = WCSession.default
            self.session.delegate = self
            self.session.activate()
        }
        start()
    }
    
    @objc func dismissPicker() {
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        InputTimeBoxField.resignFirstResponder()
    }
    
    //The phone received a message
     func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        //receieve messages from watch

        DispatchQueue.main.async{
            //interpret the message with key 'b' as a string
            self.returnDataField.text = message["b"]! as? String
            self.receivedDataString = (message["b"]! as? String)!
            self.writeToFile(clearData: false)
            self.SendTimeButton.backgroundColor = UIColor.blue;
            self.SendTimeButton.setTitle("Send Time", for: .normal)

        }

    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
            
    }
        
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
        
    func sessionDidDeactivate(_ session: WCSession) {
    }
}

