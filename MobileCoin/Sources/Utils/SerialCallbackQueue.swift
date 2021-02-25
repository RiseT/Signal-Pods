//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

final class SerialCallbackQueue {
    private let inner: SerialDispatchLock<Inner>

    init(targetQueue: DispatchQueue?) {
        self.inner = SerialDispatchLock(Inner(), targetQueue: targetQueue)
    }

    func prepend(_ block: @escaping (@escaping () -> Void) -> Void) {
        inner.accessAsyncAndStartIfNeeded {
            $0.prependTask(block)
        }
    }

    func append(_ block: @escaping (@escaping () -> Void) -> Void) {
        inner.accessAsyncAndStartIfNeeded {
            $0.appendTask(block)
        }
    }
}

extension SerialCallbackQueue {
    func prepend<Value>(
        _ block: @escaping (@escaping (Value) -> Void) -> Void,
        completion: @escaping (Value) -> Void
    ) {
        prepend { callback in
            block { value in
                callback()
                completion(value)
            }
        }
    }

    func append<Value>(
        _ block: @escaping (@escaping (Value) -> Void) -> Void,
        completion: @escaping (Value) -> Void
    ) {
        append { callback in
            block { value in
                callback()
                completion(value)
            }
        }
    }
}

extension SerialDispatchLock where Value == SerialCallbackQueue.Inner {
    fileprivate func accessAsyncAndStartIfNeeded(
        _ block: @escaping (SerialCallbackQueue.Inner) -> Void
    ) {
        accessAsync {
            block($0)

            if !$0.started {
                let nextTask = $0.startNextTask()
                nextTask(self.taskCompletion)
            }
        }
    }

    private func taskCompletion() {
        accessAsync {
            guard let nextTask = $0.nextTaskOrStop() else {
                return
            }
            nextTask(self.taskCompletion)
        }
    }
}

extension SerialCallbackQueue {
    fileprivate class Inner {
        private var pendingTasks: [(@escaping () -> Void) -> Void] = []
        fileprivate private(set) var started = false

        func prependTask(_ block: @escaping (@escaping () -> Void) -> Void) {
            pendingTasks.insert(block, at: 0)
        }

        func appendTask(_ block: @escaping (@escaping () -> Void) -> Void) {
            pendingTasks.append(block)
        }

        func startNextTask() -> (@escaping () -> Void) -> Void {
            started = true
            return pendingTasks.removeFirst()
        }

        func nextTaskOrStop() -> ((@escaping () -> Void) -> Void)? {
            if !pendingTasks.isEmpty {
                return pendingTasks.removeFirst()
            } else {
                started = false
                return nil
            }
        }
    }
}
