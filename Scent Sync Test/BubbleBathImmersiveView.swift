//
//  BubbleBathImmersiveView.swift
//  Scent Sync Test
//
//  Created by Tina Jiang on 11/21/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct BubbleBathImmersiveView: View {
    @Environment(AppModel.self) var appModel
    @State private var bgmPlayer = BGMAudioPlayer()
    
    // PortalTriangleScene 中的 Box（作为"入口"）
    @State private var box = Entity()
    @State private var cube = Entity() // Cube for portal 1
    @State private var cube2 = Entity() // Cube2 for portal 2
    @State private var cube3 = Entity() // Cube3 for portal 3
    
    // Worlds for portals (Bubble Bath skyboxes)
    @State private var world1 = Entity() // bubble_skybox1
    @State private var world2 = Entity() // bubble_skybox2
    @State private var world3 = Entity() // bubble_skybox3
    
    // 存放所有克隆出来的泡泡的根节点，方便统一显示 / 隐藏
    @State private var bubblesRoot: Entity?
    
    // Query: 所有带 ModelComponent 的实体（在气泡场景中只有气泡有 ModelComponent）
    @State private var predicate = QueryPredicate<Entity>.has(ModelComponent.self)
    @State private var timer: Timer?
    @State private var bubble = Entity()
    let bubbleCount = 50
    
    private enum SkyboxError: Error { case unableToLoadTexture }

    var body: some View {
        RealityView { content in
            // 1. 加载 PortalTriangleScene，找到 Box 和 Cubes
            do {
                let portalScene = try await Entity(named: "PortalTriangleScene", in: realityKitContentBundle)
                content.add(portalScene)
                
                guard let foundBox = portalScene.findEntity(named: "Box") else {
                    print("⚠️ BubbleBathImmersiveView: Box not found in PortalTriangleScene")
                    return
                }
                
                box = foundBox
                box.position = [0, 0, 0]
                box.scale *= [0.5, 1, 0.5]
                
                // Find Cubes in Box for portals
                guard let foundCube = box.findEntity(named: "Cube") else {
                    print("⚠️ BubbleBathImmersiveView: Cube not found in Box")
                    return
                }
                self.cube = foundCube
                
                guard let foundCube2 = box.findEntity(named: "Cube2") else {
                    print("⚠️ BubbleBathImmersiveView: Cube2 not found in Box")
                    return
                }
                self.cube2 = foundCube2
                
                guard let foundCube3 = box.findEntity(named: "Cube3") else {
                    print("⚠️ BubbleBathImmersiveView: Cube3 not found in Box")
                    return
                }
                self.cube3 = foundCube3
                
                // Create worlds with Bubble Bath skyboxes
                let worlds = await createWorldsForBubble()
                content.add(worlds)
                
                // Create portals on Cubes
                createPortals()
                
                // Setup Box interaction
                setupBoxInteraction()
                
                // Apply textures to textboxes
                await applyTextboxTextures(to: portalScene)
                
            } catch {
                print("❌ BubbleBathImmersiveView: Failed to load PortalTriangleScene - \(error.localizedDescription)")
            }
            
            // 2. 预先创建 BubbleScene 的泡泡，但默认隐藏，等点击 Box 再显示
            if bubblesRoot == nil,
               let bubbleScene = try? await Entity(named: "BubbleScene", in: realityKitContentBundle),
               let baseBubble = bubbleScene.findEntity(named: "Bubble") {
                
                bubble = baseBubble
                
                let root = Entity()
                
                for _ in 1...bubbleCount {
                    let bubbleClone = bubble.clone(recursive: true)
                    
                    let x = Float.random(in: -1.5...1.5)
                    let y = Float.random(in: 1.0...1.5)
                    let z = Float.random(in: -1.5...1.5)
                    bubbleClone.position = [x, y, z]
                    
                    // 轻微随机运动的物理效果（无重力）
                    var pb = PhysicsBodyComponent()
                    pb.isAffectedByGravity = false
                    pb.linearDamping = 0
                    
                    let linearVelX = Float.random(in: -0.05...0.05)
                    let linearVelY = Float.random(in: -0.05...0.05)
                    let linearVelZ = Float.random(in: -0.05...0.05)
                    
                    let pm = PhysicsMotionComponent(linearVelocity: [linearVelX, linearVelY, linearVelZ])
                    
                    bubbleClone.components[PhysicsBodyComponent.self] = pb
                    bubbleClone.components[PhysicsMotionComponent.self] = pm
                    
                    root.addChild(bubbleClone)
                }
                
                // 初始隐藏，点击 Box 后再显示
                root.isEnabled = false
                content.add(root)
                bubblesRoot = root
            }
        }
        // 点击交互：
        // 1）若点到 Box（或其子节点）→ 显示 / 隐藏泡泡世界
        // 2）若点到泡泡实体 → 播放破裂动画并移除
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    let entity = value.entity
                    
                    // 优先处理 Box：点击 Box 时切换泡泡世界显隐
                    if entity == box || isDescendantOf(entity: entity, ancestor: box) {
                        if let root = bubblesRoot {
                            root.isEnabled.toggle()
                            print("🫧 BubbleBathImmersiveView: bubblesRoot.isEnabled = \(root.isEnabled)")
                        }
                        return
                    }
                    
                    // 不是 Box，则尝试当作泡泡处理
                    guard var model = entity.components[ModelComponent.self],
                          var mat = model.materials.first as? ShaderGraphMaterial,
                          entity.name.contains("Bubble") else {
                        return
                    }
                    
                    let frameRate: TimeInterval = 1.0 / 60.0   // 60 FPS
                    let duration: TimeInterval = 0.25
                    let targetValue: Float = 1
                    let totalFrames = Int(duration / frameRate)
                    var currentFrame = 0
                    var popValue: Float = 0
                    
                    timer?.invalidate()
                    
                    timer = Timer.scheduledTimer(withTimeInterval: frameRate, repeats: true) { timer in
                        currentFrame += 1
                        let progress = Float(currentFrame) / Float(totalFrames)
                        
                        popValue = progress * targetValue
                        
                        do {
                            try mat.setParameter(name: "Pop", value: .float(popValue))
                            model.materials = [mat]
                            entity.components[ModelComponent.self] = model
                        } catch {
                            print("Failed to set Pop parameter on bubble: \(error.localizedDescription)")
                        }
                        
                        if currentFrame >= totalFrames {
                            timer.invalidate()
                            entity.removeFromParent()
                        }
                    }
                }
        )
        .onAppear {
            // 打开 Bubble Bath 沉浸空间时播放 BGM
            bgmPlayer.playBGM(fileName: "bubblebath_bgm", fileExtension: "mp3", volume: 0.4)
        }
        .onDisappear {
            // 退出沉浸空间时停止 BGM
            bgmPlayer.stop()
        }
    }
    
    /// 为 Box 添加点击所需的组件（输入 & 碰撞），复用 Springtime 中的逻辑
    private func setupBoxInteraction() {
        // 统一 Box 的位置和缩放
        box.position = [0, 0, 0] // meters
        box.scale *= [0.5, 1, 0.5]
        
        // InputTarget
        if box.components[InputTargetComponent.self] == nil {
            box.components.set(InputTargetComponent())
        }
        
        // Collision
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
    
    /// 创建 Bubble Bath 的 3 个 skybox worlds
    private func createWorldsForBubble() async -> Entity {
        let worlds = Entity()
        
        // World 1: bubble_skybox1
        let newWorld1 = Entity()
        newWorld1.components.set(WorldComponent())
        do {
            let skybox1 = try await createSkyboxEntity(texture: "bubble_skybox1")
            skybox1.position = [0, 0, 0]
            newWorld1.addChild(skybox1)
        } catch {
            print("⚠️ BubbleBathImmersiveView: Failed to create bubble_skybox1 - \(error)")
        }
        worlds.addChild(newWorld1)
        self.world1 = newWorld1
        
        // World 2: bubble_skybox2
        let newWorld2 = Entity()
        newWorld2.components.set(WorldComponent())
        do {
            let skybox2 = try await createSkyboxEntity(texture: "bubble_skybox2")
            skybox2.position = [0, 0, 0]
            newWorld2.addChild(skybox2)
        } catch {
            print("⚠️ BubbleBathImmersiveView: Failed to create bubble_skybox2 - \(error)")
        }
        worlds.addChild(newWorld2)
        self.world2 = newWorld2
        
        // World 3: bubble_skybox3
        let newWorld3 = Entity()
        newWorld3.components.set(WorldComponent())
        do {
            let skybox3 = try await createSkyboxEntity(texture: "bubble_skybox3")
            skybox3.position = [0, 0, 0]
            newWorld3.addChild(skybox3)
        } catch {
            print("⚠️ BubbleBathImmersiveView: Failed to create bubble_skybox3 - \(error)")
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
        // Portal for world1 (bubble_skybox1) on Cube
        createPortalForCube(cube: cube, targetWorld: world1, isFlipped: false)
        
        // Portal for world2 (bubble_skybox2) on Cube2
        createPortalForCube(cube: cube2, targetWorld: world2, isFlipped: true)
        
        // Portal for world3 (bubble_skybox3) on Cube3
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
    
    /// 应用文字纹理到 PortalTriangleScene 中的 textbox 实体（Bubble Bath 主题）
    private func applyTextboxTextures(to sceneEntity: Entity) async {
        // Map of textbox names to texture file names (Bubble Bath)
        let textboxTextureMap: [String: String] = [
            "Springtime_textbox": "bubble_text",
            "Springtime_textbox2": "bubble_text2",
            "Springtime_textbox3": "bubble_text3"
        ]
        
        for (textboxName, textureName) in textboxTextureMap {
            guard let textbox = sceneEntity.findEntity(named: textboxName) else {
                print("⚠️ BubbleBathImmersiveView: Textbox '\(textboxName)' not found")
                continue
            }
            
            // Try to load texture from bundle
            var textureResource: TextureResource?
            
            // First try RealityKitContent bundle
            if let resource = try? await TextureResource(named: textureName, in: realityKitContentBundle) {
                textureResource = resource
                print("✅ BubbleBathImmersiveView: Loaded texture '\(textureName)' from RealityKitContent bundle")
            }
            // If not found, try main bundle
            else if let url = Bundle.main.url(forResource: textureName, withExtension: "png"),
                    let resource = try? await TextureResource.load(contentsOf: url) {
                textureResource = resource
                print("✅ BubbleBathImmersiveView: Loaded texture '\(textureName)' from main bundle")
            } else {
                print("⚠️ BubbleBathImmersiveView: Texture '\(textureName).png' not found in any bundle")
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
                print("✅ BubbleBathImmersiveView: Applied texture '\(textureName)' to '\(textboxName)' directly")
                applied = true
            }
            
            // Also apply to all children to ensure visibility
            for child in textbox.children {
                if var childModelComponent = child.components[ModelComponent.self] {
                    childModelComponent.materials = [material]
                    child.components.set(childModelComponent)
                    print("✅ BubbleBathImmersiveView: Applied texture '\(textureName)' to child '\(child.name)' of '\(textboxName)'")
                    applied = true
                }
            }
            
            if !applied {
                print("⚠️ BubbleBathImmersiveView: Could not find ModelComponent on '\(textboxName)' or its children")
            }
        }
    }
}

#Preview(immersionStyle: .full) {
    BubbleBathImmersiveView()
        .environment(AppModel())
}

