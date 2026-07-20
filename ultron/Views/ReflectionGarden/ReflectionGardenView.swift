import SwiftUI

struct ReflectionGardenView: View {
    @Environment(\.dismiss) private var dismiss
    let categories = ReflectionPrompt.PromptCategory.allCases
    @State private var selectedCategory: ReflectionPrompt.PromptCategory? = nil
    @State private var growIn = false

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Header
                    VStack(spacing: AppTheme.Spacing.s) {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                    .padding(12)
                                    .background(AppTheme.Colors.bgElevated)
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)

                        // Flower illustration
                        ZStack {
                            Image("flower png")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180)
                                .scaleEffect(growIn ? 1.0 : 0.4)
                                .opacity(growIn ? 1.0 : 0)
                                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: growIn)
                        }
                        .frame(height: 160)

                        Text("Reflection Garden")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text("Choose a door to begin your reflection")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.top, 60)

                    // Category grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.m) {
                        ForEach(Array(categories.enumerated()), id: \.element.rawValue) { i, category in
                            ReflectionDoorCard(category: category, index: i) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)

                    Spacer(minLength: 40)
                }
            }
        }
        .hideNavigationBar()
        .onAppear { growIn = true }
        .sheet(item: $selectedCategory) { cat in
            ReflectionDetailView(category: cat)
        }
    }
}

extension ReflectionPrompt.PromptCategory: Identifiable {
    public var id: String { rawValue }
}

struct ReflectionDoorCard: View {
    let category: ReflectionPrompt.PromptCategory
    let index: Int
    let action: () -> Void
    @State private var appeared = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.color).opacity(0.2))
                        .frame(width: 64, height: 64)
                    Image(systemName: category.icon)
                        .font(.system(size: 26))
                        .foregroundColor(Color(hex: category.color))
                }
                VStack(spacing: 4) {
                    Text(category.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("\(ReflectionPrompt.samples.filter { $0.category == category }.count) prompts")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.l)
            .background(AppTheme.Colors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .stroke(Color(hex: category.color).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.07), value: appeared)
        .onAppear { appeared = true }
    }
}

struct ReflectionDetailView: View {
    let category: ReflectionPrompt.PromptCategory
    @Environment(\.dismiss) private var dismiss

    var prompts: [ReflectionPrompt] {
        ReflectionPrompt.samples.filter { $0.category == category }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.bgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.m) {
                        ForEach(prompts) { prompt in
                            PromptCard(prompt: prompt)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(AppTheme.Spacing.m)
                }
            }
            .navigationTitle(category.rawValue)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.Colors.accentGold)
                }
            }
        }
    }
}
