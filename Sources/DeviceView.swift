import SwiftUI
import UIKit

// MARK: - Live device metrics

final class DeviceMonitor: ObservableObject {
    @Published var batteryLevel: Double = 0
    @Published var batteryState: String = "unknown"
    @Published var lowPower: Bool = false
    @Published var thermal: String = "nominal"
    @Published var freeGB: Double = 0
    @Published var totalGB: Double = 0
    @Published var usedPercent: Double = 0
    @Published var physicalGB: Double = 0
    @Published var uptime: String = "—"
    @Published var model: String = "—"
    @Published var osVersion: String = "—"
    @Published var cores: Int = 0

    private var timer: Timer?

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    deinit { timer?.invalidate() }

    func refresh() {
        let d = UIDevice.current

        batteryLevel = Double(d.batteryLevel)
        switch d.batteryState {
        case .charging: batteryState = "Charging"
        case .full: batteryState = "Full"
        case .unplugged: batteryState = "Unplugged"
        default: batteryState = "Unknown"
        }
        lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        thermal = Self.thermalLabel(ProcessInfo.processInfo.thermalState)
        physicalGB = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824
        cores = ProcessInfo.processInfo.activeProcessorCount
        model = Self.machineIdentifier()
        osVersion = "\(d.systemName) \(d.systemVersion)"

        let up = ProcessInfo.processInfo.systemUptime
        let days = Int(up) / 86_400
        let hours = (Int(up) % 86_400) / 3_600
        let mins = (Int(up) % 3_600) / 60
        uptime = days > 0 ? "\(days)d \(hours)h" : "\(hours)h \(mins)m"

        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let free = attrs[.systemFreeSize] as? NSNumber,
           let total = attrs[.systemSize] as? NSNumber {
            let f = free.doubleValue / 1_073_741_824
            let t = total.doubleValue / 1_073_741_824
            freeGB = f
            totalGB = t
            usedPercent = t > 0 ? ((t - f) / t) * 100 : 0
        }
    }

    static func thermalLabel(_ s: ProcessInfo.ThermalState) -> String {
        switch s {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    static func machineIdentifier() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let mirror = Mirror(reflecting: sysinfo.machine)
        let id = mirror.children.reduce(into: "") { acc, el in
            if let v = el.value as? Int8, v != 0 {
                acc.append(Character(UnicodeScalar(UInt8(v))))
            }
        }
        return id.isEmpty ? "iPhone" : id
    }
}

// MARK: - View

struct DeviceView: View {
    @StateObject private var mon = DeviceMonitor()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                HStack(spacing: 12) {
                    batteryCard
                    thermalCard
                }

                storageCard

                HStack(spacing: 12) {
                    statTile("Memory", String(format: "%.1f GB", mon.physicalGB), "memorychip")
                    statTile("Cores", "\(mon.cores)", "cpu")
                }

                HStack(spacing: 12) {
                    statTile("Uptime", mon.uptime, "clock.arrow.circlepath")
                    statTile("Model", mon.model, "iphone")
                }

                infoRow("System", mon.osVersion)
                infoRow("Low Power Mode", mon.lowPower ? "On" : "Off")

                Spacer(minLength: 8)
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Minis Pulse")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.text)
            Text("Live device telemetry")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textDim)
        }
        .padding(.bottom, 4)
    }

    private var batteryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: batteryIcon)
                    .font(.system(size: 15, weight: .semibold))
                Text("Battery")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(batteryColor)

            Text(mon.batteryLevel < 0 ? "—" : "\(Int(mon.batteryLevel * 100))%")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.text)

            Text(mon.batteryState)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textDim)

            ProgressView(value: max(0, mon.batteryLevel))
                .tint(batteryColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var thermalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "thermometer.medium")
                    .font(.system(size: 15, weight: .semibold))
                Text("Thermal")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(thermalColor)

            Text(mon.thermal)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(mon.lowPower ? "Low Power On" : "Normal")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textDim)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Storage", systemImage: "internaldrive")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent2)
                Spacer()
                Text(String(format: "%.0f%% used", mon.usedPercent))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textDim)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.cardAlt)
                    Capsule()
                        .fill(LinearGradient(colors: [Theme.accent2, Theme.accent],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(6, geo.size.width * min(1, mon.usedPercent / 100)))
                }
            }
            .frame(height: 10)

            HStack {
                Text(String(format: "%.1f GB free", mon.freeGB))
                Spacer()
                Text(String(format: "%.0f GB total", mon.totalGB))
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Theme.textDim)
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func statTile(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.accent)
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textDim)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.text)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var batteryColor: Color {
        if mon.batteryLevel < 0 { return Theme.textDim }
        if mon.batteryLevel < 0.2 { return Theme.danger }
        if mon.batteryLevel < 0.4 { return Theme.warn }
        return Theme.accent2
    }

    private var batteryIcon: String {
        if mon.batteryState == "Charging" || mon.batteryState == "Full" {
            return "battery.100.bolt"
        }
        if mon.batteryLevel < 0 { return "battery.0" }
        if mon.batteryLevel < 0.25 { return "battery.25" }
        if mon.batteryLevel < 0.5 { return "battery.50" }
        if mon.batteryLevel < 0.75 { return "battery.75" }
        return "battery.100"
    }

    private var thermalColor: Color {
        switch mon.thermal {
        case "Nominal": return Theme.accent2
        case "Fair": return Theme.warn
        default: return Theme.danger
        }
    }
}
