//
//  MindsetView.swift
//  Momentum
//
//  Created by Henry Bowman on 1/20/26.
//

import SwiftUI
import PhosphorSwift

struct MindsetView: View {
    @EnvironmentObject var appState: AppState
    @State private var appeared = false

    // Sample quotes - in production, these would come from a service
    private let quotes = [
        Quote(text: "The secret of getting ahead is getting started.", author: "Mark Twain"),
        Quote(text: "It does not matter how slowly you go as long as you do not stop.", author: "Confucius"),
        Quote(text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill"),
        Quote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs"),
        Quote(text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt")
    ]

    private var todaysQuote: Quote {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return quotes[dayOfYear % quotes.count]
    }

    var body: some View {
        ZStack {
            Color.momentumBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: MomentumSpacing.section) {
                    // Header
                    VStack(alignment: .leading, spacing: MomentumSpacing.tight) {
                        Text("Mindset")
                            .font(MomentumFont.headingLarge())
                            .foregroundColor(.momentumTextPrimary)

                        Text("Stay motivated and focused")
                            .font(MomentumFont.body())
                            .foregroundColor(.momentumTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, MomentumSpacing.comfortable)
                    .padding(.top, MomentumSpacing.standard)

                    // Daily Quote Card
                    QuoteCard(quote: todaysQuote)
                        .padding(.horizontal, MomentumSpacing.comfortable)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)

                    // Why You Started Card
                    if let goal = appState.activeProjectGoal {
                        WhyYouStartedCard(vision: goal.visionRefined ?? goal.visionText)
                            .padding(.horizontal, MomentumSpacing.comfortable)
                            .offset(y: appeared ? 0 : 30)
                            .opacity(appeared ? 1 : 0)
                    }

                    // Affirmations Section
                    AffirmationsCard()
                        .padding(.horizontal, MomentumSpacing.comfortable)
                        .offset(y: appeared ? 0 : 40)
                        .opacity(appeared ? 1 : 0)

                    // Bottom spacing for tab bar
                    Spacer(minLength: 100)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Quote Model

struct Quote {
    let text: String
    let author: String
}

// MARK: - Quote Card

struct QuoteCard: View {
    let quote: Quote

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            HStack {
                Ph.quotes.fill
                    .frame(width: 28, height: 28)
                    .foregroundColor(.momentumBlue)

                Spacer()

                Text("Daily Quote")
                    .font(MomentumFont.label())
                    .foregroundColor(.momentumTextSecondary)
            }

            Text("\"\(quote.text)\"")
                .font(MomentumFont.body(18))
                .foregroundColor(.momentumTextPrimary)
                .italic()

            Text("- \(quote.author)")
                .font(MomentumFont.label())
                .foregroundColor(.momentumTextSecondary)
        }
        .padding(MomentumSpacing.standard)
        .background(
            LinearGradient(
                colors: [Color.momentumBlue.opacity(0.05), Color.momentumBlue.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .momentumCard()
    }
}

// MARK: - Why You Started Card

struct WhyYouStartedCard: View {
    let vision: String

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            HStack {
                Ph.lightbulb.fill
                    .frame(width: 24, height: 24)
                    .foregroundColor(.momentumWarning)

                Text("Why You Started")
                    .font(MomentumFont.headingMedium())
                    .foregroundColor(.momentumTextPrimary)

                Spacer()
            }

            Text(vision)
                .font(MomentumFont.body())
                .foregroundColor(.momentumTextSecondary)
                .lineLimit(4)

            Text("Remember this when things get hard.")
                .font(MomentumFont.caption())
                .foregroundColor(.momentumTextTertiary)
                .italic()
        }
        .padding(MomentumSpacing.standard)
        .momentumCard()
    }
}

// MARK: - Affirmations Card

struct AffirmationsCard: View {
    private let affirmations = [
        "I am capable of achieving my goals",
        "Every small step brings me closer",
        "I choose progress over perfection",
        "I am committed to my growth"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: MomentumSpacing.standard) {
            HStack {
                Ph.heartStraight.fill
                    .frame(width: 24, height: 24)
                    .foregroundColor(.momentumSuccess)

                Text("Daily Affirmations")
                    .font(MomentumFont.headingMedium())
                    .foregroundColor(.momentumTextPrimary)

                Spacer()
            }

            VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
                ForEach(affirmations, id: \.self) { affirmation in
                    HStack(spacing: MomentumSpacing.tight) {
                        Ph.check.regular
                            .frame(width: 16, height: 16)
                            .foregroundColor(.momentumSuccess)

                        Text(affirmation)
                            .font(MomentumFont.body())
                            .foregroundColor(.momentumTextPrimary)
                    }
                }
            }
        }
        .padding(MomentumSpacing.standard)
        .momentumCard()
    }
}

#Preview {
    MindsetView()
        .environmentObject(AppState())
}
