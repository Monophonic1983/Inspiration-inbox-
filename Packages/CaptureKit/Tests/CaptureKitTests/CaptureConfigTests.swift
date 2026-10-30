import Testing
@testable import CaptureKit

@Test func defaultAutoStopIs2_5Seconds() {
    #expect(CaptureConfig().autoStopSilence == 2.5)
}
