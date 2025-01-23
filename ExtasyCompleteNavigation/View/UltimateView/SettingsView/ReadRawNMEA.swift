import SwiftUI

struct ReadRawNMEA: View {
    @Environment(NMEAParser.self) private var navigationReadings
    @Environment(\.dismiss) private var dismiss  // Inject dismiss environment

    @State private var selectedCategory: String = "GPS"
    @State private var filterStrength: Double = 1.0
    @State private var scrollProxy: ScrollViewProxy?

    private let categories = ["GPS", "Hydro", "Wind", "Compass"]

    var filteredData: [String] {
        Array(Set(navigationReadings.latestRawData)).filter { nmea in
            switch selectedCategory {
            case "GPS":
                return nmea.contains("GPRMC") || nmea.contains("GPGGA")
            case "Hydro":
                return nmea.contains("DPT") || nmea.contains("VHW")
            case "Wind":
                return nmea.contains("MWV")
            case "Compass":
                return nmea.contains("HDG")
            default:
                return true
            }
        }.sorted()
    }

    var body: some View {
        VStack {
            // Title
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .padding()
            }
            Text("NMEA 0183 Data")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.teal)
                .padding(.top)

            // Filter Selection
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)

            // NMEA Data Scrollable Window
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(filteredData.enumerated()), id: \.element) { index, nmea in
                            Text(nmea)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black.opacity(0.8))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                                .font(.system(.body, design: .monospaced))
                                .id(index)  // Assign ID for scrolling
                        }
                    }
                    .padding(.horizontal, 4)
                    .onChange(of: filteredData.count) {
                        // Auto-scroll to the latest message when new data is added
                        withAnimation {
                            proxy.scrollTo(filteredData.count - 1, anchor: .bottom)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.gray.opacity(0.6), lineWidth: 1)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(12)
                )
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 4)

            Spacer()
        }
        .padding(.horizontal, 4)
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
    }
}

#Preview {
    ReadRawNMEA()
        .environment(NMEAParser())
}
