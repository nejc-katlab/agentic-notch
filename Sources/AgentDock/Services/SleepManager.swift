import Foundation
import IOKit.pwr_mgt

final class SleepManager {
    private var assertionID: IOPMAssertionID = IOPMAssertionID(0)
    private var currentReason: String?
    private(set) var isHolding = false

    func assertIfNeeded(reason: String) {
        let reasonStr = "AgentDock: \(reason)" as CFString

        if isHolding {
            guard reason != currentReason else { return }
            if IOPMAssertionSetProperty(assertionID, kIOPMAssertionNameKey as CFString, reasonStr) == kIOReturnSuccess {
                currentReason = reason
            }
            return
        }

        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reasonStr,
            &assertionID
        )

        if result == kIOReturnSuccess {
            isHolding = true
            currentReason = reason
            NSLog("AgentDock: sleep assertion created — %@", reason)
        } else {
            NSLog("AgentDock: failed to create sleep assertion (error %d)", result)
        }
    }

    func releaseAssertion() {
        guard isHolding else { return }

        let result = IOPMAssertionRelease(assertionID)
        if result == kIOReturnSuccess {
            NSLog("AgentDock: sleep assertion released")
        }
        assertionID = IOPMAssertionID(0)
        currentReason = nil
        isHolding = false
    }

    deinit {
        releaseAssertion()
    }
}
