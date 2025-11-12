import Foundation
import AVFoundation

struct NetworkConfiguration {

    static func safeSession(with config: URLSessionConfiguration? = nil) -> URLSession {
        if #available(iOS 18.4, *) {
            let configuration = config ?? URLSessionConfiguration.ephemeral
            return URLSession(configuration: configuration)
        } else {
            let configuration = config ?? URLSessionConfiguration.default
            return URLSession(configuration: configuration)
        }
    }

    static func videoStreamingConfiguration() -> URLSessionConfiguration {
        let config: URLSessionConfiguration
        if #available(iOS 18.4, *) {
            config = URLSessionConfiguration.ephemeral
        } else {
            config = URLSessionConfiguration.default
        }

        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300

        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true

        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: "video_cache"
        )

        return config
    }

    static func videoAssetOptions() -> [String: Any] {
        var options: [String: Any] = [
            AVURLAssetPreferPreciseDurationAndTimingKey: false,
            "AVURLAssetHTTPHeaderFieldsKey": [
                "User-Agent": "VEO3-iOS-App",
                "Accept": "video/*"
            ]
        ]

        if #available(iOS 13.0, *) {
            options[AVURLAssetAllowsCellularAccessKey] = true
        }

        if #available(iOS 14.0, *) {
            options[AVURLAssetAllowsExpensiveNetworkAccessKey] = true
            options[AVURLAssetAllowsConstrainedNetworkAccessKey] = true
        }

        options["AVURLAssetHTTPCookiesKey"] = HTTPCookieStorage.shared.cookies ?? []

        return options
    }
}
