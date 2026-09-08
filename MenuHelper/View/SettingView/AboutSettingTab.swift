//
//  AboutSettingTab.swift
//  MenuHelper
//
//  Created by Kyle on 2021/6/29.
//

import SwiftUI

struct AboutSettingTab: View {
    var body: some View {
        VStack(spacing: 7) {
            Text(appDisplayName)
                .font(.title2.weight(.semibold))
            Text("Unofficial maintenance fork")
                .font(.subheadline)
            Link("MenuHelper — original extension by Kyle-Ye", destination: URL(string: "https://github.com/Kyle-Ye/MenuHelper")!)
            Link("Fork maintained by Byron Delgado", destination: URL(string: "https://github.com/byrondelgado/MacMenuHelper")!)
            Link("Original inspiration: SwiftyMenu by Lex Tang", destination: URL(string: "https://github.com/lexrus/SwiftyMenu")!)
                .font(.caption)
            Text("FSL-1.1-MIT · Copyright 2023-2024 Kyle-Ye")
                .font(.caption)
            Text("Not affiliated with or endorsed by upstream.")
                .font(.caption)
        }
        .padding(12)
    }
}

extension View {
    func glow(color: Color = .red, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
    }

    func rainbowGlow() -> some View {
        ZStack {
            ForEach(0 ..< 2) { i in
                Rectangle()
                    .fill(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center))
                    .frame(width: 80, height: 80)
                    .mask(blur(radius: 8))
                    .overlay(blur(radius: 5 - CGFloat(i * 5)))
            }
        }
    }
}

#Preview {
    AboutSettingTab()
}
