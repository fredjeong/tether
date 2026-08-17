import Foundation
import SwiftUI
import UIKit

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
        if CommandLine.arguments.contains("-ui-testing-seed-reminder") {
            environment.reminderSettingsStore.save(
                ReminderSettings(isEnabled: true, hour: 20, minute: 0)
            )
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
            .background(
                TabAccessibilityIdentifierConfigurator(
                    identifiers: ["tab.today", "tab.history"]
                )
            )
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

private struct TabAccessibilityIdentifierConfigurator: UIViewControllerRepresentable {
    let identifiers: [String]

    func makeUIViewController(context: Context) -> ConfiguratorViewController {
        ConfiguratorViewController(identifiers: identifiers)
    }

    func updateUIViewController(
        _ viewController: ConfiguratorViewController,
        context: Context
    ) {
        viewController.identifiers = identifiers
        viewController.configureIdentifiers()
    }

    @MainActor
    final class ConfiguratorViewController: UIViewController {
        var identifiers: [String]

        init(identifiers: [String]) {
            self.identifiers = identifiers
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            configureIdentifiers()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            configureIdentifiers()
        }

        func configureIdentifiers() {
            guard let tabBarController = findTabBarController(
                from: view.window?.rootViewController
            ) else {
                return
            }

            if #available(iOS 18.0, *) {
                for (tab, identifier) in zip(tabBarController.tabs, identifiers)
                where tab.accessibilityIdentifier != identifier {
                    tab.accessibilityIdentifier = identifier
                }
            }

            for (item, identifier) in zip(
                tabBarController.tabBar.items ?? [],
                identifiers
            ) where item.accessibilityIdentifier != identifier {
                item.accessibilityIdentifier = identifier
            }
        }

        private func findTabBarController(
            from viewController: UIViewController?
        ) -> UITabBarController? {
            guard let viewController else {
                return nil
            }
            if let tabBarController = viewController as? UITabBarController {
                return tabBarController
            }
            for child in viewController.children {
                if let tabBarController = findTabBarController(from: child) {
                    return tabBarController
                }
            }
            if let presentedViewController = viewController.presentedViewController {
                return findTabBarController(from: presentedViewController)
            }
            return nil
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
