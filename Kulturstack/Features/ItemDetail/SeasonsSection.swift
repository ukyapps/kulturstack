import SwiftUI

struct SeasonsSection: View {
    // L'année qu'on s'apprête à décocher, et la saison implicite qui la porte. Un podcast n'en
    // a qu'une aujourd'hui, mais la coder en dur ici serait un piège pour la prochaine fois.
    private struct YearToUncheck: Identifiable {
        let year: Int?
        let season: Int

        var id: Int { (year ?? 0) * 1000 + season }
    }

    @State private var viewModel: SeriesEpisodesViewModel
    @State private var expanded: Set<Int>
    @State private var uncheckingSeason: Int?
    // Les années d'un podcast se replient comme les saisons d'une série ; celle où elle en
    // est — la plus récente — s'ouvre d'elle-même.
    @State private var expandedYears: Set<Int> = []
    @State private var uncheckingYear: YearToUncheck?
    @State private var isCheckingEverything = false

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
                NextEpisodeCard(next: next, kind: viewModel.kind) { Task { await viewModel.checkNext() } }
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
            // Pour un podcast, c'est l'année la plus récente : celle qu'on écoute.
            if let latest = viewModel.latestYear { expandedYears.insert(latest) }
        }
        .alert(String(localized: "series.check.failed"), isPresented: $viewModel.didFailToCheck) {}
        .confirmationDialog(viewModel.kind.uncheckEverythingTitle, isPresented: isUnchecking,
                            titleVisibility: .visible, presenting: uncheckingSeason) { number in
            Button(String(localized: "series.season.uncheckAll"), role: .destructive) {
                viewModel.uncheckSeason(number)
            }
        } message: { _ in
            Text(viewModel.kind.uncheckEverythingMessage)
        }
        .confirmationDialog(viewModel.kind.uncheckEverythingTitle, isPresented: isUncheckingYear,
                            titleVisibility: .visible, presenting: uncheckingYear) { target in
            Button(String(localized: "series.season.uncheckAll"), role: .destructive) {
                viewModel.uncheckYear(target.year, in: target.season)
            }
        } message: { _ in
            Text(viewModel.kind.uncheckEverythingMessage)
        }
        // Cocher toute une série écrit des dizaines de logs : ça se confirme une fois.
        .confirmationDialog(String(localized: "series.checkAll.confirm.title"),
                            isPresented: $isCheckingEverything, titleVisibility: .visible) {
            Button(String(localized: "series.checkAll")) { Task { await viewModel.checkEverything() } }
        } message: {
            Text(String(localized: "series.checkAll.confirm.message"))
        }
    }

    // Le statut se montre et se change au même endroit : abandonner est une action, jamais une devinette.
    private var header: some View {
        HStack(spacing: Spacing.s) {
            Text(viewModel.kind.episodesSectionTitle)
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
                    Button(viewModel.kind.resumeLabel, systemImage: "play.circle") { viewModel.resume() }
                } else {
                    Button(viewModel.kind.dropLabel, systemImage: "xmark.circle", role: .destructive) {
                        viewModel.drop()
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(Color.textSecondary)
                    .accessibilityLabel(viewModel.kind.statusMenuLabel)
            }
        }
    }

    // « Sur une série je peux pas dire j'ai tout vu toute la série » (founder, 30/09). Toutes
    // les saisons d'un coup, y compris celles qu'on n'a jamais ouvertes — d'où l'attente
    // affichée : c'est un appel par saison.
    @ViewBuilder private var wholeSeries: some View {
        if viewModel.isCheckingEverything {
            HStack(spacing: Spacing.s) {
                ProgressView()
                Text(String(localized: "series.checkAll.running"))
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.top, Spacing.s)
        } else if viewModel.watchStatus != .done {
            Button(String(localized: "series.checkAll"), systemImage: "checkmark.circle.fill") {
                isCheckingEverything = true
            }
            .buttonStyle(.bordered)
            .font(.subheadline.weight(.semibold))
            .padding(.top, Spacing.s)
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.seasons {
        case .loading:
            ProgressView().frame(maxWidth: .infinity)
        case .empty:
            EmptyState(
                icon: viewModel.kind.showsSeasons ? "rectangle.stack" : "mic",
                title: viewModel.kind.noEpisodesTitle,
                message: viewModel.kind.noEpisodesMessage
            )
        case .failed:
            EmptyState(
                icon: "wifi.exclamationmark",
                title: viewModel.kind.episodesFailedTitle,
                message: String(localized: "series.seasons.failed.message"),
                action: .init(title: String(localized: "common.retry")) { Task { await viewModel.load() } }
            )
        case .loaded(let seasons):
            // Un podcast n'a qu'une saison, implicite : sa liste s'affiche à plat, sans en-tête
            // ni dépliement. Une série garde ses saisons, qui veulent dire quelque chose.
            if !viewModel.kind.showsSeasons, let only = seasons.first {
                years(of: only)
            } else {
                ForEach(seasons) { season in
                    DisclosureGroup(isExpanded: binding(for: season.number)) {
                        episodes(of: season)
                    } label: {
                        label(season)
                    }
                    Divider()
                }
                wholeSeries
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
            wholeSeason(season, compact: true)
        }
        .padding(.vertical, Spacing.xs)
    }

    // Trois rendus par saison, comme pour la liste : rien d'annoncé ≠ chargement raté ≠ les épisodes.
    @ViewBuilder private func episodes(of season: SeasonRowModel) -> some View {
        switch viewModel.episodes[season.number] {
        case .loaded(let rows):
            VStack(alignment: .leading, spacing: 0) {
                episodeRows(rows, in: season.number)
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

    // Un flux n'a pas de saison : ses épisodes se rangent par année, et chaque année se
    // comporte comme une saison — repliable, cochable d'un bloc, avec sa progression.
    @ViewBuilder private func years(of season: SeasonRowModel) -> some View {
        switch viewModel.episodes[season.number] {
        case .loaded(let rows):
            VStack(alignment: .leading, spacing: 0) {
                wholeSeason(season, compact: false)
                ForEach(EpisodeYearGroup.group(rows)) { group in
                    DisclosureGroup(isExpanded: yearBinding(for: group.id)) {
                        episodeRows(group.rows, in: season.number)
                    } label: {
                        yearLabel(group, in: season.number)
                    }
                    Divider()
                }
            }
            .sensoryFeedback(.selection, trigger: season.watchedCount)
        default:
            episodes(of: season)
        }
    }

    private func yearLabel(_ group: EpisodeYearGroup, in season: Int) -> some View {
        HStack(spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: 2) {
                Text(group.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                Text(group.progress)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer(minLength: 0)
            if group.isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accent)
                    .accessibilityLabel(String(localized: "podcast.year.complete"))
            }
            wholeYear(group, in: season)
        }
        .padding(.vertical, Spacing.xs)
    }

    @ViewBuilder private func wholeYear(_ group: EpisodeYearGroup, in season: Int) -> some View {
        Group {
            if group.isComplete {
                Button(String(localized: "series.season.uncheckAll.short"), systemImage: "arrow.uturn.backward") {
                    uncheckingYear = YearToUncheck(year: group.year, season: season)
                }
            } else {
                Button(String(localized: "series.season.checkAll.short"), systemImage: "checkmark.circle") {
                    viewModel.checkYear(group.year, in: season)
                }
            }
        }
        .buttonStyle(.bordered)
        .font(.subheadline.weight(.semibold))
        .labelStyle(.titleOnly)
    }

    private func yearBinding(for id: Int) -> Binding<Bool> {
        Binding(
            get: { expandedYears.contains(id) },
            set: { isOpen in
                if isOpen {
                    expandedYears.insert(id)
                } else {
                    expandedYears.remove(id)
                }
            }
        )
    }

    private func episodeRows(_ rows: [EpisodeRowModel], in season: Int) -> some View {
        ForEach(rows) { row in
            EpisodeRow(model: row,
                       toggle: { viewModel.toggle(episode: row.number, in: season) },
                       checkUpTo: { viewModel.checkUpTo(episode: row.number, in: season) })
        }
    }

    // « J'ai vu toute la saison » sur l'en-tête, visible repliée comme dépliée : « quand je
    // ferme l'onglet d'une saison je peux pas ajouter toute la saison » (founder, 30/09).
    // Décocher est destructeur : ça se confirme.
    // Sur l'en-tête, la phrase entière ne tient pas à côté du titre : le bouton se raccourcit.
    // Un podcast, lui, n'a pas d'en-tête — son bouton reste dans la liste, en toutes lettres.
    @ViewBuilder private func wholeSeason(_ season: SeasonRowModel, compact: Bool) -> some View {
        Group {
            if season.isComplete {
                Button(compact ? String(localized: "series.season.uncheckAll.short")
                               : String(localized: "series.season.uncheckAll"),
                       systemImage: "arrow.uturn.backward") {
                    uncheckingSeason = season.number
                }
            } else {
                Button(compact ? String(localized: "series.season.checkAll.short")
                               : viewModel.kind.checkEverythingLabel,
                       systemImage: "checkmark.circle") {
                    Task { await viewModel.checkSeason(season.number) }
                }
            }
        }
        .buttonStyle(.bordered)
        .font(.subheadline.weight(.semibold))
        .labelStyle(.titleOnly)
        .padding(.vertical, compact ? 0 : Spacing.s)
    }

    private var isUncheckingYear: Binding<Bool> {
        Binding(get: { uncheckingYear != nil }, set: { if !$0 { uncheckingYear = nil } })
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
