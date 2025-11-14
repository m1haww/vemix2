import SwiftUI

struct VideoGenerationView: View {
    let selectedFilter: FilterItem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VideoGenerationViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with filter info
                        
                        
                        // Video Examples Section
                        videoExamplesSection
                        
                        // Image/Reference Section (only for supported providers)
                        if viewModel.selectedProvider.supportsImageInput {
                            referenceImageSection
                        }
                        
                        // Prompt Section
                        promptSection
                        
                        // AI Models Selection
                        modelSelectionSection
                        
                        // Generation Settings
                        settingsSection
                        
                        // Generate Button
                        generateButton
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Create Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.setupForFilter(selectedFilter)
        }
    }
    
    private var filterHeader: some View {
        VStack(spacing: 16) {
            // Filter preview
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        selectedFilter.isGradient == true ?
                        AnyShapeStyle(LinearGradient(
                            colors: selectedFilter.gradientColorsValues,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )) :
                        AnyShapeStyle(selectedFilter.backgroundColorValue)
                    )
                    .frame(height: 180)
                    .overlay(
                        Group {
                            if let imageName = selectedFilter.imageName {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                        }
                    )
                
                Text(selectedFilter.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Color.black.opacity(0.7)
                            .cornerRadius(12)
                    )
                    .padding(12)
            }
            
            Text("Create a video in this style")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
    
    private var referenceImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reference Image (Optional)")
                .font(.headline)
                .foregroundColor(.white)
            
            if let selectedImage = viewModel.selectedImage {
                // Display selected image with option to change
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button(action: {
                        viewModel.selectedImage = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            } else {
                // Show camera and gallery options
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.showCameraPicker = true
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            Text("Camera")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    Button(action: {
                        viewModel.showImagePicker = true
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            Text("Gallery")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(selectedImage: $viewModel.selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $viewModel.showCameraPicker) {
            ImagePicker(selectedImage: $viewModel.selectedImage, sourceType: .camera)
        }
    }
    
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Video Description")
                .font(.headline)
                .foregroundColor(.white)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                TextEditor(text: $viewModel.prompt)
                    .font(.body)
                    .foregroundColor(.white)
                    .background(Color.clear)
                    .padding(12)
                    .frame(minHeight: 100)
                
                if viewModel.prompt.isEmpty {
                    Text("Describe what you want to see in your video...")
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    private var modelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Model")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Choose your AI")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 8) {
                ForEach(VideoProvider.allCases, id: \.self) { provider in
                    ModelCard(
                        provider: provider,
                        isSelected: viewModel.selectedProvider == provider,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedProvider = provider
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Aspect Ratio
                HStack {
                    Text("Aspect Ratio")
                        .foregroundColor(.white)
                    Spacer()
                    Picker("Aspect Ratio", selection: $viewModel.aspectRatio) {
                        ForEach(viewModel.availableAspectRatios, id: \.key) { ratio in
                            Text(ratio.value).tag(ratio.key)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundColor(.blue)
                }
                
                Divider().background(Color.white.opacity(0.2))
                
                // Duration
                HStack {
                    Text("Duration")
                        .foregroundColor(.white)
                    Spacer()
                    Picker("Duration", selection: $viewModel.duration) {
                        ForEach(viewModel.availableDurations, id: \.self) { duration in
                            Text("\(duration)s").tag(duration)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundColor(.blue)
                }
                
                Divider().background(Color.white.opacity(0.2))
                
                // Generate Audio Toggle
                HStack {
                    Text("Generate Audio")
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $viewModel.generateAudio)
                        .labelsHidden()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    private var generateButton: some View {
        VStack(spacing: 16) {
            if viewModel.isGenerating {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text("Generating your video...")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if viewModel.progress > 0 {
                        ProgressView(value: viewModel.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                            .frame(height: 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(2)
                    }
                }
                .padding(.vertical, 20)
            } else {
                Button(action: {
                    Task {
                        await viewModel.generateVideo()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Generate Video")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "B951E7"), Color(hex: "B951E7")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color(hex: "B951E7").opacity(0.3), radius: 10, x: 0, y: 4)
                }
                .disabled(viewModel.prompt.isEmpty)
                .opacity(viewModel.prompt.isEmpty ? 0.5 : 1.0)
            }
        }
    }
    
    private var videoExamplesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Video Examples")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach(getExampleImages(), id: \.name) { example in
                    Button(action: {
                        viewModel.prompt = example.prompt
                    }) {
                        ZStack(alignment: .bottomLeading) {
                            Image(example.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.black.opacity(0.3))
                                )
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                Spacer()
            }
        }
    }
    
    private func getExampleImages() -> [VideoExample] {
        // Find the category that contains the selected filter
        let categoryId = getCategoryForFilter(selectedFilter.id)
        
        switch categoryId {
        case "ghostface":
            return [
                VideoExample(name: "Cozy Ghost", imageName: "ghost1", prompt: "A friendly ghost floating through a cozy haunted mansion with warm lighting"),
                VideoExample(name: "Mirror Gothic", imageName: "ghost2", prompt: "A mysterious spirit wandering through an enchanted forest at twilight"),
                VideoExample(name: "Movie Night", imageName: "ghost3", prompt: "A playful ghost dancing in an old library filled with magical books")
            ]
        case "aiDance":
            return [
                VideoExample(name: "Dance Style 1", imageName: "dance1", prompt: "An elegant ballet dancer performing in a moonlit ballroom"),
                VideoExample(name: "Dance Style 2", imageName: "dance2", prompt: "Hip-hop dancers showcasing synchronized moves in urban setting"),
                VideoExample(name: "Dance Style 3", imageName: "dance3", prompt: "Contemporary dancers expressing emotion through fluid movements")
            ]
        case "tinyWorkers":
            return [
                VideoExample(name: "Worker 1", imageName: "tiny1", prompt: "Miniature workers building a tiny village with incredible detail"),
                VideoExample(name: "Worker 2", imageName: "tiny2", prompt: "Small creatures having a tea party in a magical garden"),
                VideoExample(name: "Worker 3", imageName: "tiny3", prompt: "Tiny adventurers exploring a vast landscape from their perspective")
            ]
        case "monochrome":
            return [
                VideoExample(name: "Photoshoot 1", imageName: "mono1", prompt: "Black and white cinematic scene with dramatic shadows and lighting"),
                VideoExample(name: "Photoshoot 2", imageName: "mono2", prompt: "Vintage monochrome footage of a bustling city street"),
                VideoExample(name: "Photoshoot 3", imageName: "mono3", prompt: "Artistic monochrome portrait with emotional depth")
            ]
        case "polaroid":
            return [
                VideoExample(name: "Booth Pose 1", imageName: "Polaroid 1", prompt: "A person taking a polaroid photo in a vintage photo booth with retro lighting"),
                VideoExample(name: "Booth Pose 2", imageName: "Polaroid 2", prompt: "Friends laughing and posing in a colorful photo booth"),
                VideoExample(name: "Booth Pose 3", imageName: "Polaroid 3", prompt: "Creative poses and funny faces in a nostalgic photo booth setting")
            ]
        case "trends":
            return [
                VideoExample(name: "Veo 3 ASMR", imageName: "trend1", prompt: "A calming ASMR scene with gentle movements and soothing atmosphere"),
                VideoExample(name: "Live Photo", imageName: "trend2", prompt: "A living photograph that comes to life with subtle animation")
            ]
        case "textToVideo":
            return [
                VideoExample(name: "Veo 3", imageName: "text2v1", prompt: "Create a stunning video using advanced AI technology"),
                VideoExample(name: "Creative AI", imageName: "text2v2", prompt: "An abstract art piece coming to life with flowing colors")
            ]
        default:
            return [
                VideoExample(name: "Creative 1", imageName: "text2v1", prompt: "A surreal dreamscape with floating elements and soft lighting"),
                VideoExample(name: "Creative 2", imageName: "text2v2", prompt: "An abstract art piece coming to life with flowing colors"),
                VideoExample(name: "Dance", imageName: "dance1", prompt: "An energetic dance performance")
            ]
        }
    }
    
    private func getCategoryForFilter(_ filterId: String) -> String {
        // Map filter IDs to their categories based on data.json structure
        switch filterId {
        case "booth1", "booth2", "booth3":
            return "polaroid"
        case "cozy", "mirror", "movie":
            return "ghostface"
        case "photo1", "photomen", "photo2":
            return "monochrome"
        case "veo3asmr", "livephoto":
            return "trends"
        case "veo3":
            return "textToVideo"
        case "dance1", "dance2", "dance3":
            return "aiDance"
        case "tiny1", "tiny2", "tiny3":
            return "tinyWorkers"
        default:
            return "default"
        }
    }
}

struct VideoExample {
    let name: String
    let imageName: String
    let prompt: String
}

struct ModelCard: View {
    let provider: VideoProvider
    let isSelected: Bool
    let action: () -> Void
    
    private var providerColors: [Color] {
        switch provider {
        case .veo:
            return [Color(hex: "B951E7"), Color(hex: "B951E7")]
        case .runway:
            return [Color.green, Color.teal]
        case .pixverse:
            return [Color.orange, Color.red]
        case .vidu:
            return [Color(hex: "B951E7"), Color(hex: "B951E7")]
        }
    }
    
    private var providerDescription: String {
        switch provider {
        case .veo:
            return "Advanced AI"
        case .runway:
            return "Creative AI"
        case .pixverse:
            return "Fast Generation"
        case .vidu:
            return "High Quality"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(provider.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(providerDescription)
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Circle()
                            .fill(LinearGradient(
                                colors: providerColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Gradient bar at bottom
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: isSelected ? providerColors : [Color.white.opacity(0.1), Color.white.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [Color.black.opacity(0.6), Color.black.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? 
                        LinearGradient(
                            colors: providerColors.map { $0.opacity(0.6) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    init(selectedImage: Binding<UIImage?>, sourceType: UIImagePickerController.SourceType = .photoLibrary) {
        self._selectedImage = selectedImage
        self.sourceType = sourceType
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

@MainActor
class VideoGenerationViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var prompt: String = ""
    @Published var selectedProvider: VideoProvider = .veo
    @Published var aspectRatio: String = "16:9"
    @Published var duration: Int = 8
    @Published var generateAudio: Bool = true
    @Published var isGenerating: Bool = false
    @Published var progress: Double = 0.0
    @Published var showImagePicker: Bool = false
    @Published var showCameraPicker: Bool = false
    
    var availableAspectRatios: [(key: String, value: String)] {
        VideoGenerationService.shared.getAvailableAspectRatios(for: selectedProvider).map { ($0.key, $0.value) }
    }
    
    var availableDurations: [Int] {
        VideoGenerationService.shared.getAvailableDurations(for: selectedProvider)
    }
    
    func setupForFilter(_ filter: FilterItem) {
        // Setup based on filter type
        if filter.id.contains("veo") {
            selectedProvider = .veo
        } else if filter.id.contains("runway") {
            selectedProvider = .runway
        } else if filter.id.contains("pixverse") {
            selectedProvider = .pixverse
        } else if filter.id.contains("vidu") {
            selectedProvider = .vidu
        } else {
            selectedProvider = .veo // default
        }
        
        // Set suggested prompt based on filter
        prompt = generatePromptForFilter(filter)
    }
    
    private func generatePromptForFilter(_ filter: FilterItem) -> String {
        switch filter.id {
        case "booth1", "booth2", "booth3":
            return "A person taking a polaroid photo in a vintage photo booth with retro lighting"
        case "cozy":
            return "A cozy ghost floating peacefully in a warm, inviting room"
        case "mirror":
            return "A gothic mirror reflection scene with mysterious atmosphere"
        case "movie":
            return "A cinematic movie night scene with dramatic lighting"
        case "veo3asmr":
            return "A calming ASMR scene with gentle movements and soothing atmosphere"
        case "livephoto":
            return "A living photograph that comes to life with subtle animation"
        case "veo3":
            return "Create a stunning video using advanced AI technology"
        case "dance1", "dance2", "dance3":
            return "A person performing an energetic dance routine"
        case "tiny1", "tiny2", "tiny3":
            return "Tiny workers busy at work in a miniature world"
        default:
            return "Create an amazing video based on this style"
        }
    }
    
    func generateVideo() async {
        guard !prompt.isEmpty else { return }
        
        isGenerating = true
        progress = 0.0
        
        do {
            let task: VideoGenerationTask
            
            if let image = selectedImage {
                task = try await VideoGenerationService.shared.generateVideoFromImage(
                    image: image,
                    prompt: prompt,
                    provider: selectedProvider,
                    aspectRatio: aspectRatio,
                    duration: duration,
                    generateAudio: generateAudio
                )
            } else {
                task = try await VideoGenerationService.shared.generateVideoFromText(
                    prompt: prompt,
                    provider: selectedProvider,
                    aspectRatio: aspectRatio,
                    duration: duration,
                    generateAudio: generateAudio
                )
            }
            
            let status = try await VideoGenerationService.shared.pollTaskUntilComplete(
                task: task,
                progressHandler: { [weak self] progress in
                    DispatchQueue.main.async {
                        self?.progress = progress ?? 0.0
                    }
                }
            )
            
            if let videoURL = status.videoURL {
                print("Video generated successfully: \(videoURL)")
                // Handle successful generation
            }
            
        } catch {
            print("Error generating video: \(error)")
            // Handle error
        }
        
        isGenerating = false
        progress = 0.0
    }
}
