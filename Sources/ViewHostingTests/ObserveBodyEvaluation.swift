import SwiftUI
@testable import ViewHostingApp
import XCTest

// this silences the "notification is not sendable" warning
#if swift(>=6.0)
extension Notification: @unchecked @retroactive Sendable {}
#else
extension Notification: @unchecked Sendable {}
#endif

extension NotificationCenter {
    @MainActor func observeBodyEvaluation<T: View>(timeout: TimeInterval) async throws -> T {
        // normally we get notification immediately but if there is any problem we dont want to wait forever
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            // if timeout happens we post nil to unblock the for-await
            post(name: .bodyEvaluation, object: nil)
        }
        defer { timeoutTask.cancel() }
        for await notification in notifications(named: .bodyEvaluation) {
            guard let view = notification.object else {
                throw NSError(domain: "Add 'postBodyEvaluation()' in the body of view \(T.self)", code: 0)
            }
            guard let view = view as? T else {
                continue
            }
            return view
        }
        fatalError()
    }
}

extension View {
    @discardableResult @MainActor static func onBodyEvaluation(timeout: TimeInterval = 1) async throws -> Self {
        try await NotificationCenter.default.observeBodyEvaluation(timeout: timeout)
    }

    @MainActor static func hostedView(timeout: TimeInterval = 1, content: () -> any View) async throws -> Self {
        guard let hostView = ViewHostingApp.hostView else {
            throw XCTSkip("view needs hosting")
        }
        hostView(content)
        return try await onBodyEvaluation(timeout: timeout)
    }
}