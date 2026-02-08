//
//  ProgressView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI

struct MomentumProgressView: View {
    var body: some View {
        ZStack {
            Color.momentumBackground
                .ignoresSafeArea()

            Text("Page Under Construction")
                .font(.system(size: 17))
                .foregroundColor(.momentumTextSecondary)
        }
    }
}

#Preview {
    MomentumProgressView()
        .preferredColorScheme(.dark)
}
