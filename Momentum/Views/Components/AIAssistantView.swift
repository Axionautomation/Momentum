//
//  AIAssistantView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/29/25.
//

import SwiftUI

struct AIAssistantView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.momentumBackground
                    .ignoresSafeArea()

                Text("Page Under Construction")
                    .font(.system(size: 17))
                    .foregroundColor(.momentumTextSecondary)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.momentumBlue)
                }
            }
        }
    }
}

#Preview {
    AIAssistantView()
        .preferredColorScheme(.dark)
}
