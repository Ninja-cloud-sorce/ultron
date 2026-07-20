import SwiftUI

struct MoodSelector: View {
    @Binding var selectedMood: Mood

    var body: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Text("How are you feeling?")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)

            HStack(spacing: AppTheme.Spacing.m) {
                ForEach(Mood.allCases, id: \.self) { mood in
                    MoodOption(mood: mood, isSelected: selectedMood == mood) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedMood = mood
                        }
                    }
                }
            }
        }
    }
}

private struct MoodOption: View {
    let mood: Mood
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isSelected ? mood.color.opacity(0.25) : AppTheme.Colors.bgElevated)
                        .frame(width: 44, height: 44)
                    Image(systemName: mood.icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? mood.color : AppTheme.Colors.textTertiary)
                }
                .scaleEffect(isSelected ? 1.15 : 1.0)
                .shadow(color: isSelected ? mood.color.opacity(0.5) : .clear, radius: 8)

                Text(mood.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isSelected ? mood.color : AppTheme.Colors.textTertiary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}
