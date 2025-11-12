# Backend Implementation Guide pentru Video Generation Sora 2

## Descrierea Structurii Backend

Backend-ul copiat de la proiectul veo3 oferă o arhitectură completă pentru generarea de videoclipuri folosind multiple providere AI. Această implementare include mai multe servicii integrate pentru diferite modele de AI.

## Providere AI Implementate

### 1. Google Veo (VeoAPIService.swift)
- **Modele supportate:** Veo 2.0, Veo 3.0, Veo 3.0 Fast
- **Funcționalități:** Text-to-video, Image-to-video
- **Aspect ratios:** 16:9 (landscape)
- **Durata:** 8 secunde

### 2. Runway ML (RunwayAPIService.swift)
- **Modele supportate:** Gen-3 Alpha Turbo, Gen-4 Turbo
- **Funcționalități:** Image-to-video, Text-to-video
- **Aspect ratios:** Multiple (16:9, 9:16, 1:1, 4:3, 3:4, 21:9, 5:3, 3:5)
- **Durata:** 5, 10 secunde

### 3. Sora 2 (Sora2ApiService.swift)
- **Model:** Sora 2
- **Funcționalități:** Text-to-video, Image-to-video
- **Aspect ratios:** 16:9, 9:16
- **Durata:** 4, 8, 12 secunde

### 4. Veo3 Fast (Veo3FastAPIService.swift)
- **Model:** Veo 3.0 Fast
- **Funcționalități:** Text-to-video, Image-to-video cu upload
- **Rezoluții:** 720p, 1080p
- **Funcții avansate:** Seed control, negative prompts, audio generation

### 5. PixVerse (PixVerseAPIService.swift)
- **Modele:** V4.5
- **Funcționalități:** Text-to-video
- **Aspect ratios:** Multiple
- **Durata:** 5, 8 secunde

### 6. Vidu (ViduAPIService.swift)
- **Modele:** Vidu 1.5
- **Funcționalități:** Text-to-video
- **Aspect ratios:** Multiple
- **Durata:** 4, 5, 8 secunde

## Componente Cheie

### BackendService.swift
- **Rol:** Service principal pentru comunicarea cu backend-ul centralizat
- **Funcții:** 
  - `generateVideo()` - Generare video folosind Google Veo
  - `getVideoStatus()` - Verificare status operațiune
  - `generateRunwayVideo()` - Generare video folosind Runway
  - `getRunwayTaskStatus()` - Verificare status task Runway

### VideoGenerationService.swift
- **Rol:** Service manager pentru toate providerele AI
- **Funcții unificate:**
  - `generateVideoFromText()` - Generare din text pentru orice provider
  - `generateVideoFromImage()` - Generare din imagine pentru orice provider
  - `checkTaskStatus()` - Verificare status pentru orice provider
  - `pollTaskUntilComplete()` - Polling automat până la finalizare

### APIKeys.swift
```swift
struct APIKeys {
    static let runwayAPIKey = "..."
    static let pixverseAPIKey = "..."
    static let viduAPIKey = "..."
    static let veo3FastAPIKey = "..."
    static let sora2APIKey = "..."
}
```

### GoogleCloudConfig.swift
```swift
struct GoogleCloudConfig {
    enum VeoModel: String {
        case veo2Generate = "veo-2.0-generate-001"
        case veo3Generate = "veo-3.0-generate-preview"
        case veo3Fast = "veo-3.0-fast-generate-preview"
    }
}
```

## Modele de Date

### VeoModels.swift
- **VeoVideoGenerationRequest** - Request pentru Google Veo
- **VeoOperationResponse** - Response pentru operațiuni
- **VeoAspectRatio** - Enum pentru aspect ratios
- **VeoPersonGeneration** - Control generare persoane

### GeneratedVideo.swift
- Model pentru videoclipurile generate
- Include metadata, URL-uri, thumbnail-uri

### VideoCategory.swift, VideoStyle.swift, VideoPreset.swift
- Modele pentru categorizarea și stilizarea videoclipurilor

## Workflow de Generare Video

### 1. Inițiere Generare
```swift
let task = try await VideoGenerationService.shared.generateVideoFromText(
    prompt: "A beautiful sunset over mountains",
    provider: .sora2,
    aspectRatio: "16:9",
    duration: 8
)
```

### 2. Polling Status
```swift
let status = try await VideoGenerationService.shared.pollTaskUntilComplete(
    task: task,
    pollInterval: 3.0,
    timeout: 300.0
) { progress in
    print("Progress: \(progress ?? 0.0)")
}
```

### 3. Obținere Rezultat
```swift
if let videoURL = status.videoURL {
    // Video generat cu succes
    print("Video URL: \(videoURL)")
}
```

## Funcționalități Avansate

### Upload și Procesare Imagini
- **Sora2ApiService** și **Veo3FastAPIService** suportă upload de imagini
- Compresie automată și optimizare format
- Generare URL-uri temporare pentru backend

### Gestionare Erori
- Erori specifice pentru fiecare provider
- Retry logic implementat în servicii
- Timeout handling pentru polling

### Progress Tracking
- Progress callbacks pentru toate providerele
- Estimare timp rămas
- Status updates în timp real

## Integrare în Proiect

### Pași pentru Implementare:

1. **Configurare API Keys** în `APIKeys.swift`
2. **Adăugare dependințe** în Xcode project
3. **Import servicii** în view-urile relevante
4. **Implementare UI** pentru selecție provider și parametri

### Exemplu de Integrare UI:
```swift
class VideoGeneratorViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var progress: Double = 0.0
    @Published var generatedVideoURL: String?
    
    func generateVideo(prompt: String, provider: VideoProvider) async {
        isGenerating = true
        
        do {
            let task = try await VideoGenerationService.shared.generateVideoFromText(
                prompt: prompt,
                provider: provider,
                aspectRatio: "16:9",
                duration: 8
            )
            
            let status = try await VideoGenerationService.shared.pollTaskUntilComplete(
                task: task
            ) { [weak self] progress in
                DispatchQueue.main.async {
                    self?.progress = progress ?? 0.0
                }
            }
            
            DispatchQueue.main.async {
                self.generatedVideoURL = status.videoURL
                self.isGenerating = false
            }
            
        } catch {
            print("Error: \(error)")
            isGenerating = false
        }
    }
}
```

## Endpoint-uri Backend

### Base URLs:
- **Google Cloud/Veo:** Via backend centralizat
- **Runway:** `https://api.dev.runwayml.com`
- **Sora2/Veo3Fast:** `https://pollo.ai/api/platform`
- **Upload files:** `https://ai-assistant-backend-164860087792.europe-west1.run.app`

### Securitate:
- API keys stored în `APIKeys.swift`
- HTTPS pentru toate comunicările
- Authentication headers pentru fiecare provider

## Concluzie

Implementarea backend oferă:
- ✅ Suport pentru 6 providere AI diferiti
- ✅ Interface unificat prin `VideoGenerationService`
- ✅ Gestionare automată a polling-ului și progress-ului
- ✅ Error handling robust
- ✅ Support pentru text-to-video și image-to-video
- ✅ Multiple aspect ratios și durată configurabilă
- ✅ Upload și procesare imagini

Aceste componente oferă o bază solidă pentru dezvoltarea unei aplicații complete de generare video AI.