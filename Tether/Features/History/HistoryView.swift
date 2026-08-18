import Foundation
import SwiftUI

struct HistoryView: View {
    private let calendar: Calendar
    @State private var viewModel: HistoryViewModel

    init(environment: AppEnvironment) {
        calendar = environment.dayProvider.calendar
        _viewModel = State(initialValue: HistoryViewModel(environment: environment))
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    metricCard(
                        label: AppCopy.currentTetherLabel,
                        value: viewModel.summary.current,
                        identifier: "history.current"
                    )
                    metricCard(
                        label: AppCopy.bestTetherLabel,
                        value: viewModel.summary.best,
                        identifier: "history.best"
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                HStack(spacing: 8) {
                    stateCount(
                        state: .done,
                        count: viewModel.summary.doneCount,
                        identifier: "history.doneCount"
                    )
                    stateCount(
                        state: .light,
                        count: viewModel.summary.lightCount,
                        identifier: "history.lightCount"
                    )
                    stateCount(
                        state: .rest,
                        count: viewModel.summary.restCount,
                        identifier: "history.restCount"
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    ErrorBanner(message: errorMessage)
                }
            }

            Section {
                if viewModel.summary.days.isEmpty {
                    ContentUnavailableView(
                        AppCopy.historyEmptyState,
                        systemImage: "clock"
                    )
                } else {
                    ForEach(viewModel.summary.days) { day in
                        HistoryDayRow(day: day, calendar: calendar)
                    }
                }
            }
        }
        .accessibilityIdentifier("history.list")
        .scrollContentBackground(.hidden)
        .background(TetherTheme.canvas)
        .navigationTitle(AppCopy.historyTitle)
        .onAppear {
            viewModel.load()
        }
    }

    private func metricCard(
        label: String,
        value: Int,
        identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(TetherTheme.textSecondary)
            Text(value, format: .number)
                .font(.title.bold())
                .foregroundStyle(TetherTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .padding()
        .background(TetherTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(TetherTheme.separator, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value)")
        .accessibilityIdentifier(identifier)
    }

    private func stateCount(
        state: CheckInState,
        count: Int,
        identifier: String
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: state.systemImage)
                .foregroundStyle(state.tetherColor)
            Text(state.title)
                .font(.caption)
                .foregroundStyle(TetherTheme.textPrimary)
            Text(count, format: .number)
                .font(.headline)
                .foregroundStyle(TetherTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, minHeight: 76)
        .padding(.vertical, 8)
        .background(TetherTheme.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(TetherTheme.separator, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(state.title), \(count)")
        .accessibilityIdentifier(identifier)
    }
}
