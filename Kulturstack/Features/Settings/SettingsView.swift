import SwiftData
import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @State private var isConfirmingWipe = false
    @State private var isConfirmingWipeAgain = false
    @State private var didWipe = false
    private let services: AppServices

    init(services: AppServices) {
        let info = Bundle.main.infoDictionary
        _viewModel = State(initialValue: SettingsViewModel(
            wipe: services.wipeUseCase,
            export: ExportUseCase(repository: services.mediaRepository),
            version: info?["CFBundleShortVersionString"] as? String ?? "0",
            build: info?["CFBundleVersion"] as? String ?? "0"))
        self.services = services
    }

    #if DEBUG
    var viewModelForTesting: SettingsViewModel { viewModel }
    #endif

    var body: some View {
        Form {
            Section {
                LabeledContent(String(localized: "settings.language"), value: String(localized: "settings.language.system"))
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Link(String(localized: "settings.language.open"), destination: url)
                }
            }
            Section {
                NavigationLink(String(localized: "settings.privacy")) { PrivacyView() }
                NavigationLink(String(localized: "settings.about")) { AboutView(versionLine: viewModel.versionLine) }
            }
            // Avant « Tout effacer », et c'est voulu : on propose de sauvegarder avant de
            // proposer de détruire. Sans Mac ni câble — la sauvegarde du Mac n'avait rien
            // vu passer pendant sept jours faute de téléphone branché (25/10).
            Section {
                if let file = viewModel.exportFile {
                    ShareLink(item: file) {
                        Label(String(localized: "settings.export"), systemImage: "square.and.arrow.up")
                    }
                } else {
                    Label(String(localized: "settings.export"), systemImage: "square.and.arrow.up")
                        .foregroundStyle(Color.textSecondary)
                }
            } footer: {
                Text(viewModel.exportFooter)
            }
            Section {
                Button(String(localized: "settings.wipe"), role: .destructive) { isConfirmingWipe = true }
            } footer: {
                Text(String(localized: "settings.wipe.footer"))
            }
            #if DEBUG
            DebugSection()
            #endif
        }
        .task { viewModel.prepareExport() }
        .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { _ in
            viewModel.prepareExport()
        }
        .alert(String(localized: "settings.export.failed"), isPresented: $viewModel.didFailToExport) {}
        .navigationTitle(String(localized: "settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        // Deux confirmations : effacer, c'est irréversible et sans sauvegarde avant T3.
        .confirmationDialog(String(localized: "settings.wipe.confirm.title"), isPresented: $isConfirmingWipe, titleVisibility: .visible) {
            Button(String(localized: "settings.wipe.confirm.action"), role: .destructive) { isConfirmingWipeAgain = true }
        } message: {
            Text(String(localized: "settings.wipe.confirm.message"))
        }
        .alert(String(localized: "settings.wipe.again.title"), isPresented: $isConfirmingWipeAgain) {
            Button(String(localized: "common.cancel"), role: .cancel) {}
            Button(String(localized: "settings.wipe.again.action"), role: .destructive) { didWipe = viewModel.wipeAll() }
        } message: {
            Text(String(localized: "settings.wipe.again.message"))
        }
        .alert(String(localized: "settings.wipe.failed"), isPresented: $viewModel.didFailToWipe) {}
        .alert(String(localized: "settings.wipe.done"), isPresented: $didWipe) {}
    }
}
