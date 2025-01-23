import SwiftUI

// MARK: - WaypointCard View
struct WaypointCard<Destination: View>: View {
    let title: String
    let subtitle: String? // Optional subtitle
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: NavigationViewWrapper(content: destination)) {
            ZStack {
                // Background with subtle gradients
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green.opacity(0.3), Color.teal.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                
                Text("Select Waypoint")
                    .font(.body)
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(8)
                    .foregroundColor(Color.green)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Set a fixed minimum height
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle ?? "No subtitle")")
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
