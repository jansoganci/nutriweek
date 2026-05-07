import Foundation

struct BodyMeasurements: Codable, Equatable, Sendable {
    /// RN domain model keeps generic limbs (`arms`, `thighs`).
    /// Onboarding payload uses `leftArmCm` / `leftLegCm`; map at DTO layer.
    var chest: Double?
    var waist: Double?
    var hips: Double?
    var thighs: Double?
    var arms: Double?
}
