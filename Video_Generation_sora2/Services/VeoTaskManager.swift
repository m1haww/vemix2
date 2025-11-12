import Foundation
import Combine

class VeoTaskManager: ObservableObject {
    static let shared = VeoTaskManager()

    @Published var activeTasks: [VeoTaskInfo] = []

    private var taskTimers: [String: Timer] = [:]
    private let queue = DispatchQueue(label: "com.veo3.taskmanager", attributes: .concurrent)

    private init() {}

    func addTask(_ operationName: String, prompt: String, style: String? = nil) {
        let newTask = VeoTaskInfo(
            operationName: operationName,
            prompt: prompt,
            style: style,
            status: .pending,
            progress: 0.0,
            createdAt: Date()
        )

        queue.async(flags: .barrier) {
            DispatchQueue.main.async {
                self.activeTasks.append(newTask)
            }
        }

        startMonitoring(operationName: operationName)
    }

    func removeTask(_ operationName: String) {
        queue.async(flags: .barrier) {
            self.taskTimers[operationName]?.invalidate()
            self.taskTimers[operationName] = nil

            DispatchQueue.main.async {
                self.activeTasks.removeAll { $0.operationName == operationName }
            }
        }
    }

    private func updateTask(_ operationName: String, update: @escaping (inout VeoTaskInfo) -> Void) {
        queue.async(flags: .barrier) {
            DispatchQueue.main.async {
                if let index = self.activeTasks.firstIndex(where: { $0.operationName == operationName }) {
                    update(&self.activeTasks[index])
                }
            }
        }
    }

    private func startMonitoring(operationName: String) {
        let timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task {
                await self.checkTaskStatus(operationName: operationName)
            }
        }

        queue.async(flags: .barrier) {
            self.taskTimers[operationName] = timer
        }
    }

    private func checkTaskStatus(operationName: String) async {
        do {
            let status = try await VeoAPIService.shared.getOperationStatus(operationName: operationName)

            let progress: Double
            let taskStatus: VeoTaskStatus

            if status.done == true {
                progress = 1.0
                if status.response?.videos?.isEmpty == false {
                    taskStatus = .completed
                } else if let filteredCount = status.response?.raiMediaFilteredCount, filteredCount > 0 {
                    taskStatus = .failed
                } else {
                    taskStatus = .failed
                }
            } else {
                progress = 0.5
                taskStatus = .running
            }

            updateTask(operationName) { task in
                task.status = taskStatus
                task.progress = progress
                if taskStatus == .completed {
                    task.completedAt = Date()
                    if let video = status.response?.videos?.first {
                        task.outputBase64 = video.bytesBase64Encoded
                        task.outputURL = video.gcsUri
                        
                        if let base64Data = video.bytesBase64Encoded {
                            task.localFilePath = VideoSaveHelper.shared.saveBase64Video(base64Data: base64Data, modelPrefix: "veo")
                        }
                    }
                } else if taskStatus == .failed {
                    task.failureReason = "Video generation failed"
                }
            }

            if taskStatus == .completed || taskStatus == .failed {
                queue.async(flags: .barrier) {
                    self.taskTimers[operationName]?.invalidate()
                    self.taskTimers[operationName] = nil
                }
            }
        } catch {
            if let urlError = error as? URLError,
               (urlError.code == .timedOut || urlError.code == .networkConnectionLost || urlError.code == .notConnectedToInternet) {
                print("Transient network error, will retry on next poll")
                return
            }

            updateTask(operationName) { task in
                task.status = .failed
                task.failureReason = error.localizedDescription
            }

            queue.async(flags: .barrier) {
                self.taskTimers[operationName]?.invalidate()
                self.taskTimers[operationName] = nil
            }
        }
    }
}

struct VeoTaskInfo: Identifiable {
    let id = UUID()
    let operationName: String
    let prompt: String
    let style: String?
    var status: VeoTaskStatus
    var progress: Double
    let createdAt: Date
    var completedAt: Date?
    var outputURL: String?
    var outputBase64: String?
    var localFilePath: String?
    var failureReason: String?
}

enum VeoTaskStatus {
    case pending
    case running
    case completed
    case failed
    case cancelled
}

final class VeoTaskProgressViewModel: ObservableObject {
    @Published var status: VeoOperationStatus?
    @Published var progress: Double = 0.0

    private var timer: Timer?
    private var operationName: String?

    func startMonitoring(operationName: String) {
        self.operationName = operationName
        self.progress = 0.0
        self.status = nil

        Task {
            await checkStatus()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task {
                await self.checkStatus()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        operationName = nil
    }

    private func checkStatus() async {
        guard let operationName = operationName else { return }

        do {
            let status = try await VeoAPIService.shared.getOperationStatus(operationName: operationName)

            await MainActor.run {
                self.status = status

                if status.done == true {
                    self.progress = 1.0
                    self.stopMonitoring()
                } else {
                    self.progress = min(self.progress + 0.05, 0.9)
                }
            }
        } catch {
            print("VeoTaskProgressViewModel polling error: \(error)")

            if let urlError = error as? URLError,
               (urlError.code == .timedOut || urlError.code == .networkConnectionLost || urlError.code == .notConnectedToInternet) {
                print("Transient network error, will retry on next poll")
                return
            }

            await MainActor.run {
                if let data = (error as NSError).userInfo["data"] as? Data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let done = json["done"] as? Bool,
                   done == true {

                    self.progress = 0.0
                    self.stopMonitoring()
                } else {

                    print("Continuing to poll despite error")
                }
            }
        }
    }
}
