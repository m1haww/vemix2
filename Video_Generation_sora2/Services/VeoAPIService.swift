import Foundation
import UIKit

final class VeoAPIService {
    static let shared = VeoAPIService()

    private init() {}

    func generateVideoFromText(
        prompt: String,
        model: GoogleCloudConfig.VeoModel = .veo3Fast,
        aspectRatio: VeoAspectRatio = .landscape16x9,
        durationSeconds: Int = 8,
        enhancePrompt: Bool = true,
        generateAudio: Bool = true,
        sampleCount: Int = 1,
        seed: UInt32? = nil
    ) async throws -> String {
        let resolution = "1080p"
        
        let response = try await Veo3FastAPIService.shared.generateVideoFromText(
            prompt: prompt,
            negativePrompt: nil,
            length: durationSeconds,
            aspectRatio: aspectRatio.rawValue,
            resolution: resolution,
            seed: seed != nil ? Int(seed!) : nil,
            generateAudio: generateAudio
        )
        
        return response.data.taskId
    }

    func generateVideoFromImage(
        image: UIImage,
        prompt: String? = nil,
        model: GoogleCloudConfig.VeoModel = .veo3Fast,
        aspectRatio: VeoAspectRatio = .landscape16x9,
        durationSeconds: Int = 8,
        enhancePrompt: Bool = true,
        generateAudio: Bool = true,
        sampleCount: Int = 1,
        seed: UInt32? = nil
    ) async throws -> String {
        let resolution = "1080p"
        let resizedImage = resizeImageIfNeeded(image)
        
        let uploadResponse = try await Veo3FastAPIService.shared.uploadImage(resizedImage)
        
        let imageUrl = "https://ai-assistant-backend-164860087792.europe-west1.run.app/api/file/get-file?fileName=\(uploadResponse.fileName)"
        
        let response = try await Veo3FastAPIService.shared.generateVideoFromImage(
            imageUrl: imageUrl,
            prompt: prompt ?? "Create a dynamic video from this image",
            negativePrompt: nil,
            length: durationSeconds,
            aspectRatio: aspectRatio.rawValue,
            resolution: resolution,
            seed: seed != nil ? Int(seed!) : nil,
            generateAudio: generateAudio
        )
        
        return response.data.taskId
    }

    func getOperationStatus(operationName: String) async throws -> VeoOperationStatus {
        let status = try await Veo3FastAPIService.shared.getTaskStatus(taskId: operationName)
        
        return mapVeo3FastToVeoStatus(status, operationName: operationName)
    }

    func pollOperationUntilComplete(
        operationName: String,
        pollInterval: TimeInterval = 2.0,
        timeout: TimeInterval = 300.0
    ) async throws -> VeoOperationStatus {
        let status = try await Veo3FastAPIService.shared.pollTaskUntilComplete(
            taskId: operationName,
            pollInterval: pollInterval,
            timeout: timeout
        )
        
        return mapVeo3FastToVeoStatus(status, operationName: operationName)
    }

    private func mapVeo3FastToVeoStatus(_ veo3Status: Veo3FastTaskStatus, operationName: String) -> VeoOperationStatus {
        guard let firstGeneration = veo3Status.data.generations.first else {
            return VeoOperationStatus(
                name: operationName,
                done: false,
                response: nil,
                error: nil
            )
        }
        
        let isDone = firstGeneration.status == .succeed || firstGeneration.status == .failed
        
        var veoError: VeoOperationError? = nil
        if firstGeneration.status == .failed {
            veoError = VeoOperationError(
                code: 500, 
                message: firstGeneration.failMsg ?? "Video generation failed"
            )
        }
        
        var veoResponse: VeoGenerationResponse? = nil
        if firstGeneration.status == .succeed, let videoUrl = firstGeneration.url {
            veoResponse = VeoGenerationResponse(
                type: "GenerateVideoResponse",
                raiMediaFilteredCount: 0,
                raiMediaFilteredReasons: nil,
                videos: [VeoGeneratedVideo(
                    bytesBase64Encoded: nil,
                    gcsUri: videoUrl,
                    mimeType: "video/mp4"
                )]
            )
        }
        
        return VeoOperationStatus(
            name: operationName,
            done: isDone,
            response: veoResponse,
            error: veoError
        )
    }
    
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1280
        let size = image.size

        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }

        let widthRatio = maxDimension / size.width
        let heightRatio = maxDimension / size.height
        let ratio = min(widthRatio, heightRatio)

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? image
    }
}
