import Foundation

struct APIKeys {
    static let runwayAPIKey = "key_12379bbb04ed1094d35c1ec74818715d6421f3fc70e896a180d97cc322ccc4a5bb79937ae4157f2f6d6df2676bdde95d01cf8e735d45c5bbf272f2ec18f01cca"

    static let pixverseAPIKey = "sk-3a78ab47b676dc1adad0487d24d74414"

    static let viduAPIKey = "vda_853129498265128960_6UkoPczufjl06EIQabbvUD80Ruh0AWyp"
    
    static let veo3FastAPIKey = "pollo_njq0946AUjiNdvnU4WLQo39vNmkGkiyUDX9uuv7oFlMq"

    static let sora2APIKey = "pollo_njq0946AUjiNdvnU4WLQo39vNmkGkiyUDX9uuv7oFlMq"

    static func validateKeys() {
        if runwayAPIKey.isEmpty || runwayAPIKey == "" {
            print("⚠️ Warning: Runway API key is not configured")
        }

        if pixverseAPIKey.isEmpty {
            print("⚠️ Warning: PixVerse API key is not configured")
        }
    }
}
