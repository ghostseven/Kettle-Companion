//
//  AppDelegate.swift
//  KettleCompanion
//
//  Created by Blake Drayson on 12/05/2022.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, MQTTManagerDelegate{
    static private(set) var instance: AppDelegate!
    lazy var statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let menu = ApplicationMenu()
        
    var isBirthCertEvent: Bool = false
    var latestState: String?
    var latestTimeStamp: Date?
    
    weak var kettleState: MQTTManagerDelegate?
    
    let mqtt = MQTTManager()
    let persistenceController = PersistenceController.shared
    let appState = AppState.shared
    var timer = Timer()

    private var aboutBoxWindowController: NSWindowController?

    func showAboutPanel() {
        if aboutBoxWindowController == nil {
            let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable,/* .resizable,*/ .titled]
            let window = NSWindow()
            window.styleMask = styleMask
            window.title = "About My App"
            window.contentView = NSHostingView(rootView: About())
            aboutBoxWindowController = NSWindowController(window: window)
        }

        aboutBoxWindowController?.showWindow(aboutBoxWindowController?.window)
    }
    
    func getLastSavedEvent() -> KettleEvent? {
        let fetchRequest: NSFetchRequest<KettleEvent>
        fetchRequest = KettleEvent.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        //Get a reference to a NSMangedObjectContext
        let context = persistenceController.container.viewContext
        
        return try? context.fetch(fetchRequest).first
    }
    
    func saveEvent(state: String){
        //Originally we were checking that if the last saved event was the same as the current we would not save
        //however now we are not longer saving birth cert messages we need to make sure we save all pushed events as we
        //may have had a long outage between the app being open. We could have events that are the same in hex value
        //but have a wide gap in timestamp and this will produce incorrect results.
        let kEvent = KettleEvent(context: persistenceController.container.viewContext)
        kEvent.id = UUID()
        kEvent.timestamp = Date()
        kEvent.hexcolor = state

        try? persistenceController.container.viewContext.save()
    }
    
    
    func didGetKettleState(state: String, isBirthCertificateEvent: Bool) {
        isBirthCertEvent = isBirthCertificateEvent
        latestState = state
        
        //If we have recvied particular messages from the backend we can use these as reference points to back calculate the event timestamp.
        //For example if we have recived the event that states the kettle was boiled two hours ago we can take the current time and deduct two hours
        //and them save this as the timestamp.  This allows us to perfom sanity checking on our internal time keeping.
        //Please note if this is a birth certificate message we will not make these calculations (unless we have validated them against previous saved events).
        let _latestState = latestState!.lowercased()
        appState.activeHexColor = _latestState
        if (isBirthCertificateEvent == false){
            switch _latestState {
            case "#008000":
                latestTimeStamp = Calendar.current.date(byAdding: .hour, value: -2, to: Date()) //2 hours ago
            case "#004000":
                latestTimeStamp = Calendar.current.date(byAdding: .hour, value: -4, to: Date()) //4 hours ago
            case "#002000":
                latestTimeStamp = Calendar.current.date(byAdding: .hour, value: -6, to: Date()) //6 hours ago
            default:
                latestTimeStamp = Date()
            }
        }else{
            let lastEvent = getLastSavedEvent()
            latestTimeStamp = Date()
            if (lastEvent != nil) {
                let _savedState = lastEvent!.hexcolor.lowercased()
                switch _latestState{
                case "#00ff00", "#008000", "#004000", "#002000":
                    if ( _savedState == _latestState && lastEvent!.timestamp >= Calendar.current.date(byAdding: .hour, value: -2, to: Date())! ){
                        //Saved event matches and is in the last two hours, likely this is correct so update timestamp to saved event time and
                        //set isBirthCert to false
                        
                        switch _latestState {
                        case "#008000":
                            latestTimeStamp = lastEvent!.timestamp.addingTimeInterval(-((60 * 60) * 2)) //2 hours ago
                        case "#004000":
                            latestTimeStamp = lastEvent!.timestamp.addingTimeInterval(-((60 * 60) * 4)) //4 hours ago
                        case "#002000":
                            latestTimeStamp = lastEvent!.timestamp.addingTimeInterval(-((60 * 60) * 6)) //6 hours ago
                        default:
                            latestTimeStamp = lastEvent!.timestamp
                        }
                        
                        isBirthCertEvent = false
                    } else { latestTimeStamp = Date() }
                default:
                    latestTimeStamp = Date()
                }
            } else
            {
                latestTimeStamp = Date()
            }
        }
        
        //Only save state when messages are pushed as this is the only way the saved timestamps will be accurate, never save birth cert events.
        if (!isBirthCertificateEvent){
            saveEvent(state: state)
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        mqtt.delegate = self
        
        AppDelegate.instance = self
        statusBarItem.button?.image = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: nil)
        statusBarItem.button?.imagePosition = NSControl.ImagePosition.imageLeading
        statusBarItem.menu = menu.createMenu()
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in self.updateStatusText()})
    }
    
    func updateStatusText(){
        //var statusText: String = "Unknown"

        if appState.isConnected{
            //We have just opened the app or just reconnected after an outage and have sent a birth certificate.
            //We need to be aware that the time the latest status message was sent is not going to be accurate
            //to when it was generated so we can only approximate the last boil time.

            statusBarItem.button?.image = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: nil)
            statusBarItem.button?.imagePosition  = NSControl.ImagePosition.imageLeading
            
            let calendar = Calendar.current
            let dateDiff = calendar.dateComponents([.hour, .minute], from: (latestTimeStamp ?? Date()), to: Date())

            //Each event state will have a detailed or approximate response. A detailed response will occur when we are sure an event has been triggered by
            //the client boiling a kettle (or a system status update), in this state we can take the time the event came in as a detailed time stamp and back
            //calculate a close boil time. However an approximate response will occur if we have just sent a birth certificate message, in this scenario we
            //cannot trust the times stamp as we have forced an event update.

            //This takes a state (a hex code) and returns a status text.
            if latestState != nil{
                switch latestState!.lowercased(){
                case "#007108": //Boiling now!
                    appState.shortStatusString = "Boiling!!" //Regardless of detailed or approx this will always be the correct state to send
                    appState.longStatusString = "Kettle Is Boiling!"
                    appState.alphaValue = 1
                case "#0000ff": // Overnight resting status
                    appState.shortStatusString = "Resting" //Regardless of detailed or approx this will always be the correct state to send
                    appState.longStatusString  = "Kettle Is Resting"
                    //better loooking hex value for app
                    appState.activeHexColor = "#0b2a92"
                    appState.alphaValue = 0.8
                case "#ff0000": // Not boiled, red warning
                    appState.shortStatusString = "Not Boiled By 10am!" //Regardless of detailed or approx this will always be the correct state to send
                    appState.longStatusString  = "Not Boiled By 10am!"
                    //better loooking hex value for app
                    appState.activeHexColor = "#f5625d"
                    appState.alphaValue = 1
                case "#00ff00":
                    if(isBirthCertEvent){
                        appState.shortStatusString = "Recently"
                        appState.longStatusString  = "Boiled Recently"
                        appState.alphaValue = 1.0
                    }else{
                        appState.shortStatusString = dateComponentsAsString(date: dateDiff, style: .short)
                        appState.longStatusString = dateComponentsAsString(date: dateDiff, style: .full)
                        appState.alphaValue = minsToAlpha(mins: dateDiff.minute! + (dateDiff.hour! * 60))
                    }
                case "#008000":
                    if(isBirthCertEvent){
                        appState.shortStatusString = "2-4 Hours"
                        appState.longStatusString  = "Boiled 2 to 4 Hours Ago"
                        appState.alphaValue = 0.8
                    }else{
                        appState.shortStatusString = dateComponentsAsString(date: dateDiff, style: .short)
                        appState.longStatusString = dateComponentsAsString(date: dateDiff, style: .full)
                        appState.alphaValue = minsToAlpha(mins: dateDiff.minute! + (dateDiff.hour! * 60))
                    }
                case "#004000":
                    if(isBirthCertEvent){
                        appState.shortStatusString = "4-6 Hours"
                        appState.longStatusString  = "Boiled 4 to 6 Hours Ago"
                        appState.alphaValue = 0.6
                    }else{
                        appState.shortStatusString = dateComponentsAsString(date: dateDiff, style: .short)
                        appState.longStatusString = dateComponentsAsString(date: dateDiff, style: .full)
                        appState.alphaValue = minsToAlpha(mins: dateDiff.minute! + (dateDiff.hour! * 60))
                    }
                case "#002000":
                    if(isBirthCertEvent){
                        appState.shortStatusString = "6-8 Hours"
                        appState.longStatusString  = "Boiled 6 to 8 Hours Ago"
                        appState.alphaValue = 0.4
                    }else{
                        appState.shortStatusString = dateComponentsAsString(date: dateDiff, style: .short)
                        appState.longStatusString = dateComponentsAsString(date: dateDiff, style: .full)
                        appState.alphaValue = minsToAlpha(mins: dateDiff.minute! + (dateDiff.hour! * 60))
                    }
                case "#001000":
                    appState.shortStatusString = ">8 Hours"
                    appState.longStatusString  = "Boiled Over 8 Hours Ago"
                    appState.alphaValue = 0.2
                default:
                    appState.shortStatusString = "Unknown"
                    appState.longStatusString = "Not Known"
                    appState.alphaValue = 1.0
                }
            }

        } else{
            statusBarItem.button?.image = NSImage(systemSymbolName: "cup.and.saucer", accessibilityDescription: nil)
            statusBarItem.button?.imagePosition = NSControl.ImagePosition.imageLeft
            if appState.disconnectCount == 10 {
                //If we have 10 attempted login counts this is a short hand for indicating that there are not saved login credentials.
                appState.shortStatusString = "No Credentials"
                mqtt.disconnectMQTT()
            }else {
                if appState.disconnectCount > 6 {
                    //If we are here we have failed to login with provided credentials six times.
                    appState.shortStatusString = "Login Failed"
                    mqtt.disconnectMQTT()
                } else {
                    //If we are here we are trying to log in
                    appState.shortStatusString = "Trying To Connect..."
                    mqtt.connectMQTT()
                }
            }
        }
        statusBarItem.button?.title = appState.shortStatusString
    }
    
    func dateComponentsAsString(date: DateComponents, style: DateComponentsFormatter.UnitsStyle) -> String {
      let formatter = DateComponentsFormatter()
      formatter.allowedUnits = [.hour, .minute]
      formatter.unitsStyle = style
      return formatter.string(from: date) ?? ""
        //.positional 2:46
        //.abbreviated 2h 46m
        //.short 2 hr, 46 min
        //.full 2 hours, 46 minutes
    }
    
    func minsToAlpha(mins: Int) -> CGFloat{
        //Little calculation based on minutes since boil to give a smoother gradient of colour for the kettle image.
        //Will present a value between 1 and 0 in 0.05 increments.
        let alpha = 1 - (floor(Double(mins) / 30.0) * 0.05)
        return floor(alpha * 10) / 10.0
    }
}
