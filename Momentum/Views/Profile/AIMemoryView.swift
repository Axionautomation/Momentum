//
//  AIMemoryView.swift
//  Momentum
//
//  Created by Henry Bowman on 2/8/26.
//

import SwiftUI
import PhosphorSwift

struct AIMemoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var appeared = false
    @State private var showClearAllConfirmation = false

    private var groupedEntries: [(MemoryCategory, [AIMemoryEntry])] {
        let grouped = Dictionary(grouping: appState.aiMemoryEntries) { $0.category }
        return MemoryCategory.allCases.compactMap { category in
            guard let entries = grouped[category], !entries.isEmpty else { return nil }
            return (category, entries.sorted { $0.updatedAt > $1.updatedAt })
        }
    }

    var body: some View {
        ZStack {
            Color.momentumBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: MomentumSpacing.section) {
                    // Explanation card
                    AIMemoryExplanationCard()
                        .padding(.horizontal, MomentumSpacing.comfortable)
                        .padding(.top, MomentumSpacing.standard)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)

                    if appState.aiMemoryEntries.isEmpty {
                        // Empty state
                        VStack(spacing: MomentumSpacing.standard) {
                            Ph.brain.regular
                                .frame(width: 48, height: 48)
                                .foregroundColor(.momentumTextTertiary)

                            Text("No memories yet")
                                .font(MomentumFont.headingMedium())
                                .foregroundColor(.momentumTextSecondary)

                            Text("As you interact with AI, it will learn about your preferences, skills, and patterns.")
                                .font(MomentumFont.body())
                                .foregroundColor(.momentumTextTertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, MomentumSpacing.large)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                        .offset(y: appeared ? 0 : 30)
                        .opacity(appeared ? 1 : 0)
                    } else {
                        // Grouped list
                        ForEach(Array(groupedEntries.enumerated()), id: \.element.0) { sectionIndex, group in
                            let (category, entries) = group

                            VStack(alignment: .leading, spacing: MomentumSpacing.compact) {
                                // Section header
                                HStack(spacing: MomentumSpacing.tight) {
                                    Image(systemName: categoryIcon(for: category))
                                        .font(.system(size: 14))
                                        .foregroundColor(categoryColor(for: category))

                                    Text(category.displayName)
                                        .font(MomentumFont.label())
                                        .foregroundColor(.momentumTextSecondary)

                                    Text("\(entries.count)")
                                        .font(MomentumFont.caption(11))
                                        .foregroundColor(.momentumTextTertiary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(Color.momentumSurface)
                                        )
                                }
                                .padding(.horizontal, MomentumSpacing.comfortable)

                                // Entries
                                VStack(spacing: MomentumSpacing.tight) {
                                    ForEach(entries) { entry in
                                        AIMemoryEntryRow(
                                            entry: entry,
                                            categoryColor: categoryColor(for: category),
                                            onDelete: {
                                                withAnimation(MomentumAnimation.snappy) {
                                                    appState.deleteMemoryEntry(entry)
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, MomentumSpacing.comfortable)
                            }
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(MomentumAnimation.staggered(index: sectionIndex + 1), value: appeared)
                        }

                        // Clear all button
                        Button {
                            showClearAllConfirmation = true
                        } label: {
                            HStack(spacing: MomentumSpacing.tight) {
                                Ph.trash.regular
                                    .frame(width: 16, height: 16)
                                Text("Clear All Memories")
                                    .font(MomentumFont.label())
                            }
                            .foregroundColor(.momentumDanger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MomentumSpacing.compact)
                        }
                        .padding(.horizontal, MomentumSpacing.comfortable)
                        .padding(.top, MomentumSpacing.tight)
                    }

                    Spacer(minLength: 100)
                }
            }
        }
        .navigationTitle("AI Memory")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            withAnimation(MomentumAnimation.smoothSpring.delay(0.1)) {
                appeared = true
            }
        }
        .alert("Clear All Memories", isPresented: $showClearAllConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                withAnimation(MomentumAnimation.snappy) {
                    appState.clearAllMemoryEntries()
                }
            }
        } message: {
            Text("This will permanently delete all AI memory entries. The AI will need to relearn your preferences.")
        }
    }

    private func categoryIcon(for category: MemoryCategory) -> String {
        switch category {
        case .skill: return "hammer.fill"
        case .preference: return "slider.horizontal.3"
        case .decision: return "arrow.triangle.branch"
        case .research: return "magnifyingglass"
        case .pattern: return "chart.line.uptrend.xyaxis"
        case .personal: return "person.fill"
        }
    }

    private func categoryColor(for category: MemoryCategory) -> Color {
        switch category {
        case .skill: return .momentumBlue
        case .preference: return .momentumViolet
        case .decision: return .momentumWarning
        case .research: return .momentumBlueLight
        case .pattern: return .momentumSuccess
        case .personal: return .momentumCoral
        }
    }
}

// MARK: - Explanation Card

struct AIMemoryExplanationCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: MomentumSpacing.compact) {
            Ph.info.fill
                .frame(width: 20, height: 20)
                .foregroundColor(.momentumBlue)

            VStack(alignment: .leading, spacing: MomentumSpacing.micro) {
                Text("What does AI know about me?")
                    .font(MomentumFont.bodyMedium())
                    .foregroundColor(.momentumTextPrimary)

                Text("Momentum's AI remembers your skills, preferences, and decisions to give you better recommendations. You can review and delete any memory here.")
                    .font(MomentumFont.caption())
                    .foregroundColor(.momentumTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(MomentumSpacing.standard)
        .background(Color.momentumBlue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: MomentumRadius.medium)
                .strokeBorder(Color.momentumBlue.opacity(0.2), lineWidth: 0.5)
        )
    }
}

// MARK: - Memory Entry Row

struct AIMemoryEntryRow: View {
    let entry: AIMemoryEntry
    let categoryColor: Color
    let onDelete: () -> Void

    private var dateText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: entry.updatedAt, relativeTo: Date())
    }

    var body: some View {
        HStack(alignment: .top, spacing: MomentumSpacing.compact) {
            // Color accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(categoryColor)
                .frame(width: 3, height: 40)

            VStack(alignment: .leading, spacing: MomentumSpacing.micro) {
                Text(entry.key)
                    .font(MomentumFont.bodyMedium())
                    .foregroundColor(.momentumTextPrimary)

                Text(entry.value)
                    .font(MomentumFont.caption())
                    .foregroundColor(.momentumTextSecondary)
                    .lineLimit(2)

                HStack(spacing: MomentumSpacing.tight) {
                    Text(entry.source)
                        .font(MomentumFont.caption(10))
                        .foregroundColor(.momentumTextTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.momentumSurface)
                        )

                    Text(dateText)
                        .font(MomentumFont.caption(10))
                        .foregroundColor(.momentumTextTertiary)
                }
            }

            Spacer()

            // Delete button
            Button(action: onDelete) {
                Ph.x.regular
                    .frame(width: 14, height: 14)
                    .foregroundColor(.momentumTextTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(MomentumSpacing.compact)
        .background(Color.momentumBackgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: MomentumRadius.small))
        .overlay(
            RoundedRectangle(cornerRadius: MomentumRadius.small)
                .strokeBorder(Color.momentumCardBorder, lineWidth: 0.5)
        )
    }
}

#Preview {
    NavigationStack {
        AIMemoryView()
            .environmentObject(AppState())
    }
    .preferredColorScheme(.dark)
}
