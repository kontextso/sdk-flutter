import Flutter
import UIKit
import Foundation
import Darwin

public class AppInfoPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "kontext_flutter_sdk/app_info",
            binaryMessenger: registrar.messenger()
        )
        let instance = AppInfoPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getInstallUpdateTimes":
            result(installUpdateTimes())
        case "getProcessStartEpochMs":
            result(processStartEpochMs())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func installUpdateTimes() -> Any {
        let fm = FileManager.default

        func creationDate(_ url: URL?) -> Date? {
            guard let url else { return nil }
            return (try? fm.attributesOfItem(atPath: url.path))?[.creationDate] as? Date
        }

        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first
        let lib = fm.urls(for: .libraryDirectory, in: .userDomainMask).first
        let appSupport = try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )

        let installDate = [creationDate(docs), creationDate(lib), creationDate(appSupport)]
            .compactMap { $0 }
            .min()

        var lastUpdateCandidates = [Date]()

        let bundleURL = Bundle.main.bundleURL
        if let attrs = try? fm.attributesOfItem(atPath: bundleURL.path),
           let d = attrs[.modificationDate] as? Date {
            lastUpdateCandidates.append(d)
        }

        if let execURL = Bundle.main.executableURL,
           let vals = try? execURL.resourceValues(forKeys: [.contentModificationDateKey]),
           let d = vals.contentModificationDate {
            lastUpdateCandidates.append(d)
        }

        if let infoURL = Bundle.main.url(forResource: "Info", withExtension: "plist"),
           let vals = try? infoURL.resourceValues(forKeys: [.contentModificationDateKey, .creationDateKey]) {
            if let d = vals.contentModificationDate ?? vals.creationDate {
                lastUpdateCandidates.append(d)
            }
        }

        let parentURL = bundleURL.deletingLastPathComponent()
        if let attrs = try? fm.attributesOfItem(atPath: parentURL.path),
           let d = attrs[.modificationDate] as? Date {
            lastUpdateCandidates.append(d)
        }

        let lastUpdate = lastUpdateCandidates.max()

        let firstInstallMs: Any =
            installDate.map { NSNumber(value: Int64($0.timeIntervalSince1970 * 1000)) } ?? NSNull()
        let lastUpdateMs: Any =
            lastUpdate.map { NSNumber(value: Int64($0.timeIntervalSince1970 * 1000)) } ?? NSNull()

        return ["firstInstall": firstInstallMs, "lastUpdate": lastUpdateMs]
    }

    private static let pluginInitEpochMs: Int64 = {
        Int64(Date().timeIntervalSince1970 * 1000.0)
    }()

    private func processStartEpochMs() -> Int64? {
        if let ms = processStartViaSysctlMs() { return ms }
        return Self.pluginInitEpochMs
    }

    private func processStartViaSysctlMs() -> Int64? {
        var kp = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]

        let rc = mib.withUnsafeMutableBufferPointer { buf -> Int32 in
            sysctl(buf.baseAddress, u_int(buf.count), &kp, &size, nil, 0)
        }
        guard rc == 0, size == MemoryLayout<kinfo_proc>.stride else { return nil }

        let tv = kp.kp_proc.p_starttime
        let sec = Double(tv.tv_sec)
        let usec = Double(tv.tv_usec)
        return Int64(sec * 1000.0 + usec / 1000.0)
    }
}
