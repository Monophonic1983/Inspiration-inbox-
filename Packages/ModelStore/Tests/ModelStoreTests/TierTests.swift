import Foundation
import Testing
@testable import ModelStore

@Test func tiersFollowRAM() {
    #expect(ModelTier.forPhysicalRAMGB(8) == .large4B)
    #expect(ModelTier.forPhysicalRAMGB(6) == .small2B)
    #expect(ModelTier.forPhysicalRAMGB(4) == .foundationModelsOrRawOnly)
}

private func model(_ id: String, ram: Int, files: Bool = true) -> ModelDescriptor {
    ModelDescriptor(id: id, displayName: id, role: .structuring, license: "Apache-2.0", minRAMGB: ram,
                    files: files ? [ModelFile(path: "w.bin", url: URL(string: "https://example.com/w")!, sha256: "00", sizeBytes: 10)] : [])
}

@Test func catalogPicksLargestModelThatFits() {
    let c = ModelCatalog(version: 1, models: [model("2b", ram: 6), model("4b", ram: 8)])
    #expect(c.structuringModel(forRAMGB: 8)?.id == "4b")
    #expect(c.structuringModel(forRAMGB: 6)?.id == "2b")
    #expect(c.structuringModel(forRAMGB: 4) == nil)
}

@Test func catalogIgnoresModelsWithoutFiles() {
    #expect(ModelCatalog(version: 0, models: [model("2b", ram: 6, files: false)]).structuringModel(forRAMGB: 8) == nil)
}

@Test func checksumMatchesKnownDigest() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try Data("abc".utf8).write(to: url)
    #expect(try Checksum.sha256Hex(of: url) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
}

@Test func bundledCatalogLoads() {
    #expect(CatalogLoader.bundled().models.count == 2)
}

@MainActor @Test func deleteResetsState() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = ModelStore(root: root)
    try FileManager.default.createDirectory(at: store.directory(for: "m"), withIntermediateDirectories: true)
    FileManager.default.createFile(atPath: store.directory(for: "m").appendingPathComponent(".installed").path, contents: Data())
    #expect(store.installedDirectory(for: "m") != nil)
    store.delete("m")
    #expect(store.installedDirectory(for: "m") == nil)
}
