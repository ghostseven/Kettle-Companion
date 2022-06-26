//
//  Settings.swift
//  KettleCompanion
//
//  Created by Blake Drayson on 24/05/2022.
//

import SwiftUI

struct GeneralSettingsView: View {
    @State private var auth: MQTTAuth
    
    @EnvironmentObject private var appState: AppState
    
    init(auth:MQTTAuth){
        _auth = State(initialValue: auth)
    }
    
    var body: some View {
        VStack{
            Form {
                TextField("Client ID", text: $auth.clientID)
                TextField("User Name", text: $auth.user)
                SecureField("Password", text: $auth.password)
            }
            .padding(20)
            .frame(width: 350, height: 110)
            
            Divider()
                .padding(.bottom, 10)
            
            HStack{
                Spacer()
                Button("Cancel"){
                    NSApplication.shared.keyWindow?.close()
                }
                
                Button("Save"){
                    if !auth.clientID.isEmpty && !auth.user.isEmpty && !auth.password.isEmpty {
                        let updAuth = MQTTAuth(clientID: auth.clientID, user: auth.user, password: auth.password)
                        KeychainHelper.standard.save(updAuth, service: "kettlecompanion", account: "token")
                        appState.isConnected = false
                        appState.disconnectCount = 0
                        NSApplication.shared.keyWindow?.close()
                    }

                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

//struct AdvancedSettingsView: View {
//
//    var body: some View {
//        Text("Hello")
//    }
//}

struct SettingsView: View {
    @State private var auth: MQTTAuth
    
    init(auth:MQTTAuth){
        _auth = State(initialValue: auth)
    }
    
    private enum Tabs: Hashable {
        case general, advanced
    }
    
    var body: some View {
        TabView {
            GeneralSettingsView(auth: auth)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
//            AdvancedSettingsView()
//                .tabItem {
//                    Label("Advanced", systemImage: "star")
//                }
//                .tag(Tabs.advanced)
        }
        .padding(20)
        .frame(width: 375, height: 190)
    }
}
