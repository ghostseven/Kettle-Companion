//
//  ContentView.swift
//  KettleCompanion
//
//  Created by Blake Drayson on 11/05/2022.
//

import SwiftUI
import CoreData

struct KettleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var appState = AppState.shared
    @State private var animateGradient = false
    
    var body: some View {
        VStack(alignment: .leading){
            let colourBase = NSColor(hex: appState.activeHexColor)
            let isHiddenAnim = appState.activeHexColor == "#007108" ? false : true
            
            HStack{
                Spacer()
                Text("Kettle Companion")
                    .bold()
                Spacer()
            }
            HStack{
                Spacer()
                
                ZStack{
                    Image("KettleAppIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color(nsColor: NSColor(hue: colourBase.hueComponent, saturation: colourBase.saturationComponent, brightness: colourBase.brightnessComponent, alpha: appState.alphaValue)))
                    LinearGradient(colors: [.red, .purple, .blue], startPoint: animateGradient ? .topLeading : .bottomLeading, endPoint: animateGradient ? .bottomTrailing : .topTrailing)
                        .ignoresSafeArea()
                        .mask(Image("KettleAppIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                              )
                        .onAppear {
                            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: true)) {
                                animateGradient.toggle()
                            }
                        }
                        .opacity(isHiddenAnim ? 0 : 1)
                    Image("KettleOutline")
                        .resizable()
                        .aspectRatio(contentMode: .fit)

                }
                .frame(width: 80)
                Spacer()
            }
            HStack{
                Spacer()
                Text(appState.longStatusString)
                Spacer()
            }
        }
    }
    
    private func boilAnim(){
        
    }
}
