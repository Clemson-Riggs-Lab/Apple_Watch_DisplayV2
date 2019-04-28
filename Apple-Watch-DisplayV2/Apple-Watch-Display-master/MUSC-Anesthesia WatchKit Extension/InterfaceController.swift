//
//  InterfaceController.swift
//  MUSC-Anesthesia WatchKit Extension
//
//  Created by Nicolas Threatt and Daniel O'Brien on 6/19/18.
//  Copyright © 2018 Riggs Lab. All rights reserved.
//

import WatchKit
import Foundation

var fileRecieve = String()

class InterfaceController: WKInterfaceController {

    // Display Labels
    @IBOutlet var NameRoom: WKInterfaceLabel!
    @IBOutlet var MedicalIssue: WKInterfaceLabel!
    @IBOutlet var Data: WKInterfaceLabel!
    @IBOutlet var Et: WKInterfaceLabel!
    @IBOutlet var DirectionArrow: WKInterfaceLabel!
    @IBOutlet var underline: WKInterfaceSeparator!

    // Variables used to store data from Txt/CSV file
    var patientNameRoom = [String](), patientIssue = [String](), patientData = [String](), arrowTxt = [String]()
    var currentPatientIssue = String()
    var fileName = String()
    let numCols = 6

    // Iterate through data
    var time = [Int]()
    var rows = Int()
    var i = 0

    //Keeping times
    var recordTimes = [DispatchTime]()
    var recordTime = [String : DispatchTime]()

    //array of events
    struct eventLogElement{
        var eventType: String
        var startTime: DispatchTime
        var endTime: DispatchTime
        var pressedOK: Bool
        var pressedTime: DispatchTime
    }
    var eventLog = [eventLogElement]()
    var currentEventNum = 0
    
    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        super.awake(withContext: context)
 
         //hide cancel
        // I cant figure out how to completely remove the 'cancel' button on WatchKit, pressing it causes problems.
        self.setTitle("")
        
        if let vcID = self.value(forKey: "_viewControllerID") as? NSString {
            print("Page Two: \(vcID)")
        }
        
        //singleton for logging data
        let singy = Singleton.sharedInstance

        singy.addLogToDataString(inputString: "Experiment Started at: \(Date())")
        singy.addLogToDataString(inputString: "\n")
        singy.addLogToDataString(inputString: "\n")

        // Format interface
        formatDisplay()

        // Find correct file
        switch(fileRecieve) {
            case "File 1":
                fileName = "patients1"
            case "File 2":
                fileName = "patients2"
            print("set filename to patients2")
            case "File 3":
                fileName = "patients3"
            default:
                fileName = "patients1"
                NSLog(fileRecieve)
        }
        
        singy.addLogToDataString(inputString: "File Used for Experiment: \(fileName)")
        singy.addLogToDataString(inputString: "\n")
        singy.addLogToDataString(inputString: "\n")

        // Read txt file and store its data
        let data = readTXTIntoArray(file: fileName)

        // Assign Labels proper data
        assignLables(txtData: data)

        // Asynchronously show display
        delay(seconds: Double(i))
    }

    func delay(seconds: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: {
            self.enableDisplay()
        })
    }
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func readTXTIntoArray(file: String) -> [String]? {
        // Find file in directory
        guard let path = Bundle.main.path(forResource: fileName, ofType: "txt") else {
            return nil
        }
        do {
            // Grab all data from txt file
            let content = try String(contentsOfFile:path, encoding: String.Encoding.utf8)

            // Filter array
            var contentsFiltered = content.components(separatedBy: ["\n", ",", "\t", "\r"])
            contentsFiltered = contentsFiltered.filter({$0 != ""})
            for _ in 0..<numCols  { contentsFiltered.removeFirst() }

            // Calculate number of rows
            rows = contentsFiltered.count / numCols

            return contentsFiltered
        } catch {
            return nil
        }
    }

    func assignLables(txtData: [String]?) {
        // CSV-TXT Column Data
        let nameCol = 0, roomCol = 1, issueCol = 2, dataCol = 3, arrowCol = 4, delayCol = 5

        // Store data in arrays
        var index = 0
        while(index < (txtData?.count)!) {
            patientNameRoom.append((txtData?[index + nameCol])! + " - " + (txtData?[index + roomCol])!)
            patientIssue.append((txtData?[index + issueCol])!)
            patientData.append((txtData?[index + dataCol])!)
            arrowTxt.append((txtData?[index + arrowCol])!)
            time.append(Int((txtData?[index + delayCol])!)!)

            index += numCols
        }
    }

    //set up the screen with information
    func formatDisplay() {
        let bold = NSMutableAttributedString(string: "Arial Bold (Code)")
        if let arialBoldFont = UIFont(name: "Arial-Bold", size: 35) {
            bold.addAttribute(NSAttributedStringKey.font,value: arialBoldFont, range: NSMakeRange(0, 21))
        }

        NameRoom.setTextColor(UIColor.black)

        underline.setColor(UIColor.black)

        MedicalIssue.setTextColor(UIColor.black)
        MedicalIssue.setAttributedText(bold)

        Data.setTextColor(UIColor.black)
        Data.setAttributedText(bold)

        Et.setTextColor(UIColor.black)
        Et.setAttributedText(bold)

        DirectionArrow.setTextColor(UIColor.black)
        DirectionArrow.setAttributedText(bold)
    }
    

    //event acknowledge button
    @IBOutlet var ackButtonOut: WKInterfaceButton!
    @IBAction func ackButton() {
        
        self.eventLog[self.currentEventNum-1].pressedTime = DispatchTime.now()
        self.eventLog[self.currentEventNum-1].pressedOK = true
        
        self.ackButtonOut.setBackgroundColor(UIColor(hue: 0.2333, saturation: 1, brightness: 0.55, alpha: 1.0) /* #548c00 */)
        
        self.ackButtonOut.setTitle("Acknowledged")
    }
    
    func makeAckButtonRed(){
        self.ackButtonOut.setBackgroundColor(UIColor.red)
        self.ackButtonOut.setTitle("Acknowledge?")
    }
    //for hiding the button
    func makeAckButtonBlack(){
        self.ackButtonOut.setBackgroundColor(UIColor.black)
        self.ackButtonOut.setTitle("")
    }
    
    // Swift 3
    //calcuate the times
    func calcTime()
    {
        print("Evaluating time")
        
        let start = eventLog[currentEventNum-1].startTime // <<<<<<<<<< Start time
        let end = eventLog[currentEventNum-1].endTime // <<<<<<<<<<   end time
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
        let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
        
        print("Num: \(currentEventNum-1) EventType: \(eventLog[currentEventNum-1].eventType). ")
        
        print("Total time for this event: \(timeInterval) seconds")
        
        var timeInterval2 = Double(0) / 1_000_000_000 // Default value

        if(eventLog[currentEventNum-1].pressedOK){
            let start2 = eventLog[currentEventNum-1].startTime // <<<<<<<<<< Start time
            let end2 = eventLog[currentEventNum-1].pressedTime // <<<<<<<<<<   end time
            let nanoTime2 = end2.uptimeNanoseconds - start2.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
            timeInterval2 = Double(nanoTime2) / 1_000_000_000 // Technically could overflow for long running tests
        }
        print("Pressed? \(eventLog[currentEventNum-1].pressedOK) PressTime: \(timeInterval2)")
        
    }
    //calculate and set up log string
    func calcTimeAndLog()
    {
        let singy = Singleton.sharedInstance

        
      //  let start = eventLog[currentEventNum-1].startTime // <<<<<<<<<< Start time
       // let end = eventLog[currentEventNum-1].endTime // <<<<<<<<<<   end time
        //let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
       // let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests

        singy.addLogToDataString(inputString: "Num: \(currentEventNum-1) EventType: \(eventLog[currentEventNum-1].eventType). ")
        singy.addLogToDataString(inputString: "\n")
                singy.addLogToDataString(inputString: "This event started at: \(time[i-1]) seconds")
        //singy.addLogToDataString(inputString: "Total time for this event: \(timeInterval) seconds")
       // singy.addLogToDataString(inputString: "\n")
        singy.addLogToDataString(inputString: "\n")

        var timeInterval2 = Double(0) / 1_000_000_000 // Default value
        
        if(eventLog[currentEventNum-1].pressedOK){
            let start2 = eventLog[currentEventNum-1].startTime // <<<<<<<<<< Start time
            let end2 = eventLog[currentEventNum-1].pressedTime // <<<<<<<<<<   end time
            let nanoTime2 = end2.uptimeNanoseconds - start2.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
            timeInterval2 = Double(nanoTime2) / 1_000_000_000 // Technically could overflow for long running tests
        }
        singy.addLogToDataString(inputString: "Pressed Acknowledge? \(eventLog[currentEventNum-1].pressedOK)")
        singy.addLogToDataString(inputString: "\n")
        singy.addLogToDataString(inputString: "PressTime: \(timeInterval2)")
        singy.addLogToDataString(inputString: "\n")
        singy.addLogToDataString(inputString: "\n")
    }
    
    func handleLogging(event: String ){
        
        if(currentEventNum > 0){
            self.eventLog[currentEventNum-1].endTime = DispatchTime.now()
            calcTimeAndLog()
        }

        //need a default element, we update all its fields
        let defaultElem = eventLogElement(eventType: "blank", startTime: DispatchTime.now(), endTime: DispatchTime.now(), pressedOK: false, pressedTime: DispatchTime.now())
        
        self.eventLog.insert(defaultElem , at: currentEventNum)
        self.eventLog[currentEventNum].eventType = event
        self.eventLog[currentEventNum].startTime = DispatchTime.now()
        currentEventNum = currentEventNum + 1
    }
    
    func enableDisplay() {
        
        var NBPData = [String](), SpO2Data = [String](), CO2Data = [String](), NoEvData = [String]()
        var color = UIColor()
        
        if(i == rows){
            currentPatientIssue = patientIssue[i-1]
        }
        else{currentPatientIssue = patientIssue[i]}
        
        switch(currentPatientIssue) {
            case "NBP":
                makeAckButtonRed()
                NBPData.append(patientData[i])
                color = UIColor.magenta
                handleLogging(event: "NBP")
                print("eventNBP")

            case "SpO2":
                makeAckButtonRed()

                SpO2Data.append(patientData[i])
                color = UIColor.cyan
                print("eventSpO2")

              handleLogging(event: "SPO2")

            case "CO2":
                makeAckButtonRed()

                CO2Data.append(patientData[i])
                color = UIColor.white
                handleLogging(event: "Co2")
                print("eventCo2")
            
            case "NoEv":
                
                makeAckButtonBlack()
            
                if(i == rows){
                    color = UIColor.black
                    print("end")

                }
                else{
                    NoEvData.append(patientData[i])
                    color = UIColor.black
                    handleLogging(event: "NoEv")
                }

            default:
                print("eventDefault")
                print(patientIssue[i])
        }
        if(i != rows){
            displayInterface(interfaceColor: color)
        }
        checkIterator()
    }
 
    func displayInterface(interfaceColor: UIColor) {

        NameRoom.setTextColor(interfaceColor)
        NameRoom.setText(patientNameRoom[i])

        underline.setColor(interfaceColor)

        MedicalIssue.setTextColor(interfaceColor)
        if(currentPatientIssue == "CO2") {
            MedicalIssue.setText("CO2 mm Hg")

            Et.setTextColor(interfaceColor)
            Et.setText("Et")
        } else {
            MedicalIssue.setText(patientIssue[i])
            Et.setTextColor(UIColor.black)
        }
        
        Data.setTextColor(interfaceColor)
        DirectionArrow.setTextColor(interfaceColor)

        //We dont want vibrations or need text for NoEv
        if(currentPatientIssue != "NoEv") {

            Data.setText(patientData[i])
            DirectionArrow.setText(String(UnicodeScalar(Int(arrowTxt[i], radix: 16)!)!))
            vibrationEffect()
        }
    }

    func vibrationEffect() {
        switch(arrowTxt[i]) {
            case "2193":
                WKInterfaceDevice.current().play(.directionDown)
            case "2198":
                WKInterfaceDevice.current().play(.stop)
            case "21CA":
                WKInterfaceDevice.current().play(.notification)
            default:
                print(arrowTxt[i])
        }
    }

    func checkIterator() {
    //Update iterator
       i += 1
 
        if(i==1){
            
            //calculate when next event should start
            let duration = Double(time[i])  - Double(time[i-1])
            // Asynchronously show display
            delay(seconds: duration)
        }
        //last event complete, go back to startview
        else if(i > rows) {
            // Black out screen
            formatDisplay()

            // Change to Start Interface
            let singy = Singleton.sharedInstance
            
            singy.setFalse();
            singy.addAnotherTest();
            singy.isLogAvailable(sendBool: true);
            
            DispatchQueue.main.async {
                self.dismiss()
            }
        }
        //laste event read, wait to change back to startview
        else if(i == rows){
            delay(seconds: 3)

        }
        else{
            // Asynchronously show display
            
           // let duration = Double(time[i]) - Double(time[i - 1])
            let duration = Double(time[i]) - Double(time[i-1])
    
            delay(seconds: duration)
        }
    }

}
