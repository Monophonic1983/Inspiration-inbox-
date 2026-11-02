import Foundation

/// Loads the model catalog: remote config first (so model names can change without a release), bundled copy as fallback.
/// The bundled catalog ships with empty `files`; fill them from the Phase 0 bake-off result (see docs/mac-setup.md).
public enum CatalogLoader {
    public static func bundled() -> ModelCatalog {
        guard let url = Bundle.module.url(forResource: "catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(ModelCatalog.self, from: data)
        else { return ModelCatalog(version: 0, models: []) }
        return catalog
    }

    /// Fetching the catalog sends no user data. `remoteURL` is nil until a catalog host exists.
    public static func load(remoteURL: URL?, session: URLSession = .shared) async -> ModelCatalog {
        let local = bundled()
        guard let remoteURL, let (data, _) = try? await session.data(from: remoteURL),
              let remote = try? JSONDecoder().decode(ModelCatalog.self, from: data), remote.version >= local.version
        else { return local }
        return remote
    }
}
