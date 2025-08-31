import Flutter
import Foundation
import SystemConfiguration
import WebKit
import CoreTelephony
import Darwin

public class DeviceNetworkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "kontext_flutter_sdk/device_network",
            binaryMessenger: registrar.messenger()
        )
        let instance = DeviceNetworkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getNetworkInfo":
            fetchUserAgent { ua in
                let type = self.currentNetworkType()
                let (detail, carrier) = self.radioDetailAndCarrier()

                let payload: [String: Any] = [
                    "userAgent": ua,
                    "type": type,
                    "detail": (detail as Any?) ?? NSNull(),
                    "carrier": (carrier as Any?) ?? NSNull()
                ]
                result(payload)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - User Agent

    private func fetchUserAgent(_ completion: @escaping (String) -> Void) {
        func fallbackUA() -> String {
            if let custom = Bundle.main.object(forInfoDictionaryKey: "UserAgent") as? String,
            !custom.isEmpty {
                return custom
            }
            let dev = UIDevice.current
            let os = dev.systemVersion.replacingOccurrences(of: ".", with: "_")
            let model = (dev.userInterfaceIdiom == .pad) ? "iPad" : "iPhone"
            return "Mozilla/5.0 (\(model); CPU iPhone OS \(os) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile"
        }

        let run = {
            let web = WKWebView(frame: .zero)
            var sent = false

            func finish(_ s: String) {
                if !sent {
                    sent = true
                    completion(s)
                }
            }

            web.evaluateJavaScript("navigator.userAgent") { value, _ in
                if let ua = value as? String, !ua.isEmpty {
                    finish(ua)
                } else {
                    finish(fallbackUA())
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                if !sent { finish(fallbackUA()) }
            }
        }

        if Thread.isMainThread {
            run()
        } else {
            DispatchQueue.main.async(execute: run)
        }
    }

    // MARK: - Network Type

    private func currentNetworkType() -> String {
        let flags = reachabilityFlags()
        guard flags.contains(.reachable) else { return "other" }
        if flags.contains(.isWWAN) { return "cellular" }
        if hasAddress(onInterfacePrefix: "en") { return "wifi" }
        return "ethernet"
    }

    private func reachabilityFlags() -> SCNetworkReachabilityFlags {
        var zero = sockaddr_in()
        zero.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zero.sin_family = sa_family_t(AF_INET)

        let ref = withUnsafePointer(to: &zero) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }

        var flags = SCNetworkReachabilityFlags()
        if let ref = ref, SCNetworkReachabilityGetFlags(ref, &flags) {
            return flags
        }
        return []
    }

    private func hasAddress(onInterfacePrefix prefix: String) -> Bool {
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return false }
        defer { freeifaddrs(ifaddr) }

        var p = first
        while true {
            let name = String(cString: p.pointee.ifa_name)
            if name.hasPrefix(prefix), p.pointee.ifa_addr != nil { return true }
            if let next = p.pointee.ifa_next {
                p = next
            } else {
                break
            }
        }
        return false
    }

    // MARK: - Radio Detail + Carrier

    private func radioDetailAndCarrier() -> (String?, String?) {
        let info = CTTelephonyNetworkInfo()
        var carrierName: String? = nil

        if #available(iOS 12.0, *) {
            if #available(iOS 13.0, *),
            let dataId = info.dataServiceIdentifier,
            let providers = info.serviceSubscriberCellularProviders,
            let c = providers[dataId],
            let name = c.carrierName, !name.isEmpty {
                carrierName = name
            }
            if carrierName == nil, let providers = info.serviceSubscriberCellularProviders {
                for c in providers.values {
                    if let name = c.carrierName, !name.isEmpty {
                        carrierName = name
                        break
                    }
                }
            }
        } else {
            carrierName = info.subscriberCellularProvider?.carrierName
        }

        var techs: [String] = []
        if #available(iOS 12.0, *) {
            if #available(iOS 13.0, *),
            let dataId = info.dataServiceIdentifier,
            let dict = info.serviceCurrentRadioAccessTechnology,
            let t = dict[dataId] {
                techs.append(t)
            }
            if techs.isEmpty, let dict = info.serviceCurrentRadioAccessTechnology {
                techs.append(contentsOf: dict.values)
            }
        } else if let t = info.currentRadioAccessTechnology {
            techs = [t]
        }

        guard !techs.isEmpty else { return (nil, carrierName) }
        return (mapRATsToDetail(techs), carrierName)
    }

    private func mapRATsToDetail(_ techs: [String]) -> String {
        let s = Set(techs)

        if #available(iOS 14.1, *) {
            if s.contains(CTRadioAccessTechnologyNR) || s.contains(CTRadioAccessTechnologyNRNSA) {
                return "nr"
            }
        } else {
            if s.contains("CTRadioAccessTechnologyNR") || s.contains("CTRadioAccessTechnologyNRNSA") {
                return "nr"
            }
        }

        if s.contains(CTRadioAccessTechnologyLTE) { return "lte" }

        if s.contains(CTRadioAccessTechnologyHSDPA)
        || s.contains(CTRadioAccessTechnologyHSUPA) {
            return "hspa"
        }

        if s.contains(CTRadioAccessTechnologyEdge) { return "edge" }
        if s.contains(CTRadioAccessTechnologyGPRS) { return "gprs" }

        let threeG: Set<String> = [
            CTRadioAccessTechnologyWCDMA,
            CTRadioAccessTechnologyCDMAEVDORev0,
            CTRadioAccessTechnologyCDMAEVDORevA,
            CTRadioAccessTechnologyCDMAEVDORevB,
            CTRadioAccessTechnologyCDMA1x,
            CTRadioAccessTechnologyeHRPD
        ]
        if !s.intersection(threeG).isEmpty { return "3g" }

        if s.contains("CTRadioAccessTechnologyCDMA1x") { return "2g" }

        return "unknown"
    }
}
