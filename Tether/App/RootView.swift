import Foundation
import SwiftUI

struct RootView: View {
    private let environment: AppEnvironment
    @Environment(\.scenePhase) private var scenePhase
    @State private var appModel: AppModel
    @State private var isPresentingSettings = false
    @State private var lifecycleRefreshTask: Task<Void, Never>?

    init(environment: AppEnvironment) {
        self.environment = environment
        if CommandLine.arguments.contains("-ui-testing-reset") {
            environment.reminderSettingsStore.reset()
        }
        let appModel = AppModel(environment: environment)
        do {
            try appModel.load()
        } catch {}
        _appModel = State(initialValue: appModel)
    }

    var body: some View {
        switch appModel.rootContent {
        case .startupError:
            StartupErrorView(
                message: appModel.startupErrorMessage ?? AppCopy.startupLoadError,
                retry: { load(appModel) }
            )
        case .onboarding:
            NavigationStack {
                WelcomeView {
                    appModel.presentHabitSetup()
                }
                .navigationDestination(isPresented: habitSetupPresentation) {
                    HabitSetupView(
                        environment: environment,
                        onCreated: appModel.didCreateHabit,
                        onReminderError: appModel.setReminderError
                    )
                }
            }
        case .main:
            TabView {
                NavigationStack {
                    TodayView(environment: environment)
                        .id("\(appModel.habit?.updatedAt.timeIntervalSinceReferenceDate ?? 0)-\(appModel.lifecycleRefreshID)")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    isPresentingSettings = true
                                } label: {
                                    Image(systemName: "gearshape")
                                }
                                .accessibilityLabel(AppCopy.settingsTitle)
                                .accessibilityIdentifier("settings.open")
                            }
                        }
                        .sheet(isPresented: $isPresentingSettings) {
                            NavigationStack {
                                SettingsView(
                                    environment: environment,
                                    onHabitSaved: appModel.didUpdateHabit,
                                    onReset: {
                                        appModel.didReset()
                                        isPresentingSettings = false
                                    }
                                )
                            }
                        }
                }
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                        .accessibilityIdentifier("tab.today")
                }

                NavigationStack {
                    HistoryView(environment: environment)
                }
                .tabItem {
                    Label(AppCopy.historyTitle, systemImage: "clock")
                        .accessibilityIdentifier("tab.history")
                }
            }
            .overlay(alignment: .top) {
                if let reminderErrorMessage = appModel.reminderErrorMessage {
                    ErrorBanner(message: reminderErrorMessage)
                        .padding()
                }
            }
            .onAppear(perform: refreshForLifecycleEvent)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    refreshForLifecycleEvent()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                refreshForLifecycleEvent()
            }
            .onDisappear {
                lifecycleRefreshTask?.cancel()
                lifecycleRefreshTask = nil
            }
        }
    }

    private func load(_ appModel: AppModel) {
        do {
            try appModel.load()
        } catch {}
    }

    private var habitSetupPresentation: Binding<Bool> {
        Binding(
            get: { appModel.isPresentingHabitSetup },
            set: { isPresented in
                if isPresented {
                    appModel.presentHabitSetup()
                } else {
                    appModel.dismissHabitSetup()
                }
            }
        )
    }

    private func refreshForLifecycleEvent() {
        lifecycleRefreshTask?.cancel()
        lifecycleRefreshTask = Task { @MainActor in
            guard !Task.isCancelled else {
                return
            }
            await appModel.refreshForCurrentDay()
        }
    }
}

private struct StartupErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ErrorBanner(message: message)
            Button(AppCopy.retryAction, action: retry)
        }
        .padding()
    }
}
