import HealthKit

final class HealthKitManager {
    static let shared = HealthKitManager()
    let store = HKHealthStore()

    private init() {}

    // Les- og skrive-typene samlet som properties for gjenbruk
    private let readTypes: Set<HKObjectType> = [
        .workoutType(),
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    ]

    private let writeTypes: Set<HKSampleType> = [
        .workoutType(),
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!
    ]

    /// Asynkron autorisasjon mot HealthKit
    func requestAuthorization() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            store.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
}
