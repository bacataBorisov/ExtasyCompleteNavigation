import SwiftUI

// MARK: - WaypointCard View
struct WaypointCard<Destination: View>: View {
    let title: String
    let subtitle: String? // Optional subtitle
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: NavigationViewWrapper(content: destination)) {
            ZStack {
                Text("Select Waypoint")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        if title.isEmpty, (subtitle ?? "").isEmpty {
            return "Select waypoint"
        }
        return "\(title), \(subtitle ?? "No subtitle")"
    }
}

// MARK: - NavigationViewWrapper

/// A wrapper to ensure consistent navigation bar behavior
struct NavigationViewWrapper<Content: View>: View {
    let content: Content
    
    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline) // Consistent inline mode
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Waypoint List")
                        .font(.headline)
                }
            }
    }
}

// MARK: - Preview

struct WaypointCard_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            VStack(spacing: 16) {
                WaypointCard(
                    title: "Waypoint Example",
                    subtitle: "Subtitle Example",
                    destination: Text("Waypoint List")
                )
            }
            .padding()
            .background(Color(UIColor.systemGray6))
        }
    }
}
