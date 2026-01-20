//
//  GlobalAIChatView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/31/25.
//

import SwiftUI

struct GlobalAIChatView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()

                Text("Page Under Construction")
                    .font(.system(size: 17))
                    .foregroundColor(.gray)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

#Preview {
    GlobalAIChatView()
}
