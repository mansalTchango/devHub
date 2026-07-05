import SwiftUI

struct PlaceholderView: View {
    let module: Module

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: module.icon)
                .font(.system(size: 64, weight: .light, design: .rounded))
                .foregroundStyle(module.color)

            Text(module.rawValue)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))

            Text("Coming soon")
                .font(.system(.title2, design: .rounded))
                .foregroundStyle(.secondary)

            Text(module.description)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    PlaceholderView(module: .quickActions)
}
