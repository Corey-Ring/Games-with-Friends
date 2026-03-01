import SwiftUI

struct SkeletonLoadingModifier: ViewModifier {
    @State private var shimmerOffset: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: shimmerOffset * geometry.size.width)
                    .clipped()
                }
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        shimmerOffset = 2
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }
}

extension View {
    func skeletonLoading() -> some View {
        modifier(SkeletonLoadingModifier())
    }
}
