import Foundation

public final class VMGCalculator {
    private let SMALL: Double = 1.0e-5
    private let DEG_TO_RAD: Double = .pi / 180.0

    public private(set) var wind: [Double] = []
    public private(set) var gradus: [Double] = []
    public private(set) var diagram: [[Double]] = []
    public private(set) var optimalTackTable: [[Double]] = []

    public init?(diagram: [[Double]]) {
        guard !diagram.isEmpty, diagram[0].count > 1, diagram.count > 1 else {
            debugLog("VMGCalculator: Diagram data is empty or malformed.")
            return nil
        }

        self.wind = diagram[0].dropFirst().map { $0 }
        self.gradus = diagram.dropFirst().map { $0[0] }
        self.diagram = diagram.dropFirst().map { Array($0.dropFirst()) }
    }

    public func loadTackTable(from rows: [[Double]]) {
        optimalTackTable = rows
    }

    @discardableResult
    public func readOptimalTackTable(fileName: String) -> Bool {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "txt") else {
            debugLog("VMGCalculator: File not found: \(fileName).txt")
            return false
        }

        let contents: String
        do {
            let fileURL = URL(fileURLWithPath: path)
            contents = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            debugLog("VMGCalculator: Couldn't read file \(fileName).txt — \(error.localizedDescription)")
            return false
        }

        let lines = contents.components(separatedBy: .newlines)
        for (rowIndex, line) in lines.enumerated() {
            guard !line.isEmpty else { continue }

            if rowIndex > 0 {
                let values = line.split(whereSeparator: { $0.isWhitespace }).compactMap { Double($0) }
                if values.count >= 8 {
                    optimalTackTable.append(values)
                } else {
                    debugLog("Malformed row \(rowIndex): \(line)")
                }
            }
        }

        debugLog("Optimal tack table loaded with \(optimalTackTable.count) rows.")
        return !optimalTackTable.isEmpty
    }

    public func interpolateTackTableUsingSpline(for windSpeed: Double, trueWindAngle: Double) -> (interpolatedRow: [Double]?, sailingState: String?, sailingStateLimit: Double?) {
        guard !optimalTackTable.isEmpty else {
            debugLog("Optimal tack table is empty.")
            return (nil, nil, nil)
        }

        let normalizedTWA = normalizeAngleTo180(trueWindAngle)
        let windSpeeds = optimalTackTable.map { $0[0] }

        guard let lowerIndex = windSpeeds.lastIndex(where: { $0 <= windSpeed }),
              let upperIndex = windSpeeds.firstIndex(where: { $0 > windSpeed }),
              lowerIndex != upperIndex else {
            debugLog("Wind speed \(windSpeed) is out of range.")
            return (nil, nil, nil)
        }

        if windSpeed <= windSpeeds.first! {
            let threshold = optimalTackTable.first?[7] ?? 0
            return (optimalTackTable.first, determineSailingState(trueWindAngle: normalizedTWA, threshold: threshold), threshold)
        }
        if windSpeed >= windSpeeds.last! {
            let threshold = optimalTackTable.last?[7] ?? 0
            return (optimalTackTable.last, determineSailingState(trueWindAngle: normalizedTWA, threshold: threshold), threshold)
        }

        var interpolatedRow: [Double] = [windSpeed]
        let expectedColumns = optimalTackTable[0].count
        for columnIndex in 1..<expectedColumns {
            let xa = optimalTackTable[max(lowerIndex - 1, 0)][columnIndex]
            let xb = optimalTackTable[lowerIndex][columnIndex]
            let xc = optimalTackTable[upperIndex][columnIndex]
            let xd = optimalTackTable[min(upperIndex + 1, windSpeeds.count - 1)][columnIndex]

            let u = (windSpeed - windSpeeds[lowerIndex]) / (windSpeeds[upperIndex] - windSpeeds[lowerIndex])
            interpolatedRow.append(eval_cubic_spline(u: u, xa: xa, xb: xb, xc: xc, xd: xd))
        }

        let interpolatedThreshold = interpolatedRow.last ?? 0
        let sailingState = determineSailingState(trueWindAngle: normalizedTWA, threshold: interpolatedThreshold)

        return (interpolatedRow, sailingState, interpolatedThreshold)
    }

    public func evaluateDiagram(windForce: Double, windAngle: Double) -> Double {
        guard !wind.isEmpty, !gradus.isEmpty else { return 0.0 }

        var finalWindAngle = abs(windAngle)
        if windForce <= wind[0] { return 0.0 }
        if finalWindAngle > 360 { finalWindAngle -= 360 }
        if finalWindAngle > 180 { finalWindAngle = 360 - finalWindAngle }

        guard let j = wind.firstIndex(where: { $0 > windForce }), j > 0 else { return 0.0 }
        let windRatio = (windForce - wind[j - 1]) / (wind[j] - wind[j - 1])

        guard let i = gradus.firstIndex(where: { $0 > finalWindAngle }), i > 0 else { return 0.0 }
        let angleRatio = (finalWindAngle - gradus[i - 1]) / (gradus[i] - gradus[i - 1])

        return interpolate(windIndex: j, angleIndex: i, windRatio: windRatio, angleRatio: angleRatio)
    }

    /// Boat speed (knots) at each diagram TWA for the given true wind speed.
    public func polarBoatSpeedCurve(forTrueWindSpeedKnots tws: Double) -> [(twa: Double, speed: Double)] {
        guard !wind.isEmpty, !gradus.isEmpty else { return [] }
        return gradus.map { twa in
            (twa: twa, speed: evaluateDiagram(windForce: tws, windAngle: twa))
        }
    }

    private func interpolate(windIndex j: Int, angleIndex i: Int, windRatio: Double, angleRatio: Double) -> Double {
        let i0 = max(i - 1, 0)
        let i1 = i
        let i2 = min(i + 1, gradus.count - 1)
        let i3 = min(i + 2, gradus.count - 1)

        let j0 = max(j - 1, 0)
        let j1 = j
        let j2 = min(j + 1, wind.count - 1)
        let j3 = min(j + 2, wind.count - 1)

        let dWind1 = eval_cubic_spline(u: windRatio, xa: diagram[i0][j0], xb: diagram[i0][j1], xc: diagram[i0][j2], xd: diagram[i0][j3])
        let dWind2 = eval_cubic_spline(u: windRatio, xa: diagram[i1][j0], xb: diagram[i1][j1], xc: diagram[i1][j2], xd: diagram[i1][j3])
        let dWind3 = eval_cubic_spline(u: windRatio, xa: diagram[i2][j0], xb: diagram[i2][j1], xc: diagram[i2][j2], xd: diagram[i2][j3])
        let dWind4 = eval_cubic_spline(u: windRatio, xa: diagram[i3][j0], xb: diagram[i3][j1], xc: diagram[i3][j2], xd: diagram[i3][j3])

        return eval_cubic_spline(u: angleRatio, xa: dWind1, xb: dWind2, xc: dWind3, xd: dWind4)
    }

    public func eval_cubic_spline(u: Double, xa: Double, xb: Double, xc: Double, xd: Double) -> Double {
        guard u >= 0 && u <= 1 else {
            Log.navigation.warning("Cubic spline interpolation parameter \(u) is outside the valid range [0, 1]")
            return 0.0
        }

        let c = u * u * u * (-1 * xa + 3 * xb - 3 * xc + xd) +
        u * u * (3 * xa - 6 * xb + 3 * xc) +
        u * (-3 * xa + 3 * xc) +
        (xa + 4 * xb + xc)

        return c / 6.0
    }

    public func determineSailingState(trueWindAngle: Double, threshold: Double) -> String {
        abs(trueWindAngle) <= threshold ? "Upwind" : "Downwind"
    }
}
