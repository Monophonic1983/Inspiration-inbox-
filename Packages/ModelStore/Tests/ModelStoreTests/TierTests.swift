import Testing
@testable import ModelStore

@Test func tiersFollowRAM() {
    #expect(ModelTier.forPhysicalRAMGB(8) == .large4B)
    #expect(ModelTier.forPhysicalRAMGB(6) == .small2B)
    #expect(ModelTier.forPhysicalRAMGB(4) == .foundationModelsOrRawOnly)
}
