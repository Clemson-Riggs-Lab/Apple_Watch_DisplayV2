//
//  StartView.swift
//  MUSC-Anesthesia WatchKit Extension
//
//  Created by Nicolas Threatt and Daniel O'Brien on 7/25/18.
//  Copyright © 2018 Riggs Lab. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

var timeHit: Bool = false

//This singleton is used to do a few things mostly log data between the watch pages
class Singleton  {
    var didLoadNewView: Bool = false
    var logAvailable: Bool = false
    var lastTime: Int = 100
    var loggedData: String = ""
    var numTests: Int = 0
    static let sharedInstance = Singleton()
    func setFalse(){ didLoadNewView = false }
    func setTrue(){ didLoadNewView = true }
    func setLastTime(val: Int){ lastTime = val }
    func addAnotherTest(){numTests = numTests + 1;}
    func addLogToDataString(inputString: String){
        loggedData = loggedData + " " + inputString;
    }
    func isLogAvailable(sendBool: Bool){
        logAvailable = sendBool
    }
}

extension String  {
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}

extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }
    
    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}

class StartView: WKInterfaceController ,WCSessionDelegate{
    var session:WCSession!

    weak var timer: Timer?
    let calendar = Calendar.current
    var recievedMin: String?
    var recievedSec: String?
    var didReceiveTime: Bool = false

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        //
    }
    
    @IBAction func sendMessageToPhone() {
        
        let singy = Singleton.sharedInstance;
        
        if(WCSession.isSupported()){
            print("Session supported, message sent")
            session.sendMessage(["b":singy.loggedData], replyHandler: nil, errorHandler: nil)
        }
        else{
            print("Session not supported")
        }
        print("Sent this: XXXXXXXXX \(singy.loggedData)")

    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        print("Recieved Message")
        
        //set the start times value
        recievedMin = message["a"]! as? String
        
        //show recieved time
        self.messageLabel.setText(message["a"]! as? String)
        
        didReceiveTime = true
    }

    
    @IBOutlet var messageLabel: WKInterfaceLabel!
    @IBOutlet var pickerView: WKInterfacePicker!
    @IBOutlet var StartingInLabel: WKInterfaceLabel!
    
    let inputFiles = ["File 1", "File 2", "File 3"]

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        //for sharing, set up Watchkit Session
        if(WCSession.isSupported()){
            self.session = WCSession.default
            self.session.delegate = self
            self.session.activate()
        }
        
        if let vcID = self.value(forKey: "_viewControllerID") as? NSString {
            print("Page One: \(vcID)")
        }
        
        let pickerItems: [WKPickerItem] = inputFiles.map { file in
            let item = WKPickerItem()
            item.title = file
            item.caption = file

            return item
        }
        pickerView.setItems(pickerItems)
        
        //start the 'engine' loop
        startTimer()
    }
    
    @IBAction func pickerSelectedItemChanged(_ value: Int) {
        fileRecieve = inputFiles[value]
    }

    
    func startTimer(){
      print("Starting time loop")
      timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }

    @objc func updateCounter() {
        
        let singy = Singleton.sharedInstance;

        //we check if there is a queued log file to send
        if(singy.logAvailable){
            sendMessageToPhone()
            singy.isLogAvailable(sendBool: false)
        }
        
        //if we received a time, begin countdown
        if(didReceiveTime){
        
            //parsing the received start time
            var resultMin = recievedMin![0...1]    // first two letters
            var resultSec = recievedMin![2...3]
            if(recievedMin!.count == 4){

                resultMin = recievedMin![0...1]    // first two letters
                resultSec = recievedMin![2...3]
            }
            else{
                print("Wrong input")
            }
        
            self.messageLabel.setText(recievedMin)

            //converting received time to ints
            if let myInt = Int(resultMin) , let myInt2 = Int(resultSec){
            
                var timeUntilStart = 1;
                var timeUntilStart2 = 1;

                //show countdown
                if(calendar.component(.minute, from: Date()) < myInt){
                    timeUntilStart = myInt - calendar.component(.minute, from: Date())
                }
                else if( calendar.component(.minute, from: Date()) > myInt){
                    timeUntilStart = (60 - calendar.component(.minute, from: Date())) + myInt;
                }
                else{}
            
                if(calendar.component(.second, from: Date()) < myInt2){
                    timeUntilStart2 = myInt2 - calendar.component(.second, from: Date())
                }
                else if( calendar.component(.second, from: Date()) > myInt2){
                    timeUntilStart2 = (60 - calendar.component(.second, from: Date())) + myInt2;
                }
                else{}
            
            
            // Now make sure we can branch
            if(singy.lastTime != myInt){
                
                StartingInLabel.setText("Starting in : \(timeUntilStart - 1 ) : \(timeUntilStart2)")
                    
                if(calendar.component(.minute, from: Date()) == myInt && singy.didLoadNewView == false){
                    if(calendar.component(.second, from: Date()) == myInt2){
                        singy.setTrue()
                        singy.setLastTime(val: myInt)
                        print("secondPageNow")
                    
                        //load the page
                        presentController(withName: "secondpage", context: nil)
                    }
                }
            }
            else{
                StartingInLabel.setText("Waiting for time")
            }
        }
        }
    }
}
