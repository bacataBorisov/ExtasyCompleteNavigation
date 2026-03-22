//
//  KalmanFilter.swift
//  ExtasyCompleteNavigation
//
//  Created by Vasil Borisov on 19.11.24.
//
//
//  Utility class for smoothing noisy data using the Kalman filter.
/**
 Key Parameters in Kalman Filter

     1.   Q (Process Noise Covariance):
     •    Represents the uncertainty in the system model (i.e., how much the actual system deviates from the model used in the Kalman filter).
     •    Higher Q allows the filter to trust the incoming measurements more and react faster to changes.
     •    Lower Q makes the filter trust its internal prediction more, resulting in slower adaptation to changes.
 
     2.   R (Measurement Noise Covariance):
 
     •    Represents the noise level in the incoming measurements.
     •    Higher R makes the filter smoother but slower to respond to changes.
     •    Lower R makes the filter more responsive but potentially noisier.

 Steps to Tune the Kalman Filter

     1.   Understand Your Data:
     •    Analyze the variability in your wind force data (both apparent and true). High variability might suggest       a need for higher Q or lower R.
     2.   Initial Guess for Q and R:
     •    Start with equal values for Q and R (e.g., Q = 0.1, R = 0.1) and observe the filter’s behavior.
     3.   Experimentation:
     •    Gradually increase or decrease Q and R to observe the effect on the filtered output.
     •    For smoother output, increase R.
     •    For faster response, increase Q.
     4.   Automated Tuning (Optional):
     •    Implement an optimization routine to minimize the error between the filtered output and a ground truth (if available).
     •    For example, use the sum of squared errors (SSE) or mean squared error (MSE) as an objective function.

 Adjusting Q and R Dynamically

 In some cases, you might want to adjust Q and R dynamically based on the state of the system. For example:

     •    If the boat is moving through turbulent conditions, increase Q to allow faster adaptation.
     •    If the system is in stable conditions, increase R to smooth the data more.

 How to Apply This in Your Code

 In your Kalman filter implementation, Q and R can either:

     •    Be set statically during initialization (e.g., kalmanFilter.updateParameters(Q: 0.01, R: 0.1)).
     •    Be updated dynamically during runtime based on some conditions.

 */
import Foundation

class KalmanFilter {
    private var x: Double      // Estimated value
    private var p: Double      // Estimate uncertainty
    private var q: Double      // Process noise covariance
    private var r: Double      // Measurement noise covariance

    init(initialValue: Double, processNoise: Double = 1e-5, measurementNoise: Double = 1e-1) {
        self.x = initialValue
        self.p = 1.0
        self.q = processNoise
        self.r = measurementNoise
    }

    func update(measurement: Double) -> Double {
        p += q
        let k = p / (p + r)
        x += k * (measurement - x)
        p *= (1 - k)
        return x
    }

    /// Update Q and R without resetting the accumulated estimate — no value jump.
    func updateNoise(processNoise: Double, measurementNoise: Double) {
        q = processNoise
        r = measurementNoise
    }

    /// Maps a user-facing damping level (0 = raw, 11 = maximum smooth) to Q/R parameters.
    /// R spans 1e-3 … 1e4 logarithmically; Q stays fixed at 1.0.
    static func params(forDampingLevel level: Int) -> (processNoise: Double, measurementNoise: Double) {
        let clamped = max(0, min(11, level))
        let r = pow(10.0, Double(clamped) * 7.0 / 11.0 - 3.0)
        return (processNoise: 1.0, measurementNoise: r)
    }
}
