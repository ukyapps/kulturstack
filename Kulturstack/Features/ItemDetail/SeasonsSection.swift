import SwiftUI

struct SeasonsSection: View {
    @State private var viewModel: SeriesEpisodesViewModel
    @State private var expanded: Set<Int>
    @State private var uncheckingSeason: Int?

    private let opened: Set<Int>

    init(itemID: UUID, services: AppServices, opened: Set<Int> = [], onChange: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: SeriesEpisodesViewModel(
            itemID: itemID, repository: services.mediaRepository, useCase: services.episodeUseCase,
            status: services.watchStatusUseCase, onChange: onChange))
        _expanded = State(initialValue: opened)
        self.opened = opened
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            // Où elle en est vient avant la liste : c'est ce qu'on ouvre la fiche pour savoir.
            if let next = viewModel.next {
                NextEpisodeCard(next: next) { Task { await viewModel.checkNext() } }
            }
            header
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            await viewModel.load()
            // La saison où elle en est s'ouvre d'elle-même : la fiche arrive dépliée au bon endroit.
            if let current = viewModel.currentSeason { expanded.insert(current) }
            for number in opened.sorted() { await viewModel.open(number) }
        }
        .alert(String(localized: "series.check.failed"), isPresented: $viewModel.didFailToCheck) {}
        .confirmationDialog(String(localized: "series.season.uncheck.title"), isPresented: isUnchecking,
                            titleVisibility: .visible, presenting: uncheckingSeason) { number in
            Button(String(localized: "series.season.uncheckAll"), role: .destructive) {
                viewModel.uncheckSeason(number)
            }
        } message: { _ in
            Text(String(localized: "series.season.uncheck.message"))
        }
        .alert(String(localized: "series.finish.title"), isPresented: $viewModel.proposesFinish) {
            Button(String(localized: "series.finish.confirm")) { viewModel.finish() }
            Button(String(localized: "series.finish.later"), role: .cancel) {}
        } message: {
            Text(String(localized: "series.finish.message"))
        }
    }

    // Le statut se montre et se change au même endroit : abandonner est une action, jamais une devinette.
    private var header: some View {
        HStack(spacing: Spacing.s) {
            Text(String(localized: "series.seasons.title"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)
            if let status = viewModel.watchStatus {
                Text(status.label)
                    .font(.caption)
                    .padding(.horizontal, Spacing.s)
                    .padding(.vertical, 2)
                    .background(Color.surfaceSecondary, in: Capsule())
                    .foregroundStyle(Color.textPrimary)
            }
            Spacer(minLength: 0)
            Menu {
                if viewModel.watchStatus == .dropped {
                    Button(String(localized: "series.resume"), systemImage: "play.circle") { viewModel.resume() }
                } else {
                    Button(String(localized: "series.drop"), systemImage: "xmark.circle", role: .destructive) {
                        viewModel.drop()
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(Color.textSecondary)
                    .accessibilityLabel(String(localized: "series.status.menu"))
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.seasons {
        case .loading:
            ProgressView().frame(maxWidth: .infinity)
        case .empty:
            EmptyState(
                icon: "rectangle.stack",
                title: String(localized: "series.seasons.empty.title"),
                message: String(localized: "series.seasons.empty.message")
            )
        case .failed:
            EmptyState(
                icon: "wifi.exclamationmark",
                title: String(localized: "series.seasons.failed.title"),
                message: String(localized: "series.seasons.failed.message"),
                action: .init(title: String(localized: "common.retry")) { Task { await viewModel.load() } }
            )
        case .loaded(let seasons):
            ForEach(seasons) { season in
                DisclosureGroup(isExpanded: binding(for: season.number)) {
                    episodes(of: season)
                } label: {
                    label(season)
                }
                Divider()
            }
        }
    }

    private func label(_ season: SeasonRowModel) -> some View {
        HStack(spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: 2) {
                Text(season.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                Text(season.progress)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer(minLength: 0)
            if season.isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accent)
                    .accessibilityLabel(String(localized: "series.season.complete"))
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    // Trois rendus par saison, comme pour la liste : rien d'annoncé ≠ chargement raté ≠ les épisodes.
    @ViewBuilder private func episodes(of season: SeasonRowModel) -> some View {
        switch viewModel.episodes[season.number] {
        case .loaded(let rows):
            VStack(alignment: .leading, spacing: 0) {
                wholeSeason(season)
                ForEach(rows) { row in
                    EpisodeRow(model: row,
                               toggle: { viewModel.toggle(episode: row.number, in: season.number) },
                               checkUpTo: { viewModel.checkUpTo(episode: row.number, in: season.number) })
                }
            }
            .sensoryFeedback(.selection, trigger: season.watchedCount)
        case .empty:
            Text(String(localized: "series.episodes.empty"))
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .padding(.vertical, Spacing.s)
        case .failed:
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(String(localized: "series.episodes.failed"))
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                Button(String(localized: "common.retry")) { Task { await viewModel.open(season.number) } }
                    .buttonStyle(.bordered)
            }
            .padding(.vertical, Spacing.s)
        case .loading, .none:
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, Spacing.s)
        }
    }

    // « J'ai vu toute la saison » en un bouton, sous la saison dépliée — c'est là qu'on sait
    // enfin ce qu'elle contient. Décocher est destructeur : ça se confirme.
    @ViewBuilder private func wholeSeason(_ season: SeasonRowModel) -> some View {
        Group {
            if season.isComplete {
                Button(String(localized: "series.season.uncheckAll"), systemImage: "arrow.uturn.backward") {
                    uncheckingSeason = season.number
                }
            } else {
                Button(String(localized: "series.season.checkAll"), systemImage: "checkmark.circle") {
                    viewModel.checkSeason(season.number)
                }
            }
        }
        .buttonStyle(.bordered)
        .font(.subheadline.weight(.semibold))
        .padding(.vertical, Spacing.s)
    }

    private var isUnchecking: Binding<Bool> {
        Binding(get: { uncheckingSeason != nil }, set: { if !$0 { uncheckingSeason = nil } })
    }

    // Une saison n'est chargée qu'au dépliement : une série de dix saisons ne fait pas dix appels.
    private func binding(for number: Int) -> Binding<Bool> {
        Binding(
            get: { expanded.contains(number) },
            set: { isOpen in
                if isOpen {
                    expanded.insert(number)
                    Task { await viewModel.open(number) }
                } else {
                    expanded.remove(number)
                }
            }
        )
    }
}
