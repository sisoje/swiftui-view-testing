import Combine
import SwiftUI

struct ViewHosting<T: View> {
    struct SendableView: @unchecked Sendable { let view: T }
    let currentValue = CurrentValueSubject<SendableView?, Never>(nil)
}

@MainActor extension ViewHosting {
    private func host(content: () -> any View) {
        _ = _PreviewHost.makeHost(content: content()).previews
    }

    func hosted(content: () -> any View) async throws -> T {
        host {
            content().onBody { view in
                currentValue.send(SendableView(view: view))
            }
        }
        guard let view = currentValue.value?.view else {
            throw ViewHostingError.missing
        }
        return view
    }

    @discardableResult func onBody(timeout: TimeInterval = 1) async throws -> T {
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            currentValue.send(nil)
        }
        for await bodyEvaluation in currentValue.dropFirst().values {
            timeoutTask.cancel()
            guard let view = bodyEvaluation?.view else {
                throw ViewHostingError.timeout
            }
            return view
        }
        fatalError()
    }
}