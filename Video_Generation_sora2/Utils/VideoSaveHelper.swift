import Foundation

final class VideoSaveHelper {
    static let shared = VideoSaveHelper()
    
    private init() {}
    
    /// Save video from base64 encoded string to local directory
    func saveBase64Video(base64Data: String, modelPrefix: String) -> String? {
        guard let videoData = Data(base64Encoded: base64Data) else {
            print("[VideoSaveHelper] Failed to decode base64 video data")
            return nil
        }
        
        return saveVideoData(videoData, modelPrefix: modelPrefix)
    }
    
    /// Save video from URL to local directory
    func saveVideoFromURL(_ urlString: String, modelPrefix: String) async -> String? {
        guard let url = URL(string: urlString) else {
            print("[VideoSaveHelper] Invalid URL: \(urlString)")
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return saveVideoData(data, modelPrefix: modelPrefix)
        } catch {
            print("[VideoSaveHelper] Failed to download video from URL: \(error)")
            return nil
        }
    }
    
    /// Save video data to local directory
    private func saveVideoData(_ data: Data, modelPrefix: String) -> String? {
        let fileName = "\(modelPrefix)_\(UUID().uuidString).mp4"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localPath = documentsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: localPath)
            print("[VideoSaveHelper] Video saved successfully to: \(localPath.path)")
            return localPath.path
        } catch {
            print("[VideoSaveHelper] Failed to save video: \(error)")
            return nil
        }
    }
    
    /// Get the documents directory path
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Delete video file at path
    func deleteVideo(at path: String) -> Bool {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: path) {
            do {
                try fileManager.removeItem(atPath: path)
                print("[VideoSaveHelper] Video deleted successfully: \(path)")
                return true
            } catch {
                print("[VideoSaveHelper] Failed to delete video: \(error)")
                return false
            }
        }
        
        return false
    }
    
    /// Check if video exists at path
    func videoExists(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
    
    /// Download thumbnail from URL and return as Data
    func downloadThumbnail(from urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else {
            print("[VideoSaveHelper] Invalid thumbnail URL: \(urlString)")
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Verify we got an image response
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                print("[VideoSaveHelper] Thumbnail downloaded successfully from: \(urlString)")
                return data
            } else {
                print("[VideoSaveHelper] Failed to download thumbnail - invalid response")
                return nil
            }
        } catch {
            print("[VideoSaveHelper] Failed to download thumbnail: \(error)")
            return nil
        }
    }
}