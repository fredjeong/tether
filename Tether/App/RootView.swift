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
                MainShellPlaceholder(
                    title: "Today",
                    message: "Your daily check-in will appear here."
                )
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                        .accessibilityIdentifier("tab.today")
                }

                MainShellPlaceholder(
                    title: AppCopy.historyTitle,
                    message: "Your habit history will appear here."
                )
                .tabItem {
                    Label(AppCopy.historyTitle, systemImage: "clock")
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

private struct MainShellPlaceholder: View {
    let title: String
    let message: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                title,
                systemImage: "circle.dotted",
                description: Text(message)
            )
            .navigationTitle(title)
        }
    }
}
