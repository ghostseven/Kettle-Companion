//
//  KettleCompanionApp.swift
//  KettleCompanion
//
//  Created by Blake Drayson on 11/05/2022.
//

import SwiftUI

class AppState: ObservableObject{
    public static let shared = AppState()
    @Published var disconnectCount = 0 //Used as a counter for disconnections we respond at different levels.
    @Published var isConnected = false //Indicated connection state.
    @Published var isBirthCertEvent = false //Is this a birth certificate message, we do different things if it is.
    @Published var shortStatusString = "Unknown" //Long status string
    @Published var longStatusString = "Not Known" //Short status string
    @Published var activeHexColor = "#0000ff" //The current active hex colour as sent by the backend.
    @Published var alphaValue = 0.0 //Calculated alpha value, used to display green colour gradient.
}

@main
struct KettleCompanionApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let persistenceController = PersistenceController.shared
    let appState = AppState.shared
    
    var body: some Scene {
        Settings {
            SettingsView(auth: KeychainHelper.standard.read(service: "kettlecompanion", account: "token", type: MQTTAuth.self) ?? MQTTAuth(clientID: "", user: "", password: ""))
                .environmentObject(self.appState)
        }
    }
}

extension NSColor {
     convenience init(hex: String) {
        let trimHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let dropHash = String(trimHex.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        let hexString = trimHex.starts(with: "#") ? dropHash : trimHex
        let ui64 = UInt64(hexString, radix: 16)
        let value = ui64 != nil ? Int(ui64!) : 0
        // #RRGGBB
        var components = (
            R: CGFloat((value >> 16) & 0xff) / 255,
            G: CGFloat((value >> 08) & 0xff) / 255,
            B: CGFloat((value >> 00) & 0xff) / 255,
            a: CGFloat(1)
        )
        if String(hexString).count == 8 {
            // #RRGGBBAA
            components = (
                R: CGFloat((value >> 24) & 0xff) / 255,
                G: CGFloat((value >> 16) & 0xff) / 255,
                B: CGFloat((value >> 08) & 0xff) / 255,
                a: CGFloat((value >> 00) & 0xff) / 255
            )
        }
        self.init(red: components.R, green: components.G, blue: components.B, alpha: components.a)
     }

    func toHex(alpha: Bool = false) -> String? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if alpha {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
