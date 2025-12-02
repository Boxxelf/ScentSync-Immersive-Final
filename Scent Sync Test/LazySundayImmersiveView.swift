//
//  LazySundayImmersiveView.swift
//  Scent Sync Test
//
//  Created by iya student on 11/18/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct LazySundayImmersiveView: View {
    @Environment(AppModel.self) var appModel
    @State private var bgmPlayer = BGMAudioPlayer()
    
    // PortalTriangleScene 中的 Box（用于将来扩展 Lazy Sunday 专属交互）
    @State private var box = Entity()
    @State private var cube = Entity() // Cube for portal 1
    @State private var cube2 = Entity() // Cube2 for portal 2
    @State private var cube3 = Entity() // Cube3 for portal 3
    
    // Worlds for portals (Lazy Sunday skyboxes)
    @State private var world1 = Entity() // lazysunday_skybox1
    @State private var world2 = Entity() // lazysunday_skybox2
    @State private var world3 = Entity() // lazysunday_skybox3
    
    // MyosotisBloomingScene（勿忘我花开场景）
    @State private var myosotisScene: Entity?
    @State private var isMyosotisVisible = false
    @State private var myosotisEntities: [Entity] = []
    
    private enum SkyboxError: Error { case unableToLoadTexture }

    var body: some View {
        RealityView { content in
            // 使用与 Springtime 相同的 PortalTriangleScene 作为 Lazy Sunday 的沉浸环境
            do {
                let portalScene = try await Entity(named: "PortalTriangleScene", in: realityKitContentBundle)
                content.add(portalScene)
                
                guard let foundBox = portalScene.findEntity(named: "Box") else {
                    print("⚠️ LazySundayImmersiveView: Box not found in PortalTriangleScene")
                    return
                }
                
                box = foundBox
                box.position = [0, 0, 0]
                box.scale *= [0.5, 1, 0.5]
                
                // Find Cubes in Box for portals
                guard let foundCube = box.findEntity(named: "Cube") else {
                    print("⚠️ LazySundayImmersiveView: Cube not found in Box")
                    return
                }
                self.cube = foundCube
                
                guard let foundCube2 = box.findEntity(named: "Cube2") else {
                    print("⚠️ LazySundayImmersiveView: Cube2 not found in Box")
                    return
                }
                self.cube2 = foundCube2
                
                guard let foundCube3 = box.findEntity(named: "Cube3") else {
                    print("⚠️ LazySundayImmersiveView: Cube3 not found in Box")
                    return
                }
                self.cube3 = foundCube3
                
                // Create worlds with Lazy Sunday skyboxes
                let worlds = await createWorldsForLazySunday()
                content.add(worlds)
                
                // Create portals on Cubes
                createPortals()
                
                // Setup Box interaction
                setupBoxInteraction()
                
                // Apply textures to textboxes
                await applyTextboxTextures(to: portalScene)
                
            } catch {
                print("❌ LazySundayImmersiveView: Failed to load PortalTriangleScene - \(error.localizedDescription)")
            }
            
            // 预先加载 MyosotisBloomingScene，默认隐藏，点击 Box 时显示/隐藏
            if myosotisScene == nil {
                if let scene = try? await Entity(named: "MyosotisBloomingScene", in: realityKitContentBundle) {
                    scene.isEnabled = false
                    content.add(scene)
                    myosotisScene = scene
                    isMyosotisVisible = false
                    
                    // 设置每一株勿忘我可点击并具备碰撞体
                    setupMyosotisEntities(in: scene)
                    print("🌸 LazySundayImmersiveView: Loaded MyosotisBloomingScene (initially hidden)")
                } else {
                    print("⚠️ LazySundayImmersiveView: Failed to load MyosotisBloomingScene")
                }
            }
        }
        // 点击 Box 时显示 / 隐藏 MyosotisBloomingScene
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    let entity = value.entity
                    if entity == box || isDescendantOf(entity: entity, ancestor: box) {
                        print("📦 LazySundayImmersiveView: Box tapped")
                        if let scene = myosotisScene {
                            isMyosotisVisible.toggle()
                            scene.isEnabled = isMyosotisVisible
                            print("🌸 LazySundayImmersiveView: MyosotisBloomingScene isEnabled = \(scene.isEnabled)")
                        } else {
                            print("⚠️ LazySundayImmersiveView: MyosotisBloomingScene not available")
                        }
                        return
                    }
                    
                    // 若点击到任意一株勿忘我，播放它的开花动画
                    if let target = myosotisEntities.first(where: { entity == $0 || isDescendantOf(entity: entity, ancestor: $0) }) {
                        playBloomAnimation(for: target)
                    }
                }
        )
        .onAppear {
            // Start playing BGM when immersive space appears
            bgmPlayer.playBGM(fileName: "lazysunday_bgm", fileExtension: "mp3", volume: 0.4)
        }
        .onDisappear {
            // Stop BGM when immersive space disappears
            bgmPlayer.stop()
        }
    }
    
    /// 为 MyosotisBloomingScene 中的每一株勿忘我添加可点击 & 碰撞，并缓存下来
    private func setupMyosotisEntities(in scene: Entity) {
        myosotisEntities.removeAll()
        
        for index in 1...7 {
            let name = "myosotis_\(index)"
            if let plant = scene.findEntity(named: name) {
                // InputTarget
                if plant.components[InputTargetComponent.self] == nil {
                    plant.components.set(InputTargetComponent())
                }
                
                // Collision（根据可视范围生成 Box 碰撞体）
                if plant.components[CollisionComponent.self] == nil {
                    let bounds = plant.visualBounds(relativeTo: plant)
                    let extent = bounds.extents
                    if extent.x > 0 && extent.y > 0 && extent.z > 0 {
                        let shape = ShapeResource.generateBox(size: extent)
                        let collider = CollisionComponent(shapes: [shape])
                        plant.components.set(collider)
                    }
                }
                
                myosotisEntities.append(plant)
                print("🌱 LazySundayImmersiveView: setup myosotis entity '\(name)'")
            } else {
                print("⚠️ LazySundayImmersiveView: myosotis entity '\(name)' not found in scene")
            }
        }
    }
    
    /// 为 Box 添加点击所需的组件（输入 & 碰撞）
    private func setupBoxInteraction() {
        // 统一 Box 的位置和缩放（与 Springtime / Bubble Bath 一致）
        box.position = [0, 0, 0] // meters
        box.scale *= [0.5, 1, 0.5]
        
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
    
    /// 判断某个实体是否是指定 ancestor 的子孙节点
    private func isDescendantOf(entity: Entity, ancestor: Entity) -> Bool {
        var current: Entity? = entity.parent
        while let parent = current {
            if parent == ancestor {
                return true
            }
            current = parent.parent
        }
        return false
    }
    
    /// 播放指定勿忘我的 Bloom 动画（从 AnimationLibrary 中寻找合适动画）
    private func playBloomAnimation(for plant: Entity) {
        print("Attempting to play Bloom animation for \(plant.name)...")
        
        if let animationLibrary = plant.components[AnimationLibraryComponent.self] {
            // 优先找名称包含 Bloom 的动画
            for (name, resource) in animationLibrary.animations {
                if name.lowercased().contains("bloom") {
                    print("Playing bloom animation: \(name)")
                    plant.playAnimation(resource, transitionDuration: 0.25, startsPaused: false)
                    return
                }
            }
            
            // 找不到就播放第一个动画
            if let (firstName, firstResource) = animationLibrary.animations.first {
                print("Playing first available animation: \(firstName)")
                plant.playAnimation(firstResource, transitionDuration: 0.25, startsPaused: false)
            } else {
                print("No animations found in AnimationLibrary for \(plant.name)")
            }
        } else {
            print("AnimationLibrary component not found on plant \(plant.name)")
        }
    }
    
    /// 创建 Lazy Sunday 的 3 个 skybox worlds
    private func createWorldsForLazySunday() async -> Entity {
        let worlds = Entity()
        
        // World 1: lazysunday_skybox1
        let newWorld1 = Entity()
        newWorld1.components.set(WorldComponent())
        do {
            let skybox1 = try await createSkyboxEntity(texture: "lazysunday_skybox1")
            skybox1.position = [0, 0, 0]
            newWorld1.addChild(skybox1)
        } catch {
            print("⚠️ LazySundayImmersiveView: Failed to create lazysunday_skybox1 - \(error)")
        }
        worlds.addChild(newWorld1)
        self.world1 = newWorld1
        
        // World 2: lazysunday_skybox2
        let newWorld2 = Entity()
        newWorld2.components.set(WorldComponent())
        do {
            let skybox2 = try await createSkyboxEntity(texture: "lazysunday_skybox2")
            skybox2.position = [0, 0, 0]
            newWorld2.addChild(skybox2)
        } catch {
            print("⚠️ LazySundayImmersiveView: Failed to create lazysunday_skybox2 - \(error)")
        }
        worlds.addChild(newWorld2)
        self.world2 = newWorld2
        
        // World 3: lazysunday_skybox3
        let newWorld3 = Entity()
        newWorld3.components.set(WorldComponent())
        do {
            let skybox3 = try await createSkyboxEntity(texture: "lazysunday_skybox3")
            skybox3.position = [0, 0, 0]
            newWorld3.addChild(skybox3)
        } catch {
            print("⚠️ LazySundayImmersiveView: Failed to create lazysunday_skybox3 - \(error)")
        }
        worlds.addChild(newWorld3)
        self.world3 = newWorld3
        
        return worlds
    }
    
    /// 创建 skybox 实体（球体材质）
    private func createSkyboxEntity(texture: String) async throws -> Entity {
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
    
    /// 在 Cubes 上创建 portals，连接到对应的 worlds
    private func createPortals() {
        // Portal for world1 (lazysunday_skybox1) on Cube
        createPortalForCube(cube: cube, targetWorld: world1, isFlipped: false)
        
        // Portal for world2 (lazysunday_skybox2) on Cube2
        createPortalForCube(cube: cube2, targetWorld: world2, isFlipped: true)
        
        // Portal for world3 (lazysunday_skybox3) on Cube3
        createPortalForCube(cube: cube3, targetWorld: world3, isFlipped: false)
    }
    
    /// 在指定的 Cube 上创建一个 portal，连接到 targetWorld
    private func createPortalForCube(cube: Entity, targetWorld: Entity, isFlipped: Bool) {
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
            portal.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
        } else {
            // For Cube and Cube3, place portal on the negative Z side (front face)
            portal.position = [0, 0, -cubeDepth / 2 - 0.001]
            // Rotate 180 degrees around Y axis so it faces the correct direction
            portal.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])
        }
    }
    
    /// 应用文字纹理到 PortalTriangleScene 中的 textbox 实体（Lazy Sunday 主题）
    private func applyTextboxTextures(to sceneEntity: Entity) async {
        // Map of textbox names to texture file names (Lazy Sunday)
        let textboxTextureMap: [String: String] = [
            "Springtime_textbox": "lazysunday_text",
            "Springtime_textbox2": "lazysunday_text2",
            "Springtime_textbox3": "lazysunday_text3"
        ]
        
        for (textboxName, textureName) in textboxTextureMap {
            guard let textbox = sceneEntity.findEntity(named: textboxName) else {
                print("⚠️ LazySundayImmersiveView: Textbox '\(textboxName)' not found")
                continue
            }
            
            // Try to load texture from bundle
            var textureResource: TextureResource?
            
            // First try RealityKitContent bundle
            if let resource = try? await TextureResource(named: textureName, in: realityKitContentBundle) {
                textureResource = resource
                print("✅ LazySundayImmersiveView: Loaded texture '\(textureName)' from RealityKitContent bundle")
            }
            // If not found, try main bundle
            else if let url = Bundle.main.url(forResource: textureName, withExtension: "png"),
                    let resource = try? await TextureResource.load(contentsOf: url) {
                textureResource = resource
                print("✅ LazySundayImmersiveView: Loaded texture '\(textureName)' from main bundle")
            } else {
                print("⚠️ LazySundayImmersiveView: Texture '\(textureName).png' not found in any bundle")
                continue
            }
            
            guard let texture = textureResource else {
                continue
            }
            
            // Use SimpleMaterial for better visibility and control
            var material = SimpleMaterial()
            material.color = .init(texture: .init(texture))
            material.metallic = 0.0
            material.roughness = 0.0 // Very low roughness for maximum visibility
            
            // Apply material to the textbox and all its children
            var applied = false
            
            // Try to apply to the textbox itself
            if var modelComponent = textbox.components[ModelComponent.self] {
                modelComponent.materials = [material]
                textbox.components.set(modelComponent)
                print("✅ LazySundayImmersiveView: Applied texture '\(textureName)' to '\(textboxName)' directly")
                applied = true
            }
            
            // Also apply to all children to ensure visibility
            for child in textbox.children {
                if var childModelComponent = child.components[ModelComponent.self] {
                    childModelComponent.materials = [material]
                    child.components.set(childModelComponent)
                    print("✅ LazySundayImmersiveView: Applied texture '\(textureName)' to child '\(child.name)' of '\(textboxName)'")
                    applied = true
                }
            }
            
            if !applied {
                print("⚠️ LazySundayImmersiveView: Could not find ModelComponent on '\(textboxName)' or its children")
            }
        }
    }
}

#Preview(immersionStyle: .full) {
    LazySundayImmersiveView()
        .environment(AppModel())
}

