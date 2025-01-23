import SwiftUI

struct iPhoneDisplayCell: View {
    
    // MARK: - Constants for Styling
    private let alarmGradient = EllipticalGradient(colors: [Color(UIColor.systemRed), Color(UIColor.systemPink), Color(UIColor.systemBackground)])
    private let nonAlarmGradient = EllipticalGradient(colors: [Color(UIColor.systemBackground), Color(UIColor.systemBackground)])
    
    // MARK: - Properties
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(SettingsManager.self) private var settingsManager
    
    var cell: MultiDisplayCells
    var valueID: Int
    var fontMultiplier: CGFloat = 1.0
    
    // MARK: - State
    @State private var displayedValue: Double = 0 // Tracks the animated value
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                alarmBackground()
                
                VStack(spacing: 0) {
                    // Top Row: Label (leading) and Unit (trailing)
                    HStack {
                        Text(cell.name)
                            .font(Font.custom("AppleSDGothicNeo-Bold", size: min(width, height) * 0.15 * fontMultiplier))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(getUnit())
                            .font(Font.custom("AppleSDGothicNeo-Bold", size: min(width, height) * 0.15 * fontMultiplier))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding([.leading, .trailing, .top], 4)
                    
                    Spacer()
                    
                    // Center: Value (center-aligned)
                    Text(String(format: cell.specifier, displayedValue))
                        .font(Font.custom("Futura-CondensedExtraBold", size: min(width, height) * 0.6 * fontMultiplier))
                        .lineLimit(1)
                        .minimumScaleFactor(0.45)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    
                    Spacer()
                }
                .foregroundStyle(Color("display_font"))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // Set the initial value when the view appears
            if let initialValue = navigationReadings.displayValue(a: valueID) {
                displayedValue = initialValue
            }
        }
        .onChange(of: navigationReadings.displayValue(a: valueID)) { _, newValue in
            guard let newValue = newValue else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                displayedValue = newValue
            }
        }
    }
    
    // MARK: - Helper Methods
    private func alarmBackground() -> some View {
        (cell.id == 0 && triggerAlarm()) ? alarmGradient : nonAlarmGradient
    }
    
    private func triggerAlarm() -> Bool {
        guard let value = navigationReadings.hydroData?.depth else { return false }
        return value < 3
    }
    
    private func getUnit() -> String {
        settingsManager.metricWind && cell.valueHasMetric ? cell.metric : cell.units
    }
}

#Preview {
    iPhoneDisplayCell(cell: displayCell[1], valueID: 1, fontMultiplier: 1)
        .environment(NMEAParser())
        .environment(SettingsManager())
        .modelContainer(for: [Matrix.self])
}
