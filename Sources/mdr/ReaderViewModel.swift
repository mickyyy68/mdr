import Combine

/// Per-window navigation state for a reader window: whether it is showing the
/// document or the settings view. Owned by `AppDelegate`, observed by `ReaderView`.
@MainActor
final class ReaderViewModel: ObservableObject {
    @Published var isShowingSettings = false
}