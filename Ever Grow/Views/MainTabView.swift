import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label(LocalizedStrings.today.localized, systemImage: "sun.max")
                }
            
            PastView()
                .tabItem {
                    Label(LocalizedStrings.past.localized, systemImage: "clock.arrow.circlepath")
                }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
    }
} 