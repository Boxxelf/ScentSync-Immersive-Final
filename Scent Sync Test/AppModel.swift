//
//  AppModel.swift
//  Scent Sync Test
//
//  Created by Tina Jiang on 11/17/25.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    // Immersive Space IDs for different scents
    static let springtimeImmersiveSpaceID = "SpringtimeImmersiveSpace"
    static let lazySundayImmersiveSpaceID = "LazySundayImmersiveSpace"
    
    // Legacy immersive space ID (kept for backward compatibility)
    let immersiveSpaceID = "ImmersiveSpace"
    
    // Current selected scent for immersive experience
    var currentScentImmersiveSpaceID: String? = nil
    
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    // Get immersive space ID for a specific scent
    func immersiveSpaceID(for scentTitle: String) -> String {
        switch scentTitle {
        case "Springtime In A Park":
            return AppModel.springtimeImmersiveSpaceID
        case "Lazy Sunday Morning":
            return AppModel.lazySundayImmersiveSpaceID
        default:
            return AppModel.springtimeImmersiveSpaceID // Default fallback
        }
    }
}
