import SwiftUI
import UIKit

enum AppAppearance {
    static func configure() {
        let background = UIColor(Palette.background)
        let accent = UIColor(Palette.lime)
        let navigation = UINavigationBarAppearance()
        navigation.configureWithOpaqueBackground()
        navigation.backgroundColor = background
        navigation.shadowColor = .clear
        navigation.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigation.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = navigation
        navigationBar.scrollEdgeAppearance = navigation
        navigationBar.compactAppearance = navigation
        navigationBar.compactScrollEdgeAppearance = navigation
        navigationBar.tintColor = accent
        navigationBar.isTranslucent = false

        let tabs = UITabBarAppearance()
        tabs.configureWithOpaqueBackground()
        tabs.backgroundColor = background
        tabs.shadowColor = .clear
        for item in [tabs.stackedLayoutAppearance, tabs.inlineLayoutAppearance, tabs.compactInlineLayoutAppearance] {
            item.normal.iconColor = UIColor(Palette.muted)
            item.normal.titleTextAttributes = [.foregroundColor: UIColor(Palette.muted)]
            item.selected.iconColor = accent
            item.selected.titleTextAttributes = [.foregroundColor: accent]
        }
        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tabs
        tabBar.scrollEdgeAppearance = tabs
        tabBar.tintColor = accent
        tabBar.unselectedItemTintColor = UIColor(Palette.muted)
        tabBar.isTranslucent = false

        let toolbar = UIToolbarAppearance()
        toolbar.configureWithOpaqueBackground()
        toolbar.backgroundColor = background
        toolbar.shadowColor = .clear
        UIToolbar.appearance().standardAppearance = toolbar
        UIToolbar.appearance().compactAppearance = toolbar
        UIToolbar.appearance().scrollEdgeAppearance = toolbar
        UIToolbar.appearance().compactScrollEdgeAppearance = toolbar
    }
}

struct AppSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Palette.background.ignoresSafeArea())
            .foregroundStyle(.white)
            .preferredColorScheme(.dark)
            .environment(\.colorScheme, .dark)
            .toolbarColorScheme(.dark, for: .navigationBar, .tabBar)
            .toolbarBackground(Palette.background, for: .navigationBar, .tabBar)
            .toolbarBackground(.visible, for: .navigationBar, .tabBar)
    }
}

extension View {
    func appSurface() -> some View { modifier(AppSurface()) }
}
