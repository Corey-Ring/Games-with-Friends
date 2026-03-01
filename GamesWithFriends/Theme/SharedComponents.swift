import SwiftUI

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .font(AppTheme.Typography.buttonLabel)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppTheme.brandOrange)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .pressable()
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .font(AppTheme.Typography.buttonLabel)
            .foregroundColor(AppTheme.brandOrange)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppTheme.brandOrange, lineWidth: 1.5)
            )
        }
        .pressable()
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    let title: String
    var icon: String? = nil
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(AppTheme.Typography.pillLabel)
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(isSelected ? color : color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
        }
        .pressable()
    }
}
