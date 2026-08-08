import SwiftUI

@MainActor
final class SettingsViewStore: ObservableObject {
    @Published var viewModel = SettingsModels.Load.ViewModel(
        icons: [],
        selectedIconID: "default",
        packs: [],
        selectedPack: "classic"
    )

    var interactor: SettingsBusinessLogic!

    func displayLoad(_ viewModel: SettingsModels.Load.ViewModel) {
        self.viewModel = viewModel
    }
}

enum SettingsSceneFactory {
    @MainActor
    static func make() -> SettingsViewStore {
        let store = SettingsViewStore()
        let presenter = SettingsPresenter()
        presenter.display = store
        store.interactor = SettingsInteractor(presenter: presenter)
        return store
    }
}

struct SettingsView: View {
    @StateObject private var store: SettingsViewStore

    init(router: AppRouter) {
        _store = StateObject(wrappedValue: SettingsSceneFactory.make())
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    iconSection
                    soundSection
                }
                .padding(16)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { store.interactor.load() }
    }

    private var iconSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("APP ICON")
                    .font(.sectionLabel)
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 0) {
                    ForEach(store.viewModel.icons) { icon in
                        let isSelected = store.viewModel.selectedIconID == icon.id
                        Button {
                            store.interactor.selectIcon(key: icon.key)
                        } label: {
                            VStack(spacing: 6) {
                                Image(icon.previewAsset)
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                                            .strokeBorder(isSelected ? Theme.accent : Theme.cardBorder,
                                                          lineWidth: isSelected ? 2.5 : 1)
                                    )
                                Text(icon.title)
                                    .font(.system(.caption2, design: .rounded).weight(isSelected ? .bold : .regular))
                                    .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                            }
                            .padding(.horizontal, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var soundSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 4) {
                Text("TIMER SOUNDS · tap to preview")
                    .font(.sectionLabel)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.bottom, 8)
                ForEach(store.viewModel.packs) { pack in
                    let isSelected = store.viewModel.selectedPack == pack.key
                    Button {
                        store.interactor.selectPack(key: pack.key)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: isSelected ? "speaker.wave.2.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pack.title)
                                    .font(.system(.body, design: .rounded).weight(.bold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(pack.subtitle)
                                    .font(.system(.footnote, design: .rounded))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if pack.id != store.viewModel.packs.last?.id {
                        Divider().overlay(Theme.cardBorder)
                    }
                }
            }
        }
    }
}
