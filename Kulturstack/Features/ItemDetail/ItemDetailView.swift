import SwiftUI

struct ItemDetailView: View {
    @State private var viewModel: ItemDetailViewModel
    @State private var editing: LogReference?
    @State private var isSummaryExpanded = false
    private let services: AppServices

    init(subject: ItemDetailViewModel.Subject, services: AppServices) {
        _viewModel = State(initialValue: ItemDetailViewModel(subject: subject, repository: services.mediaRepository,
                                                             logUseCase: services.logUseCase))
        self.services = services
    }

    init(itemID: UUID, services: AppServices) {
        self.init(subject: .stored(itemID), services: services)
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewModel.load() }
            .sheet(item: $editing, onDismiss: { viewModel.load() }) {
                LogEditView(logID: $0.id, services: services, showsItemLink: false)
            }
            .alert(String(localized: "detail.logAgain.failed"), isPresented: $viewModel.didFailToLog) {}
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .missing:
            EmptyState(
                icon: "trash.slash",
                title: String(localized: "detail.missing.title"),
                message: String(localized: "detail.missing.message")
            )
        case .failed:
            EmptyState(
                icon: "exclamationmark.triangle",
                title: String(localized: "detail.error.title"),
                message: String(localized: "detail.error.message"),
                action: .init(title: String(localized: "common.retry")) { viewModel.load() }
            )
        case .loaded(let model):
            detail(model)
        }
    }

    private func detail(_ model: ItemDetailModel) -> some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                header(model)
                Button(String(localized: model.logs.isEmpty ? "detail.log" : "detail.logAgain"), systemImage: "plus.circle.fill") {
                    viewModel.log()
                }
                .buttonStyle(.borderedProminent)
                .sensoryFeedback(.success, trigger: model.logs.count)
                logs(model.logs)
                if let source = model.source {
                    Text(String(localized: "detail.source \(source)"))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(Spacing.m)
        }
    }

    private func header(_ model: ItemDetailModel) -> some View {
        VStack(spacing: Spacing.s) {
            CoverThumbnail(url: model.coverURL, placeholderSymbol: model.kind.symbol, width: 120)
            Text(model.year.map { String(localized: "log.edit.work \(model.title) \(String($0))") } ?? model.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
            Text(model.headline)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
            ForEach(model.facts, id: \.self) { fact in
                Text(fact)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let summary = model.summary {
                summaryBlock(summary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func summaryBlock(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(summary)
                .font(.body)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(isSummaryExpanded ? nil : 3)
            Button(String(localized: isSummaryExpanded ? "detail.summary.less" : "detail.summary.more")) {
                withAnimation { isSummaryExpanded.toggle() }
            }
            .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Spacing.s)
    }

    private func logs(_ logs: [ItemLogRowModel]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(String(localized: "detail.logs.title"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)
            if logs.isEmpty {
                Text(String(localized: "detail.logs.empty"))
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            ForEach(logs) { log in
                Button {
                    editing = LogReference(id: log.id)
                } label: {
                    ItemLogRow(model: log)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
