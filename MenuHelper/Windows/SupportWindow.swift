//
//  SupportWindow.swift
//  MenuHelper
//
//  Created by Kyle on 2022/2/13.
//

import Foundation
import SwiftUI

struct SupportWindow: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Original extension by Kyle-Ye")
                .font(.title2)
            Text("Finder Menu Tools is an unofficial maintenance fork of MenuHelper. Credit for the original extension belongs to Kyle-Ye.")
                .multilineTextAlignment(.center)
            Link("Visit Kyle-Ye's MenuHelper repository", destination: URL(string: "https://github.com/Kyle-Ye/MenuHelper")!)
            Text("This fork is distributed without charge and has no in-app purchases.")
                .font(.footnote)
        }
        .padding(32)
    }
}

struct SupportWindow_Previews: PreviewProvider {
    static var previews: some View {
        SupportWindow()
    }
}
