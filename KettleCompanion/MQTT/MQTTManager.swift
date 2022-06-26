//
//  MQTTManager.swift
//  KettleCompanion
//
//  Created by Blake Drayson on 12/05/2022.
//

import Cocoa
import CocoaMQTT
import SwiftUI

struct MQTTAuth: Codable{
    var clientID: String
    var user: String
    var password: String
}

protocol MQTTManagerDelegate: AnyObject {
    func didGetKettleState(state: String, isBirthCertificateEvent: Bool)
}

class MQTTManager: CocoaMQTTDelegate {
    weak var delegate: MQTTManagerDelegate?
    let appState = AppState.shared
    var mqtt: CocoaMQTT!

    let defaultHost = "WIOTP.stanford-clark.com"

    func disconnectMQTT(){
        mqtt.disconnect()
        mqtt.autoReconnect = false
    }
    
    func connectMQTT(){
        let auth = KeychainHelper.standard.read(service: "kettlecompanion", account: "token", type: MQTTAuth.self) ?? nil
        
        //If we were able to get the login settings from the keychain then we can attempt to log in
        if auth != nil{
            let clientID = auth!.clientID
            mqtt = CocoaMQTT(clientID: clientID, host: defaultHost, port: 1883)
            mqtt.logLevel = .info

            mqtt.username = auth!.user
            mqtt.password = auth!.password
            mqtt.keepAlive = 60
            
            mqtt.autoReconnect = false
            mqtt.disconnect()
            
            mqtt.autoReconnect = true
            mqtt.delegate = self
            appState.isConnected = mqtt.connect()
        }else{
            
            if appState.disconnectCount < 10 {
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            appState.disconnectCount = 10
            appState.isConnected = false
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if ack == .accept {
            appState.disconnectCount = 0
            mqtt.subscribe("iot-2/cmd/command/fmt/text")
            //Set isBirthCertEvent to true so when we publish this message the system knows that we have requested the even and we should only approximate the time.
            appState.isBirthCertEvent = true
            //lets get the last message that the kettle generated, we can do this by sending a birth certificate message (of any value) to the following mqtt topic.
            mqtt.publish("iot-2/evt/status/fmt/text", withString: "ok")
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        delegate?.didGetKettleState(state: message.string!, isBirthCertificateEvent: appState.isBirthCertEvent)
        appState.isBirthCertEvent = false
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        if appState.disconnectCount > 6 {
            //We have disconnected 6 times lets pop the preferences window and stop incrementing.
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        } else {
            //Update the disconnect count.
            appState.disconnectCount += 1
        }
        appState.isConnected = false
    }
}
