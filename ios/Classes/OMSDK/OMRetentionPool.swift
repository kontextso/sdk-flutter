import Foundation

final class OMRetentionPool {
    static let shared = OMRetentionPool()

    private init() {}

    private var retainedSessions: [UUID: OMSession] = [:]

    func retain(_ session: OMSession) {
        let id = UUID()
        retainedSessions[id] = session

        DispatchQueue.main.asyncAfter(
            deadline: .now() + OMConstants.retentionInterval
        ) { [weak self] in
            self?.retainedSessions.removeValue(forKey: id)
        }
    }
}
