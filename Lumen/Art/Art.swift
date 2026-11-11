import SwiftUI
import UIKit

/// Every illustration slot in the app, by asset name.
/// Drop a final image with the same name into Assets.xcassets and it replaces
/// the painted placeholder automatically. See README for the full list.
enum Art {
    // Sky and light layers
    static let skyDay = "sky_day"
    static let skyDawn = "sky_dawn"
    static let skyGolden = "sky_golden"
    static let skyDusk = "sky_dusk"
    static let skyNight = "sky_night"
    static let cloudsSoft = "clouds_soft_01"
    static func lightBeam(_ level: Int) -> String { "light_beam_level_\(max(1, min(5, level)))" }
    static let seaMist = "sea_mist_01"
    static let paperGrain = "texture_paper_grain"

    // Scene grounds
    static func ground(_ terrain: Terrain, _ mood: SceneMood) -> String { "ground_\(terrain.rawValue)_\(mood.rawValue)" }
    static let hillsFar = "hills_far_01"
    static let wildflowers = "wildflowers_01"
    static let butterflies = "butterflies_01"

    // Milestone unlocks
    static let milestoneRainbow = "milestone_rainbow"
    static let milestoneFloweringTree = "milestone_flowering_tree"
    static let milestoneStillPond = "milestone_still_pond"
    static let milestoneGoldenEvening = "milestone_golden_evening"

    // Sheep items
    static let itemBell = "item_bell"
    static let itemDaisy = "item_daisy"
    static let itemScarf = "item_scarf"

    // Journey nodes
    static func journeyNode(_ journeyAsset: String, state: String) -> String { "\(journeyAsset)_node_\(state)" }
    static func journeyCover(_ journeyAsset: String) -> String { "\(journeyAsset)_cover" }

    static func exists(_ name: String) -> Bool { UIImage(named: name) != nil }
}

/// Shows the final asset when it exists, otherwise the painted placeholder.
struct ArtLayer<Placeholder: View>: View {
    let name: String
    var contentMode: ContentMode = .fill
    @ViewBuilder var placeholder: () -> Placeholder

    var body: some View {
        if Art.exists(name) {
            Image(name)
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .accessibilityHidden(true)
        } else {
            placeholder()
                .accessibilityHidden(true)
        }
    }
}

enum SceneMood: String, CaseIterable {
    case day, dawn, golden, dusk, night
}

enum Terrain: String, CaseIterable {
    case meadow, sea, hills, desert, valley
}

/// Describes one layered scene. Verse cards reference scenes by name
/// (scene_meadow_day_01, scene_sea_mist_01...) and this maps the name to layers.
struct SceneConfig: Equatable {
    var name: String = "scene_meadow_day_01"
    var mood: SceneMood = .day
    var terrain: Terrain = .meadow
    var lightLevel: Int = 2
    var bloom: Int = 6
    var milestones: Set<Milestone> = []

    static func named(_ name: String, lightLevel: Int = 2, bloom: Int = 6) -> SceneConfig {
        var config = SceneConfig(name: name, lightLevel: lightLevel, bloom: bloom)
        if name.contains("night") { config.mood = .night }
        else if name.contains("dusk") || name.contains("storm") { config.mood = .dusk }
        else if name.contains("golden") || name.contains("evening") { config.mood = .golden }
        else if name.contains("dawn") || name.contains("morning") { config.mood = .dawn }
        if name.contains("sea") || name.contains("water") { config.terrain = .sea }
        else if name.contains("hills") || name.contains("rock") || name.contains("city") { config.terrain = .hills }
        else if name.contains("valley") { config.terrain = .valley }
        else if name.contains("desert") { config.terrain = .desert }
        if config.mood == .night || config.mood == .dusk { config.lightLevel = min(config.lightLevel, 1) }
        return config
    }
}

/// Tiny deterministic generator so placeholder flowers stay put between renders.
struct SeededRandom {
    private var state: UInt64
    init(seed: Int) { state = UInt64(truncatingIfNeeded: seed &* 2654435761 &+ 12345) | 1 }
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double((state >> 33) % 10_000) / 10_000
    }
}
