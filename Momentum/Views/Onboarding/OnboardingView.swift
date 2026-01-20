//
//  OnboardingView.swift
//  Momentum
//
//  Created by Henry Bowman on 12/28/25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep: OnboardingStep = .welcome
    @State private var visionText: String = ""

    enum OnboardingStep {
        case welcome
        case visionInput
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            switch currentStep {
            case .welcome:
                WelcomeView(onContinue: { currentStep = .visionInput })
            case .visionInput:
                VisionInputView(
                    visionText: $visionText,
                    onContinue: { completeOnboarding() },
                    onBack: { currentStep = .welcome }
                )
            }
        }
    }

    private func completeOnboarding() {
        // Create a basic goal from the vision text
        let goal = Goal(
            id: UUID(),
            userId: UUID(),
            visionText: visionText.isEmpty ? "My Goal" : visionText,
            visionRefined: visionText.isEmpty ? "My Goal" : visionText,
            goalType: .project,
            isIdentityBased: false,
            status: .active,
            createdAt: Date(),
            targetCompletionDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()),
            currentPowerGoalIndex: 0,
            completionPercentage: 0,
            powerGoals: []
        )

        appState.completeOnboarding(with: goal)
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                VStack(spacing: 12) {
                    Text("Welcome to Momentum")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)

                    Text("Turn your biggest vision into\ntomorrow's first task")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }
}

// MARK: - Vision Input View
struct VisionInputView: View {
    @Binding var visionText: String
    let onContinue: () -> Void
    let onBack: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack {
                Button {
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's your vision?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)

                        Text("What do you want to achieve?")
                            .font(.system(size: 17))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                    // Text Input
                    TextField("Type your vision here...", text: $visionText, axis: .vertical)
                        .font(.system(size: 17))
                        .foregroundColor(.black)
                        .padding()
                        .frame(minHeight: 120, alignment: .topLeading)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .focused($isTextFieldFocused)
                        .padding(.horizontal)

                    // Examples
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Examples:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        VStack(alignment: .leading, spacing: 8) {
                            exampleRow("Start a business")
                            exampleRow("Learn a new skill")
                            exampleRow("Get healthier")
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Continue Button
            Button(action: onContinue) {
                HStack {
                    Text("Continue")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(visionText.count < 3 ? Color.gray : Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(visionText.count < 3)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private func exampleRow(_ text: String) -> some View {
        Button {
            visionText = text
        } label: {
            Text("• \(text)")
                .font(.system(size: 15))
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
