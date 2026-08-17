import SwiftUI

struct RootView: View {
    private let environment: AppEnvironment
    @State private var appModel: AppModel

    init(environment: AppEnvironment) {
        self.environment = environment
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
                        onCreated: appModel.didCreateHabit
                    )
                }
            }
        case .main:
            TabView {
                NavigationStack {
                    TodayView(environment: environment)
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
