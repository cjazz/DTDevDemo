//
//  mainVC.swift
//  DTDevDemo_Swift
//
//  Created by Adam Chin on 1/6/17
//

import UIKit

class mainVC: UIViewController, DTDeviceDelegate, UITextViewDelegate {
    
    var dtdev :  DTDevices = DTDevices.sharedDevice() as! DTDevices

    @IBOutlet weak var textView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dtdev.delegate = self
        dtdev.connect()
    }
    
    
    @IBAction func reConnect(_ sender: Any) {
        dtdev.connect()
    }
    
    
    @IBAction func disconnect(_ sender: Any) {
        dtdev.disconnect()
    }
    
    @IBAction func headInfo(_ sender: Any) {
        textView.text = "Geadinfo:\n" + msrHeadInfo()
    }
    
    func connectionState(_ state: Int32) {
        
        let info="SDK version: \(dtdev.sdkVersion/100) \nSDK Build Date:\(dtdev.sdkVersion%100) \(DateFormatter.localizedString(from: dtdev.sdkBuildDate, dateStyle: DateFormatter.Style.medium, timeStyle: DateFormatter.Style.none))\n"
        
        print("Build Date: \(dtdev.sdkBuildDate!)")
        print(info)

        if state == CONN_STATES.CONNECTED.rawValue {
            let deviceInfo = String(format: "%@\n%@ %@\nFirmware: %@\nHardware: %@\nSerial: %@\n MSRHead Info: \n%@",info, dtdev.deviceName, dtdev.deviceModel, dtdev.firmwareRevision,dtdev.hardwareRevision, dtdev.serialNumber, msrHeadInfo())
            textView.text = deviceInfo
            //  ALG_PPAD_DUKPT or ALG_EH_IDTECH
            do {
                try dtdev.emsrSetEncryption(ALG_PPAD_DUKPT, params: nil)
            }   catch let error as NSError {
                print("error \(error.code)")
            }
        }
    }
    
    func msrHeadInfo() -> (String){
        var data = ""
        do {
            let msrInfo = try dtdev.emsrGetDeviceInfo()
            let keyInfo = try dtdev.emsrGetKeysInfo()
            data = String(format: "Ident: %@\nFW version: %02d.%02d.%02d\nSN: %@\n", msrInfo.ident, msrInfo.securityVersion/100,msrInfo.securityVersion%100, msrInfo.firmwareVersion/100, msrInfo.serialNumberString)
            
            data += String(format: " AES enc key version: %d\n AES auth key version: %d\n AES load key version: %d\n DUKPT key verion: %d\n TMK key version: %d\n", keyInfo.getKeyVersion(KEY_ENCRYPTION), keyInfo.getKeyVersion(ALG_EH_IDTECH), keyInfo.getKeyVersion(ALG_EH_IDTECH), keyInfo.getKeyVersion(ALG_EH_IDTECH), keyInfo.getKeyVersion(ALG_EH_IDTECH))
        } catch _ as NSError {
            print("error geting head info")
        }
        return data
    }

    func magneticCardEncryptedData(_ encryption: Int32, tracks: Int32, data: Data!) {
        let string1 = String(data: data, encoding: String.Encoding.ascii) ?? "track data could not be read"
        textView.text = textView.text + "Tracks: n\(tracks)\n, Encryption: \(encryption)\n Data: \(string1)"
    }
    
    
    func magneticCardEncryptedData(_ encryption: Int32, tracks: Int32, data: Data!, track1masked: String!, track2masked: String!, track3: String!, source: Int32) {
        let string1 = String(data: data, encoding: String.Encoding.ascii) ?? "data could not be printed"
        print("data: \(string1)")
        print("Track1 masked: \(String(describing: track1masked))")
        print("Track2 masked: \(String(describing: track2masked))")
        print("Track3 masked: \(String(describing: track3))")
        print("Source: \(source)")
        
    }
    
    func magneticCardData(_ track1: String, track2: String, track3: String) {
        let card = dtdev.msExtractFinancialCard(track1, track2: track2)
        var status = ""
        
        if card != nil
        {
            if !((card!.cardholderName.isEmpty)) {
                let string1 = card?.cardholderName
                status += "Name: \(string1!)\n"
            }
            
            //status += "PAN: \(card?.cardholderName.masked(4, end: 4))\n"
            status += "Expires: \(card!.expirationMonth)/\(card!.expirationYear)\n"
            if !((card!.serviceCode.isEmpty)) {
                status += "Service Code: \(card!.serviceCode!)\n"
            }
            if !(card!.discretionaryData.isEmpty) {
                let string2 = card?.discretionaryData
                status += "Discretionary: \(string2!)\n\n"
            }
        }
        
        if !track1.isEmpty {
            status += "Track1: \(track1)\n"
        }
        if !track2.isEmpty {
            status += "Track2: \(track2)\n"
        }
        if !track3.isEmpty {
            status += "Track3: \(track3)\n\n"
        }
        
        let sound: [Int32] = [2730,150,0,30,2730,150];
        
        do {
            try dtdev.playSound(100, beepData: sound, length: Int32(sound.count*4))
        } catch {
        }
        textView.text = status
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

