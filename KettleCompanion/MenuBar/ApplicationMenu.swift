//
//  ApplicationMenu.swift
//  KettleCompanion
//
//  Created by Blake Drayson on 06/06/2022.
//

import Foundation
import SwiftUI

class ApplicationMenu: NSObject{
    let menu = NSMenu()
    let appState = AppState.shared
    
    func createMenu() -> NSMenu{
        let kettleView = KettleView()
        let topView = NSHostingController(rootView: kettleView)
        topView.view.frame.size = CGSize(width: 175, height: 150)
        
        let customMenuItem = NSMenuItem()
        customMenuItem.view = topView.view
        menu.addItem(customMenuItem)
        menu.addItem(NSMenuItem.separator())
        
        let settingsMenuItem = NSMenuItem(title: "Settings", action: #selector(settings), keyEquivalent: "")
        settingsMenuItem.target = self
        menu.addItem(settingsMenuItem)
        
        let aboutMenuItem = NSMenuItem(title: "About", action: #selector(about), keyEquivalent: "")
        aboutMenuItem.target = self
        menu.addItem(aboutMenuItem)
        
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)
        return menu
    }
    
    @objc func settings(sender: NSMenuItem){
        NSApp.setActivationPolicy(.regular)
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    @objc func about(sender: NSMenuItem){
        NSApp.setActivationPolicy(.regular)
        NSApp.orderFrontStandardAboutPanel()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    @objc func quit(sender: NSMenuItem){
        NSApp.terminate(self)
    }
}
