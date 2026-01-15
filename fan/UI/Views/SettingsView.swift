import SwiftUI

enum StatusBarDisplayMode: String, CaseIterable {
    case none = "None"
    case temperature = "Temperature"
    case power = "Power Usage"
    case fanSpeedPercentage = "Fan Speed %"
    
    var description: String {
        self.rawValue
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: FanControlViewModel
    @Environment(\.dismiss) var dismiss
    @State private var launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
    @State private var statusBarDisplayMode = UserDefaults.standard.string(forKey: "statusBarDisplayMode") ?? "temperature"
    @State private var monitoringInterval = UserDefaults.standard.double(forKey: "monitoringInterval") > 0 ? UserDefaults.standard.double(forKey: "monitoringInterval") : 1.0
    @State private var enableNotifications = UserDefaults.standard.bool(forKey: "enableNotifications")
    @State private var highTempAlert = UserDefaults.standard.double(forKey: "highTempAlert") > 0 ? UserDefaults.standard.double(forKey: "highTempAlert") : 85.0
    @State private var autoSwitchMode = UserDefaults.standard.bool(forKey: "autoSwitchMode")
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("Settings")
                    .font(.system(size: 16, weight: .bold))
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help("Close Settings")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 12) {
                    // Startup Settings
                    settingCard(
                        icon: "rectangle.and.paperclip",
                        title: "Launch at Login",
                        description: "Automatically start the app when you log in"
                    ) {
                        Toggle("", isOn: $launchAtLogin)
                            .onChange(of: launchAtLogin) { oldValue, newValue in
                                UserDefaults.standard.set(newValue, forKey: "launchAtLogin")
                                viewModel.launchAtLogin = newValue
                                updateLaunchAtLogin(newValue)
                            }
                    }
                    
                    // Status Bar Display Mode
                    settingCard(
                        icon: "menubar.rectangle",
                        title: "Menu Bar Display",
                        description: "What information to show in the status bar"
                    ) {
                        Picker("", selection: $statusBarDisplayMode) {
                            Text("None").tag("none")
                            Text("Temperature").tag("temperature")
                            Text("Power Usage").tag("power")
                            Text("Fan Speed %").tag("fanSpeedPercentage")
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: statusBarDisplayMode) { oldValue, newValue in
                            UserDefaults.standard.set(newValue, forKey: "statusBarDisplayMode")
                        }
                    }
                    
                    // Monitoring Interval
                    settingCard(
                        icon: "timer",
                        title: "Monitoring Interval",
                        description: "How often to check temperatures (seconds)"
                    ) {
                        HStack {
                            Slider(value: $monitoringInterval, in: 0.5...5.0, step: 0.5)
                            Text(String(format: "%.1f", monitoringInterval) + "s")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 40)
                        }
                        .onChange(of: monitoringInterval) { oldValue, newValue in
                            UserDefaults.standard.set(newValue, forKey: "monitoringInterval")
                        }
                    }
                    
                    // High Temperature Alert
                    settingCard(
                        icon: "exclamationmark.triangle.fill",
                        title: "High Temp Alert",
                        description: "Alert threshold temperature (°C)"
                    ) {
                        HStack {
                            Slider(value: $highTempAlert, in: 70...95, step: 1)
                            Text(String(format: "%.0f", highTempAlert) + "°")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 40)
                        }
                        .onChange(of: highTempAlert) { oldValue, newValue in
                            UserDefaults.standard.set(newValue, forKey: "highTempAlert")
                        }
                    }
                    
                    // Enable Notifications
                    settingCard(
                        icon: "bell.fill",
                        title: "Notifications",
                        description: "Show alerts for high temperature events"
                    ) {
                        Toggle("", isOn: $enableNotifications)
                            .onChange(of: enableNotifications) { oldValue, newValue in
                                UserDefaults.standard.set(newValue, forKey: "enableNotifications")
                            }
                    }
                    
                    // Auto Switch Mode
                    settingCard(
                        icon: "arrow.left.arrow.right",
                        title: "Auto Mode Switching",
                        description: "Switch to automatic mode on high temps"
                    ) {
                        Toggle("", isOn: $autoSwitchMode)
                            .onChange(of: autoSwitchMode) { oldValue, newValue in
                                UserDefaults.standard.set(newValue, forKey: "autoSwitchMode")
                            }
                    }
                    
                    Spacer()
                        .frame(height: 8)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
            }
            
            Divider()
                .padding(.horizontal)
            
            // Footer Info
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.7))
                
                Text("Changes apply immediately")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 380, height: 580)
        .background {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                LinearGradient(
                    colors: [Color.blue.opacity(0.03), Color.purple.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    @ViewBuilder
    private func settingCard<Content: View>(
        icon: String,
        title: String,
        description: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue.opacity(0.8))
                    .frame(width: 24, alignment: .center)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                
                Spacer()
            }
            
            content()
                .padding(.leading, 34)
        }
        .padding(12)
        .liquidGlass()
    }
    
    private func updateLaunchAtLogin(_ enabled: Bool) {
        LaunchAtLoginManager.shared.isEnabled = enabled
    }
}

#Preview {
    SettingsView(viewModel: FanControlViewModel())
        .background(Color.black)
}
