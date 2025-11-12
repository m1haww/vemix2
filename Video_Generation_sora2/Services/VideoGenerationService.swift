import Foundation
import UIKit

enum VideoProvider: String, CaseIterable {
    case veo = "Google Veo"
    case runway = "Runway"
    case pixverse = "PixVerse"
    case vidu = "Vidu"

    var displayName: String {
        return self.rawValue
    }

    var icon: String {
        switch self {
        case .veo: return "sparkles"
        case .runway: return "wand.and.rays"
        case .pixverse: return "star.fill"
        case .vidu: return "play.rectangle.fill"
        }
    }
    
    var supportsImageInput: Bool {
        switch self {
        case .veo, .runway: return true
        case .pixverse, .vidu: return false
        }
    }
}

final class VideoGenerationService {
    static let shared = VideoGenerationService()

    private init() {}

    func generateVideoFromText(
        prompt: String,
        provider: VideoProvider,
        veoModel: GoogleCloudConfig.VeoModel? = nil,
        runwayModel: RunwayModel? = nil,
        pixverseModel: PixVerseModel? = nil,
        viduModel: ViduModel? = nil,
        aspectRatio: String,
        duration: Int,
        generateAudio: Bool = true
    ) async throws -> VideoGenerationTask {
        switch provider {
        case .veo:
            let veoRatio = VeoAspectRatio(rawValue: aspectRatio) ?? .landscape16x9
            let operationId = try await VeoAPIService.shared.generateVideoFromText(
                prompt: prompt,
                model: veoModel ?? .veo3Fast,
                aspectRatio: veoRatio,
                durationSeconds: duration,
                generateAudio: generateAudio
            )
            return VideoGenerationTask(
                id: operationId,
                provider: .veo,
                prompt: prompt,
                startTime: Date()
            )

        case .runway:
            throw VideoGenerationError.unsupportedProvider("Runway only supports image-to-video generation")

        case .pixverse:
            guard let pixverseRatio = PixVerseAspectRatio(rawValue: aspectRatio) else {
                throw VideoGenerationError.invalidAspectRatio
            }
            let response = try await PixVerseAPIService.shared.generateVideoFromText(
                prompt: prompt,
                model: pixverseModel ?? .v45,
                aspectRatio: pixverseRatio,
                duration: duration
            )
            guard let videoId = response.resp?.videoId else {
                throw VideoGenerationError.invalidResponse
            }
            return VideoGenerationTask(
                id: String(videoId),
                provider: .pixverse,
                prompt: prompt,
                startTime: Date()
            )

        case .vidu:
            guard let viduRatio = ViduAspectRatio(rawValue: aspectRatio) else {
                throw VideoGenerationError.invalidAspectRatio
            }
            let response = try await ViduAPIService.shared.generateVideoFromText(
                prompt: prompt,
                model: viduModel ?? .vidu15,
                duration: duration,
                aspectRatio: viduRatio,
                bgm: generateAudio
            )
            return VideoGenerationTask(
                id: response.taskId,
                provider: .vidu,
                prompt: prompt,
                startTime: Date()
            )
        }
    }

    func generateVideoFromImage(
        image: UIImage,
        prompt: String? = nil,
        provider: VideoProvider,
        veoModel: GoogleCloudConfig.VeoModel? = nil,
        runwayModel: RunwayModel? = nil,
        aspectRatio: String,
        duration: Int,
        generateAudio: Bool = true
    ) async throws -> VideoGenerationTask {
        switch provider {
        case .veo:
            let veoRatio = VeoAspectRatio(rawValue: aspectRatio) ?? .landscape16x9
            let operationId = try await VeoAPIService.shared.generateVideoFromImage(
                image: image,
                prompt: prompt,
                model: veoModel ?? .veo3Fast,
                aspectRatio: veoRatio,
                durationSeconds: duration,
                generateAudio: generateAudio
            )
            return VideoGenerationTask(
                id: operationId,
                provider: .veo,
                prompt: prompt,
                image: image,
                startTime: Date()
            )

        case .runway:
            guard let runwayRatio = RunwayAspectRatio(rawValue: aspectRatio) else {
                throw VideoGenerationError.invalidAspectRatio
            }
            let response = try await RunwayAPIService.shared.generateVideoFromImage(
                image: image,
                prompt: prompt,
                model: runwayModel ?? .gen3aTurbo,
                aspectRatio: runwayRatio,
                duration: duration
            )
            return VideoGenerationTask(
                id: response.id,
                provider: .runway,
                prompt: prompt,
                image: image,
                startTime: Date()
            )

        case .pixverse:
            throw VideoGenerationError.unsupportedProvider("PixVerse does not support image-to-video generation")

        case .vidu:
            throw VideoGenerationError.unsupportedProvider("Vidu does not support image-to-video generation")
        }
    }

    func checkTaskStatus(task: VideoGenerationTask) async throws -> VideoGenerationStatus {
        switch task.provider {
        case .veo:
            let status = try await VeoAPIService.shared.getOperationStatus(operationName: task.id)
            return VideoGenerationStatus(
                isComplete: status.done ?? false,
                progress: nil,
                videoURL: status.response?.videos?.first?.gcsUri,
                error: status.error?.message,
                metadata: nil
            )

        case .runway:
            let status = try await RunwayAPIService.shared.getTaskStatus(taskId: task.id)

            return VideoGenerationStatus(
                isComplete: status.status == .succeeded || status.status == .failed,
                progress: status.progress,
                videoURL: status.output?.first,
                error: status.failure,
                metadata: nil
            )

        case .pixverse:
            guard let videoId = Int64(task.id) else {
                throw VideoGenerationError.invalidTaskId
            }
            let status = try await PixVerseAPIService.shared.getVideoStatus(videoId: videoId)

            if status.errCode != 0 {
                throw VideoGenerationError.serverError(status.errMsg)
            }

            guard let resp = status.resp else {
                throw VideoGenerationError.invalidResponse
            }

            let errorMessage: String? = {
                switch resp.videoStatus {
                case .failed: return "Video generation failed"
                case .moderationFailed: return "Content moderation failed"
                default: return nil
                }
            }()

            return VideoGenerationStatus(
                isComplete: resp.videoStatus == .success,
                progress: resp.videoStatus == .generating ? 0.5 : (resp.videoStatus == .success ? 1.0 : 0.1),
                videoURL: resp.url,
                error: errorMessage,
                metadata: (resp.outputWidth != nil && resp.outputHeight != nil) ? VideoMetadata(
                    durationMs: nil,
                    fps: nil,
                    frameCount: nil,
                    dimensions: [resp.outputWidth!, resp.outputHeight!]
                ) : nil
            )

        case .vidu:
            let status = try await ViduAPIService.shared.getTaskStatus(taskId: task.id)

            let errorMessage: String? = {
                if status.state == "failed" {
                    if let errCode = status.errCode, !errCode.isEmpty {
                        return errCode
                    }
                    return "Video generation failed"
                }
                return nil
            }()

            let progress: Double? = {
                switch status.state {
                case "created", "queueing": return 0.1
                case "processing": return 0.5
                case "success": return 1.0
                case "failed": return nil
                default: return 0.1
                }
            }()

            let videoURL: String? = status.creations?.first?.url
            let thumbnailURL: String? = status.creations?.first?.coverUrl

            return VideoGenerationStatus(
                isComplete: status.state == "success",
                progress: progress,
                videoURL: videoURL,
                error: errorMessage,
                metadata: thumbnailURL != nil ? VideoMetadata(
                    durationMs: nil,
                    fps: nil,
                    frameCount: nil,
                    dimensions: [],
                    thumbnailURL: thumbnailURL
                ) : nil
            )

        }
    }

    func pollTaskUntilComplete(
        task: VideoGenerationTask,
        pollInterval: TimeInterval? = nil,
        timeout: TimeInterval = 300.0,
        progressHandler: ((Double?) -> Void)? = nil
    ) async throws -> VideoGenerationStatus {
        switch task.provider {
        case .veo:
            let status = try await VeoAPIService.shared.pollOperationUntilComplete(
                operationName: task.id,
                pollInterval: pollInterval ?? 2.0,
                timeout: timeout
            )
            return VideoGenerationStatus(
                isComplete: true,
                progress: 1.0,
                videoURL: status.response?.videos?.first?.gcsUri,
                error: nil,
                metadata: nil
            )

        case .runway:
            let status = try await RunwayAPIService.shared.pollTaskUntilComplete(
                taskId: task.id,
                pollInterval: pollInterval ?? 5.0,
                timeout: timeout,
                progressHandler: progressHandler
            )

            return VideoGenerationStatus(
                isComplete: true,
                progress: status.status == .succeeded ? 1.0 : (status.progress ?? 0.0),
                videoURL: status.output?.first,
                error: status.failure,
                metadata: nil
            )

        case .pixverse:
            guard let videoId = Int64(task.id) else {
                throw VideoGenerationError.invalidTaskId
            }
            let status = try await PixVerseAPIService.shared.pollVideoUntilComplete(
                videoId: videoId,
                pollInterval: pollInterval ?? 3.0,
                timeout: timeout,
                progressHandler: progressHandler
            )

            guard let resp = status.resp else {
                throw VideoGenerationError.invalidResponse
            }

            return VideoGenerationStatus(
                isComplete: true,
                progress: 1.0,
                videoURL: resp.url,
                error: nil,
                metadata: (resp.outputWidth != nil && resp.outputHeight != nil) ? VideoMetadata(
                    durationMs: nil,
                    fps: nil,
                    frameCount: nil,
                    dimensions: [resp.outputWidth!, resp.outputHeight!]
                ) : nil
            )

        case .vidu:
            let status = try await ViduAPIService.shared.pollTaskUntilComplete(
                taskId: task.id,
                pollInterval: pollInterval ?? 3.0,
                timeout: timeout,
                progressHandler: progressHandler
            )

            let videoURL: String? = status.creations?.first?.url
            let thumbnailURL: String? = status.creations?.first?.coverUrl

            return VideoGenerationStatus(
                isComplete: true,
                progress: 1.0,
                videoURL: videoURL,
                error: nil,
                metadata: thumbnailURL != nil ? VideoMetadata(
                    durationMs: nil,
                    fps: nil,
                    frameCount: nil,
                    dimensions: [],
                    thumbnailURL: thumbnailURL
                ) : nil
            )

        }
    }

    func getAvailableAspectRatios(for provider: VideoProvider) -> [String: String] {
        switch provider {
        case .veo:
            return Dictionary(uniqueKeysWithValues: VeoAspectRatio.allCases.map {
                ($0.rawValue, $0.displayName)
            })
        case .runway:
            return Dictionary(uniqueKeysWithValues: RunwayAspectRatio.allCases.map {
                ($0.rawValue, $0.displayName)
            })
        case .pixverse:
            return Dictionary(uniqueKeysWithValues: PixVerseAspectRatio.allCases.map {
                ($0.rawValue, $0.displayName)
            })
        case .vidu:
            return Dictionary(uniqueKeysWithValues: ViduAspectRatio.allCases.map {
                ($0.rawValue, $0.displayName)
            })
        }
    }

    func getAvailableDurations(for provider: VideoProvider) -> [Int] {
        switch provider {
        case .veo:
            return [8]
        case .runway:
            return [5, 10]
        case .pixverse:
            return [5, 8]
        case .vidu:
            return [4, 5, 8]
        }
    }
}

struct VideoGenerationTask {
    let id: String
    let provider: VideoProvider
    let prompt: String?
    let image: UIImage?
    let startTime: Date

    init(id: String, provider: VideoProvider, prompt: String? = nil, image: UIImage? = nil, startTime: Date = Date()) {
        self.id = id
        self.provider = provider
        self.prompt = prompt
        self.image = image
        self.startTime = startTime
    }
}

struct VideoGenerationStatus {
    let isComplete: Bool
    let progress: Double?
    let videoURL: String?
    let error: String?
    let metadata: VideoMetadata?
}

struct VideoMetadata {
    let durationMs: Int?
    let fps: Int?
    let frameCount: Int?
    let dimensions: [Int]?
    let thumbnailURL: String?
    
    init(durationMs: Int? = nil, fps: Int? = nil, frameCount: Int? = nil, dimensions: [Int]? = nil, thumbnailURL: String? = nil) {
        self.durationMs = durationMs
        self.fps = fps
        self.frameCount = frameCount
        self.dimensions = dimensions
        self.thumbnailURL = thumbnailURL
    }
}

enum VideoGenerationError: LocalizedError {
    case invalidAspectRatio
    case providerNotAvailable
    case taskNotFound
    case invalidTaskId
    case invalidResponse
    case serverError(String)
    case unsupportedProvider(String)

    var errorDescription: String? {
        switch self {
        case .invalidAspectRatio:
            return "Invalid aspect ratio for selected provider"
        case .providerNotAvailable:
            return "Selected provider is not available"
        case .taskNotFound:
            return "Generation task not found"
        case .invalidTaskId:
            return "Invalid task ID format"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unsupportedProvider(let message):
            return message
        }
    }
}

