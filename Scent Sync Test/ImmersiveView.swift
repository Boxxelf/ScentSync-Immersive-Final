//
//  ImmersiveView.swift
//  Scent Sync Test
//
//  Created by Tina Jiang on 11/17/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

@MainActor
struct ImmersiveView: View {
    @State private var box = Entity() //  to store box
    @State private var world1 = Entity() //  to store world1
    @State private var world2 = Entity() //  to store world2
    @State private var world3 = Entity() //  to store world3
    @State private var cube = Entity() //  to store cube
    @State private var cube2 = Entity() //  to store cube2
    @State private var cube3 = Entity() //  to store cube3
    @State private var lilyEntity: Entity? = nil //  to store animated_blooming_lily
    @State private var lilyEntity1: Entity? = nil //  to store animated_blooming_lily_1
    @State private var lilyEntity2: Entity? = nil //  to store animated_blooming_lily_2
    @State private var flowerSceneEntity: Entity? = nil //  to store FlowerBloomingScene root
    @State private var isFlowerSceneVisible = false //  to control FlowerBloomingScene visibility
    @State private var bgmPlayer = BGMAudioPlayer() //  to play BGM
    
    private enum SkyboxError: Error { case unableToLoadTexture }
    
    // Helper function to add fallback content when loading fails
    func addFallbackContent(to content: RealityViewContent) {
        print("⚠️ Adding fallback content")
        let fallbackEntity = Entity()
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let mesh = MeshResource.generateSphere(radius: 0.5)
        fallbackEntity.components.set(ModelComponent(mesh: mesh, materials: [material]))
        fallbackEntity.position = [0, 0, -2]
        content.add(fallbackEntity)
        print("✅ Added fallback white sphere at [0, 0, -2]")
    }
    
    var body: some View {
        RealityView { content in
            print("🎬 ImmersiveView RealityView content closure started")
            
            // Add the initial RealityKit content
            do {
                let immersiveContentEntity = try await Entity(named: "PortalTriangleScene", in: realityKitContentBundle)
                print("✅ Successfully loaded PortalTriangleScene")
                content.add(immersiveContentEntity)
                
                guard let box = immersiveContentEntity.findEntity(named: "Box") else {
                    print("❌ ERROR: Cannot find Box in PortalTriangleScene")
                    // Add fallback content
                    addFallbackContent(to: content)
                    return
                }
                
                print("✅ Found Box entity")
                
                // change the position and scale of the box
                self.box = box
                box.position = [0, 0, 0] // meters
                box.scale *= [0.5,1,0.5]
                
                // Find Cubes in Box
                guard let foundCube = box.findEntity(named: "Cube") else {
                    print("❌ ERROR: Cannot find Cube in Box")
                    addFallbackContent(to: content)
                    return
                }
                self.cube = foundCube
                print("✅ Found Cube")
                
                // Try to find Cube2 and Cube3
                guard let foundCube2 = box.findEntity(named: "Cube2") else {
                    print("❌ ERROR: Cannot find Cube2 in Box")
                    addFallbackContent(to: content)
                    return
                }
                self.cube2 = foundCube2
                print("✅ Found Cube2")
                
                guard let foundCube3 = box.findEntity(named: "Cube3") else {
                    print("❌ ERROR: Cannot find Cube3 in Box")
                    addFallbackContent(to: content)
                    return
                }
                self.cube3 = foundCube3
                print("✅ Found Cube3")
                
                print("🌍 Creating worlds...")
                let worlds = await createWorlds()
                content.add(worlds)
                print("✅ Worlds created and added")
                
                print("🚪 Creating portals...")
                createPortals()
                print("✅ Portals created")
                
                // Load FlowerBloomingScene (initially hidden)
                print("🌸 Loading flower scene...")
                await loadFlowerScene(content: content)
                print("✅ Flower scene loaded")
                
                // Setup Box for tap interaction
                setupBoxInteraction()
                
                // Apply textures to textboxes
                await applyTextboxTextures(to: immersiveContentEntity)
                
            } catch {
                print("❌ ERROR loading PortalTriangleScene: \(error)")
                print("Error details: \(error.localizedDescription)")
                // Add fallback content so we can see something
                addFallbackContent(to: content)
            }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    // Check if Box or its children were tapped
                    if value.entity == box || isDescendantOf(entity: value.entity, ancestor: box) {
                        // Toggle FlowerBloomingScene visibility
                        toggleFlowerScene()
                        return
                    }
                    
                    // Check if the tapped entity is any of the lilies or their descendants
                    if let lily = lilyEntity {
                        if value.entity == lily || isDescendantOf(entity: value.entity, ancestor: lily) {
                            playBloomAnimation(for: lily)
                            return
                        }
                    }
                    if let lily1 = lilyEntity1 {
                        if value.entity == lily1 || isDescendantOf(entity: value.entity, ancestor: lily1) {
                            playBloomAnimation(for: lily1)
                            return
                        }
                    }
                    if let lily2 = lilyEntity2 {
                        if value.entity == lily2 || isDescendantOf(entity: value.entity, ancestor: lily2) {
                            playBloomAnimation(for: lily2)
                            return
                        }
                    }
                }
        )
        .onAppear {
            // Start playing BGM when immersive space appears
            bgmPlayer.playBGM(fileName: "springtime_bgm", fileExtension: "mp3", volume: 0.4)
        }
        .onDisappear {
            // Stop BGM when immersive space disappears
            bgmPlayer.stop()
        }
    }

    func createWorlds() async -> Entity {
        let worlds = Entity()
        
        //Make world 1
        let newWorld1 = Entity()
        newWorld1.components.set(WorldComponent())
        do {
            let skybox1 = try await createSkyboxEntity(texture: "skybox1")
            skybox1.position = [0, 0, 0]
            newWorld1.addChild(skybox1)
        } catch {
            print("Failed to create skybox1: \(error)")
        }
        worlds.addChild(newWorld1)
        self.world1 = newWorld1
        
        //Make world 2
        let newWorld2 = Entity()
        newWorld2.components.set(WorldComponent())
        do {
            let skybox4 = try await createSkyboxEntity(texture: "skybox4")
            skybox4.position = [0, 0, 0]
            newWorld2.addChild(skybox4)
        } catch {
            print("Failed to create skybox4: \(error)")
        }
        worlds.addChild(newWorld2)
        self.world2 = newWorld2
        
        //Make world 3
        let newWorld3 = Entity()
        newWorld3.components.set(WorldComponent())
        do {
            let skybox3 = try await createSkyboxEntity(texture: "skybox3")
            skybox3.position = [0, 0, 0]
            newWorld3.addChild(skybox3)
        } catch {
            print("Failed to create skybox3: \(error)")
        }
        worlds.addChild(newWorld3)
        self.world3 = newWorld3
    
        return worlds
    }
    
    func createSkyboxEntity(texture: String) async throws -> Entity {
        guard let resource = try? await TextureResource(named: texture) else {
            throw SkyboxError.unableToLoadTexture
        }

        var material = UnlitMaterial()
        material.color = .init(texture: .init(resource))

        let entity = Entity()
        entity.components.set(ModelComponent(mesh: .generateSphere(radius: 1000), materials: [material]))
        // Flip X axis so texture is visible from inside the sphere
        entity.scale *= .init(x: -1, y: 1, z: 1)
        return entity
    }

    func createPortals() {
        // Create portal for world1 on Cube
        createPortalForCube(cube: cube, targetWorld: world1, isFlipped: false)
        
        // Create portal for world2 on Cube2 - try flipped position
        createPortalForCube(cube: cube2, targetWorld: world2, isFlipped: true)
        
        // Create portal for world3 on Cube3
        createPortalForCube(cube: cube3, targetWorld: world3, isFlipped: false)
    }
    
    func createPortalForCube(cube: Entity, targetWorld: Entity, isFlipped: Bool) {
        // Get Cube's visual bounds to determine its size
        let cubeBounds = cube.visualBounds(relativeTo: cube)
        let cubeWidth = cubeBounds.max.x - cubeBounds.min.x
        let cubeHeight = cubeBounds.max.y - cubeBounds.min.y
        
        // Create portal with size matching Cube's dimensions
        let portalMesh = MeshResource.generatePlane(width: cubeWidth, height: cubeHeight)
        let portal = ModelEntity(mesh: portalMesh, materials: [PortalMaterial()])
        portal.components.set(PortalComponent(target: targetWorld))
        
        // Attach portal directly to Cube
        cube.addChild(portal)
        
        // Position portal at the front face of Cube (facing outward)
        let cubeDepth = cubeBounds.max.z - cubeBounds.min.z
        
        if isFlipped {
            // For Cube2, place portal on the positive Z side (opposite side)
            portal.position = [0, 0, cubeDepth / 2 + 0.001]
            // No rotation needed for this side
            portal.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
        } else {
            // For Cube and Cube3, place portal on the negative Z side (front face)
            portal.position = [0, 0, -cubeDepth / 2 - 0.001]
            // Rotate 180 degrees around Y axis so it faces the correct direction
            portal.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])
        }
    }
    
    func loadFlowerScene(content: RealityViewContent) async {
        do {
            // Load FlowerBloomingScene
            if let flowerScene = try? await Entity(named: "FlowerBloomingScene", in: realityKitContentBundle) {
                content.add(flowerScene)
                self.flowerSceneEntity = flowerScene
                
                // Initially hide the flower scene
                flowerScene.isEnabled = false
                isFlowerSceneVisible = false
                
                // Setup all lily entities
                setupLilyEntity(flowerScene: flowerScene, name: "animated_blooming_lily", entity: &lilyEntity)
                setupLilyEntity(flowerScene: flowerScene, name: "animated_blooming_lily_1", entity: &lilyEntity1)
                setupLilyEntity(flowerScene: flowerScene, name: "animated_blooming_lily_2", entity: &lilyEntity2)
            } else {
                print("Warning: Failed to load FlowerBloomingScene")
            }
        } catch {
            print("Failed to load FlowerBloomingScene: \(error)")
        }
    }
    
    func setupBoxInteraction() {
        // Ensure Box has InputTarget and Collision components for tap detection
        if box.components[InputTargetComponent.self] == nil {
            box.components.set(InputTargetComponent())
        }
        
        if box.components[CollisionComponent.self] == nil {
            let bounds = box.visualBounds(relativeTo: box)
            let extent = bounds.extents
            if extent.x > 0 && extent.y > 0 && extent.z > 0 {
                let shape = ShapeResource.generateBox(size: extent)
                let collider = CollisionComponent(shapes: [shape])
                box.components.set(collider)
            }
        }
    }
    
    func toggleFlowerScene() {
        guard let flowerScene = flowerSceneEntity else {
            print("⚠️ FlowerBloomingScene entity not available")
            return
        }
        
        isFlowerSceneVisible.toggle()
        flowerScene.isEnabled = isFlowerSceneVisible
        
        if isFlowerSceneVisible {
            print("🌸 FlowerBloomingScene is now visible")
        } else {
            print("🌸 FlowerBloomingScene is now hidden")
        }
    }
    
    func applyTextboxTextures(to sceneEntity: Entity) async {
        // Map of textbox names to texture file names
        let textboxTextureMap: [String: String] = [
            "Springtime_textbox": "Springtime_text",
            "Springtime_textbox2": "Springtime_text2",
            "Springtime_textbox3": "Springtime_text3"
        ]
        
        for (textboxName, textureName) in textboxTextureMap {
            guard let textbox = sceneEntity.findEntity(named: textboxName) else {
                print("⚠️ Textbox '\(textboxName)' not found")
                continue
            }
            
            print("🔍 Found textbox '\(textboxName)' at position: \(textbox.position), scale: \(textbox.scale), rotation: \(textbox.orientation)")
            
            // Try to load texture from bundle - try both main bundle and RealityKitContent bundle
            var textureResource: TextureResource?
            
            // First try RealityKitContent bundle
            if let resource = try? await TextureResource(named: textureName, in: realityKitContentBundle) {
                textureResource = resource
                print("✅ Loaded texture '\(textureName)' from RealityKitContent bundle")
            }
            // If not found, try main bundle
            else if let url = Bundle.main.url(forResource: textureName, withExtension: "png"),
                    let resource = try? await TextureResource.load(contentsOf: url) {
                textureResource = resource
                print("✅ Loaded texture '\(textureName)' from main bundle")
            } else {
                print("⚠️ Texture '\(textureName).png' not found in any bundle")
                continue
            }
            
            guard let texture = textureResource else {
                continue
            }
            
            // Use SimpleMaterial for better visibility and control
            var material = SimpleMaterial()
            // Use texture with full brightness
            material.color = .init(texture: .init(texture))
            material.metallic = 0.0
            material.roughness = 0.0 // Very low roughness for maximum visibility
            
            // Apply material to the textbox and all its children
            var applied = false
            
            // Try to apply to the textbox itself
            if var modelComponent = textbox.components[ModelComponent.self] {
                modelComponent.materials = [material]
                textbox.components.set(modelComponent)
                print("✅ Applied texture '\(textureName)' to '\(textboxName)' directly")
                applied = true
            }
            
            // Also apply to all children to ensure visibility
            for child in textbox.children {
                if var childModelComponent = child.components[ModelComponent.self] {
                    childModelComponent.materials = [material]
                    child.components.set(childModelComponent)
                    print("✅ Applied texture '\(textureName)' to child '\(child.name)' of '\(textboxName)'")
                    applied = true
                }
            }
            
            if !applied {
                print("⚠️ Could not find ModelComponent on '\(textboxName)' or its children")
            }
        }
    }
    
    // Helper function to setup a lily entity with collision and input components
    func setupLilyEntity(flowerScene: Entity, name: String, entity: inout Entity?) {
        if let lily = flowerScene.findEntity(named: name) {
            entity = lily
            
            // Ensure the entity has InputTarget component for tap detection
            if lily.components[InputTargetComponent.self] == nil {
                lily.components.set(InputTargetComponent())
            }
            
            // Ensure the entity has Collision component for interaction
            if lily.components[CollisionComponent.self] == nil {
                // Get visual bounds to create a collider
                let bounds = lily.visualBounds(relativeTo: lily)
                let extent = bounds.extents
                // Use a sphere collider if extent is too small, otherwise use box
                if extent.x > 0 && extent.y > 0 && extent.z > 0 {
                    let shape = ShapeResource.generateBox(size: extent)
                    let collider = CollisionComponent(shapes: [shape])
                    lily.components.set(collider)
                } else {
                    // Fallback to sphere collider
                    let maxExtent = Swift.max(extent.x, Swift.max(extent.y, extent.z))
                    let radius = maxExtent / 2
                    let shape = ShapeResource.generateSphere(radius: Swift.max(radius, 0.1))
                    let collider = CollisionComponent(shapes: [shape])
                    lily.components.set(collider)
                }
            }
            
            // Also add colliders to child entities that might be tappable
            for child in lily.children {
                if child.components[CollisionComponent.self] == nil && child.components[ModelComponent.self] != nil {
                    let bounds = child.visualBounds(relativeTo: child)
                    let extent = bounds.extents
                    if extent.x > 0 && extent.y > 0 && extent.z > 0 {
                        let shape = ShapeResource.generateBox(size: extent)
                        let collider = CollisionComponent(shapes: [shape])
                        child.components.set(collider)
                    }
                }
            }
        } else {
            print("Warning: \(name) entity not found in FlowerBloomingScene")
        }
    }
    
    // Helper function to check if an entity is a descendant of another entity
    func isDescendantOf(entity: Entity, ancestor: Entity) -> Bool {
        var current: Entity? = entity.parent
        while let parent = current {
            if parent == ancestor {
                return true
            }
            current = parent.parent
        }
        return false
    }
    
    func playBloomAnimation(for lily: Entity) {
        print("Attempting to play Bloom animation for \(lily.name)...")
        
        // First, try to access the animation from the AnimationLibrary component
        if let animationLibrary = lily.components[AnimationLibraryComponent.self] {
            print("Found AnimationLibrary with \(animationLibrary.animations.count) animation(s)")
            
            // Look for the "default subtree animation" which is referenced by the Bloom timeline
            // Note: animations is a dictionary-like collection: (key: String, value: AnimationResource)
            // Note: The name in the file is "default_subtree_animation" (with underscore)
            // but it might be loaded as "default subtree animation" (with space)
            for (animationName, animationResource) in animationLibrary.animations {
                print("Found animation: '\(animationName)'")
                if animationName == "default subtree animation" || 
                   animationName == "default_subtree_animation" ||
                   animationName.contains("subtree") {
                    print("Playing animation: \(animationName)")
                    lily.playAnimation(animationResource, transitionDuration: 0.25, startsPaused: false)
                    return
                }
            }
            
            // Fallback: play the first available animation
            if let (firstAnimationName, firstAnimation) = animationLibrary.animations.first {
                print("Playing first available animation: \(firstAnimationName)")
                lily.playAnimation(firstAnimation, transitionDuration: 0.25, startsPaused: false)
            } else {
                print("No animations found in AnimationLibrary")
            }
        } else {
            print("AnimationLibrary component not found on lily entity: \(lily.name)")
            
            // Try to find animation in child entities
            for child in lily.children {
                if let animationLibrary = child.components[AnimationLibraryComponent.self] {
                    print("Found AnimationLibrary in child entity: \(child.name)")
                    for (animationName, animationResource) in animationLibrary.animations {
                        print("Found animation in child: '\(animationName)'")
                        if animationName.contains("subtree") || animationName.contains("bloom") {
                            print("Playing animation from child entity: \(animationName)")
                            lily.playAnimation(animationResource, transitionDuration: 0.25, startsPaused: false)
                            return
                        }
                    }
                    // Fallback: play first animation from child
                    if let (firstAnimationName, firstAnimation) = animationLibrary.animations.first {
                        print("Playing first animation from child entity: \(firstAnimationName)")
                        lily.playAnimation(firstAnimation, transitionDuration: 0.25, startsPaused: false)
                        return
                    }
                }
            }
            
            print("Could not find any animations to play for \(lily.name)")
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
