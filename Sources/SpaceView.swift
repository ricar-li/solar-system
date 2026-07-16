import SwiftUI
import SceneKit

/// 3D 太阳系。行星绕太阳公转、自转；拖动旋转、双指缩放、点选；
/// 选中时镜头飞向并跟随；双击空白 / resetToken 重置全景。
struct SpaceView: UIViewRepresentable {
    var speed: Double
    var paused: Bool
    var showOrbits: Bool
    var showLabels: Bool
    var selectedID: String?
    /// 递增时重置相机与系统旋转。
    var resetToken: Int
    var onTapPlanet: (Planet) -> Void
    /// 双击空白重置时回调（用于清空选中等 UI 状态）。
    var onReset: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> SCNView {
        let v = SCNView()
        v.scene = context.coordinator.scene
        v.backgroundColor = .black
        v.antialiasingMode = .multisampling4X
        v.allowsCameraControl = false
        v.delegate = context.coordinator
        v.isPlaying = true
        v.rendersContinuously = true

        let pan = UIPanGestureRecognizer(
            target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        let pinch = UIPinchGestureRecognizer(
            target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        let tap = UITapGestureRecognizer(
            target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        tap.require(toFail: doubleTap)

        v.addGestureRecognizer(pan)
        v.addGestureRecognizer(pinch)
        v.addGestureRecognizer(tap)
        v.addGestureRecognizer(doubleTap)
        context.coordinator.scnView = v
        return v
    }

    func updateUIView(_ v: SCNView, context: Context) {
        let c = context.coordinator
        c.parent = self
        c.setOrbitsVisible(showOrbits)
        c.setLabelsVisible(showLabels)
        if resetToken != c.lastResetToken {
            c.lastResetToken = resetToken
            c.resetCamera()
        }
        c.applySelection(selectedID)
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject, SCNSceneRendererDelegate {
        var parent: SpaceView
        let scene = SCNScene()
        weak var scnView: SCNView?

        let systemNode = SCNNode()
        let cameraNode = SCNNode()
        private var cameraDistance: Float = 24
        private var lookTarget = SCNVector3Zero
        private var focused = false
        /// 飞向动画进行中时不抢写相机位置，避免打断缓动。
        private var isFlying = false
        /// 相对目标的单位方向（相机 = 目标 + offsetDir * cameraDistance）
        private var offsetDir = SCNVector3(0, 0.38, 1)

        private struct Spinner { let node: SCNNode; let omega: Float }
        private var spinners: [Spinner] = []
        private var lastTime: TimeInterval = 0

        private var planetNodes: [String: SCNNode] = [:]
        private var orbitRings: [SCNNode] = []
        private var labelNodes: [SCNNode] = []
        private var selectionRing: SCNNode?
        private var lastFocusedID: String?
        var lastResetToken: Int = 0

        /// 小行星最小可点半径（世界单位），方便小朋友点中。
        private let minHitRadius: Double = 0.45

        init(_ parent: SpaceView) {
            self.parent = parent
            super.init()
            scene.background.contents = TextureGenerator.starfield()
            scene.rootNode.addChildNode(systemNode)
            buildSun()
            for p in SolarData.planets { buildPlanet(p) }
            buildAsteroidBelt()
            setupCameraAndLight()
            normalizeOffsetDir()
        }

        private func omega(_ period: Double) -> Float { Float(2 * Double.pi / period) }

        private func normalizeOffsetDir() {
            var dx = offsetDir.x, dy = offsetDir.y, dz = offsetDir.z
            var len = sqrt(dx * dx + dy * dy + dz * dz)
            if len < 0.01 {
                dx = 0; dy = 0.38; dz = 1
                len = sqrt(dx * dx + dy * dy + dz * dz)
            }
            offsetDir = SCNVector3(dx / len, dy / len, dz / len)
        }

        private func buildSun() {
            let p = SolarData.sun
            let g = SCNSphere(radius: p.displayRadius)
            g.segmentCount = 80
            let m = SCNMaterial()
            m.diffuse.contents = TextureGenerator.planetTexture(for: p)
            m.emission.contents = TextureGenerator.planetTexture(for: p)
            m.emission.intensity = 0.9
            m.lightingModel = .constant
            g.materials = [m]
            let node = SCNNode(geometry: g)
            node.name = "planet:sun"
            systemNode.addChildNode(node)
            spinners.append(Spinner(node: node, omega: omega(p.spinPeriod)))
            planetNodes["sun"] = node

            let glow = SCNSphere(radius: p.displayRadius * 1.35)
            glow.segmentCount = 48
            let gm = SCNMaterial()
            gm.diffuse.contents = UIColor(hex: "FFD86B").withAlphaComponent(0.18)
            gm.lightingModel = .constant
            gm.isDoubleSided = true
            glow.materials = [gm]
            node.addChildNode(SCNNode(geometry: glow))

            addLabel(for: p, on: node, yOffset: Float(p.displayRadius + 0.6))
        }

        private func buildPlanet(_ p: Planet) {
            let orbit = SCNNode()
            orbit.eulerAngles.y = Float.random(in: 0 ..< (2 * Float.pi))
            systemNode.addChildNode(orbit)
            spinners.append(Spinner(node: orbit, omega: omega(p.orbitPeriod)))

            let holder = SCNNode()
            holder.position = SCNVector3(Float(p.orbitRadius), 0, 0)
            orbit.addChildNode(holder)

            let tilt = SCNNode()
            tilt.eulerAngles.z = Float(p.axialTilt * Double.pi / 180)
            holder.addChildNode(tilt)

            let g = SCNSphere(radius: p.displayRadius)
            g.segmentCount = 64
            let m = SCNMaterial()
            m.diffuse.contents = TextureGenerator.planetTexture(for: p)
            m.lightingModel = .blinn
            m.specular.contents = UIColor(white: 0.15, alpha: 1)
            g.materials = [m]
            let node = SCNNode(geometry: g)
            node.name = "planet:\(p.id)"
            tilt.addChildNode(node)
            spinners.append(Spinner(node: node, omega: omega(p.spinPeriod)))
            planetNodes[p.id] = node

            // 小行星加大隐形点击球，方便小朋友点中
            if p.displayRadius < minHitRadius {
                addHitSphere(to: node, radius: minHitRadius, planetID: p.id)
            }

            if p.hasRing { addRing(to: tilt, planet: p) }
            if p.id == "earth" { addMoon(to: holder, planetRadius: p.displayRadius) }

            addOrbitRing(radius: p.orbitRadius)
            addLabel(for: p, on: holder, yOffset: Float(p.displayRadius + 0.5))
        }

        /// 透明大球体，仅用于 hit-test。
        private func addHitSphere(to parent: SCNNode, radius: Double, planetID: String) {
            let g = SCNSphere(radius: radius)
            g.segmentCount = 12
            let m = SCNMaterial()
            m.diffuse.contents = UIColor.clear
            m.transparency = 0.0
            m.writesToDepthBuffer = false
            m.colorBufferWriteMask = []
            m.lightingModel = .constant
            g.materials = [m]
            let hit = SCNNode(geometry: g)
            hit.name = "planet:\(planetID)"
            hit.renderingOrder = -10
            parent.addChildNode(hit)
        }

        /// 火星(5.7)与木星(7.5)之间的程序化小行星带。
        private func buildAsteroidBelt() {
            let mid: Float = 6.55
            let beltRoot = SCNNode()
            systemNode.addChildNode(beltRoot)
            spinners.append(Spinner(node: beltRoot, omega: omega(100)))

            for i in 0..<180 {
                let angle = Float(i) / 180 * 2 * .pi + Float.random(in: -0.03...0.03)
                let r = mid + Float.random(in: -0.6...0.6)
                let y = Float.random(in: -0.1...0.1)
                let size = CGFloat.random(in: 0.018...0.055)
                let g = SCNSphere(radius: size)
                g.segmentCount = 5
                let m = SCNMaterial()
                let w = CGFloat.random(in: 0.42...0.72)
                m.diffuse.contents = UIColor(white: w, alpha: 1)
                m.lightingModel = .blinn
                g.materials = [m]
                let n = SCNNode(geometry: g)
                n.position = SCNVector3(cos(angle) * r, y, sin(angle) * r)
                n.name = "asteroid"
                beltRoot.addChildNode(n)
            }
        }

        private func addRing(to tilt: SCNNode, planet p: Planet) {
            let inner = p.displayRadius * 1.35
            let outer = p.displayRadius * 2.3
            let tube = SCNTube(innerRadius: inner, outerRadius: outer, height: 0.012)
            tube.radialSegmentCount = 96
            let m = SCNMaterial()
            let base = p.id == "saturn" ? "E6D2A0" : "BFE6EA"
            m.diffuse.contents = TextureGenerator.ringTexture(base: base)
            m.diffuse.wrapS = .repeat
            m.isDoubleSided = true
            m.lightingModel = .constant
            tube.materials = [m]
            tilt.addChildNode(SCNNode(geometry: tube))
        }

        private func addMoon(to holder: SCNNode, planetRadius: Double) {
            let moonOrbit = SCNNode()
            holder.addChildNode(moonOrbit)
            spinners.append(Spinner(node: moonOrbit, omega: omega(4)))
            let g = SCNSphere(radius: 0.1)
            let m = SCNMaterial()
            m.diffuse.contents = UIColor(hex: "C9C9CE")
            g.materials = [m]
            let moon = SCNNode(geometry: g)
            // 点月球也打开地球卡片（教育向）
            moon.name = "planet:earth"
            moon.position = SCNVector3(Float(planetRadius + 0.55), 0, 0)
            moonOrbit.addChildNode(moon)
            // 月球也加大点击范围
            addHitSphere(to: moon, radius: 0.35, planetID: "earth")
        }

        private func addOrbitRing(radius: Double) {
            let tube = SCNTube(innerRadius: radius - 0.012, outerRadius: radius + 0.012, height: 0.002)
            tube.radialSegmentCount = 140
            let m = SCNMaterial()
            m.diffuse.contents = UIColor.white.withAlphaComponent(0.18)
            m.lightingModel = .constant
            m.isDoubleSided = true
            tube.materials = [m]
            let ring = SCNNode(geometry: tube)
            systemNode.addChildNode(ring)
            orbitRings.append(ring)
        }

        private func addLabel(for p: Planet, on parent: SCNNode, yOffset: Float) {
            let img = TextureGenerator.labelImage(p.nameCN)
            let aspect = img.size.width / max(img.size.height, 1)
            let h: CGFloat = 0.42
            let plane = SCNPlane(width: h * aspect, height: h)
            let m = SCNMaterial()
            m.diffuse.contents = img
            m.isDoubleSided = true
            m.lightingModel = .constant
            plane.materials = [m]
            let label = SCNNode(geometry: plane)
            label.position = SCNVector3(0, yOffset, 0)
            label.constraints = [SCNBillboardConstraint()]
            parent.addChildNode(label)
            labelNodes.append(label)
        }

        private func setupCameraAndLight() {
            let cam = SCNCamera()
            cam.fieldOfView = 55
            cam.zNear = 0.1; cam.zFar = 500
            cameraNode.camera = cam
            cameraNode.position = SCNVector3(0, 9, cameraDistance)
            cameraNode.look(at: SCNVector3Zero)
            scene.rootNode.addChildNode(cameraNode)

            let sunLight = SCNNode()
            sunLight.light = SCNLight()
            sunLight.light?.type = .omni
            sunLight.light?.intensity = 1600
            sunLight.light?.attenuationStartDistance = 2
            sunLight.light?.attenuationEndDistance = 60
            systemNode.addChildNode(sunLight)

            let ambient = SCNNode()
            ambient.light = SCNLight()
            ambient.light?.type = .ambient
            ambient.light?.intensity = 350
            ambient.light?.color = UIColor(white: 0.8, alpha: 1)
            scene.rootNode.addChildNode(ambient)
        }

        // MARK: 渲染循环
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            defer { lastTime = time }
            guard lastTime > 0 else { return }
            var dt = Float(time - lastTime)
            if dt > 0.1 { dt = 0.1 }
            let mult = parent.paused ? 0 : Float(parent.speed)

            // 公转 / 自转
            if mult > 0 {
                for s in spinners {
                    s.node.eulerAngles.y += dt * s.omega * mult
                }
            }

            // 选中跟随时：每帧更新 lookTarget，保持相机相对偏移
            // 飞向动画期间不抢写位置，只同步 lookTarget
            if focused, let id = lastFocusedID, let node = planetNodes[id] {
                let target = node.presentation.worldPosition
                lookTarget = target
                if !isFlying {
                    cameraNode.position = SCNVector3(
                        target.x + offsetDir.x * cameraDistance,
                        target.y + offsetDir.y * cameraDistance,
                        target.z + offsetDir.z * cameraDistance)
                    cameraNode.look(at: target)
                }
            }
        }

        // MARK: 状态
        func setOrbitsVisible(_ on: Bool) { orbitRings.forEach { $0.isHidden = !on } }
        func setLabelsVisible(_ on: Bool) { labelNodes.forEach { $0.isHidden = !on } }

        func applySelection(_ id: String?) {
            selectionRing?.removeFromParentNode()
            selectionRing = nil

            // 清空选中：复位焦点标记，不强制改相机（双击/全景按钮会 reset）
            guard let id, let target = planetNodes[id], let p = SolarData.planet(id: id) else {
                if lastFocusedID != nil {
                    lastFocusedID = nil
                    focused = false
                }
                return
            }

            let radius = p.displayRadius * 1.6
            let tube = SCNTube(innerRadius: radius, outerRadius: radius + 0.05, height: 0.02)
            tube.radialSegmentCount = 80
            let m = SCNMaterial()
            m.diffuse.contents = UIColor(hex: "7FE0FF")
            m.emission.contents = UIColor(hex: "7FE0FF")
            m.lightingModel = .constant
            tube.materials = [m]
            let ring = SCNNode(geometry: tube)
            ring.constraints = [SCNBillboardConstraint()]
            ring.runAction(.repeatForever(.sequence([
                .scale(to: 1.12, duration: 0.7), .scale(to: 1.0, duration: 0.7)])))
            target.addChildNode(ring)
            selectionRing = ring

            if id != lastFocusedID {
                lastFocusedID = id
                focusOn(id: id, planet: p, node: target)
            }
        }

        private func focusOn(id: String, planet p: Planet, node: SCNNode) {
            // presentation 含当前动画帧上的世界坐标
            let target = node.presentation.worldPosition
            let dist = Float(max(p.displayRadius * 6.0 + 2.5, id == "sun" ? 7 : 4.5))
            let cam = cameraNode.presentation.worldPosition
            var dx = cam.x - target.x
            var dy = cam.y - target.y
            var dz = cam.z - target.z
            var len = sqrt(dx * dx + dy * dy + dz * dz)
            if len < 0.15 {
                dx = 0.35; dy = 0.55; dz = 1.0
                len = sqrt(dx * dx + dy * dy + dz * dz)
            }
            dx /= len; dy /= len; dz /= len
            if abs(dy) < 0.2 {
                dy = 0.35
                let n = sqrt(dx * dx + dy * dy + dz * dz)
                dx /= n; dy /= n; dz /= n
            }
            offsetDir = SCNVector3(dx, dy, dz)
            let newPos = SCNVector3(
                target.x + dx * dist,
                target.y + dy * dist,
                target.z + dz * dist)

            lookTarget = target
            focused = true
            cameraDistance = dist
            isFlying = true

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.85
            SCNTransaction.animationTimingFunction =
                CAMediaTimingFunction(name: .easeInEaseOut)
            SCNTransaction.completionBlock = { [weak self] in
                self?.isFlying = false
            }
            cameraNode.position = newPos
            cameraNode.look(at: target)
            SCNTransaction.commit()
        }

        func resetCamera() {
            focused = false
            lastFocusedID = nil
            isFlying = false
            cameraDistance = 24
            lookTarget = SCNVector3Zero
            offsetDir = SCNVector3(0, 0.38, 1)
            normalizeOffsetDir()
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.7
            SCNTransaction.animationTimingFunction =
                CAMediaTimingFunction(name: .easeInEaseOut)
            systemNode.transform = SCNMatrix4Identity
            cameraNode.position = SCNVector3(0, 9, 24)
            cameraNode.look(at: SCNVector3Zero)
            SCNTransaction.commit()
        }

        // MARK: 手势
        @objc func handlePan(_ g: UIPanGestureRecognizer) {
            guard let v = g.view else { return }
            let t = g.translation(in: v)
            let f: Float = 0.006
            let ry = SCNMatrix4MakeRotation(Float(t.x) * f, 0, 1, 0)
            let rx = SCNMatrix4MakeRotation(Float(t.y) * f, 1, 0, 0)
            systemNode.transform = SCNMatrix4Mult(systemNode.transform, SCNMatrix4Mult(ry, rx))
            g.setTranslation(.zero, in: v)
        }

        @objc func handlePinch(_ g: UIPinchGestureRecognizer) {
            guard g.state == .changed else { return }
            cameraDistance = max(4, min(80, cameraDistance / Float(g.scale)))
            if focused {
                let t = lookTarget
                // 保持当前 offsetDir，只改距离
                normalizeOffsetDir()
                cameraNode.position = SCNVector3(
                    t.x + offsetDir.x * cameraDistance,
                    t.y + offsetDir.y * cameraDistance,
                    t.z + offsetDir.z * cameraDistance)
                cameraNode.look(at: t)
            } else {
                cameraNode.position = SCNVector3(0, cameraDistance * 0.38, cameraDistance)
                cameraNode.look(at: SCNVector3Zero)
            }
            g.scale = 1
        }

        /// 从节点向上找带 `planet:` 前缀的名字（兼容点击子节点 / 光晕 / 隐形点击球）。
        private func planetID(from node: SCNNode) -> String? {
            var n: SCNNode? = node
            while let cur = n {
                if let name = cur.name, name.hasPrefix("planet:") {
                    return String(name.dropFirst("planet:".count))
                }
                n = cur.parent
            }
            return nil
        }

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let v = scnView else { return }
            let hits = v.hitTest(g.location(in: v),
                                 options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue])
            for h in hits {
                if let id = planetID(from: h.node), let p = SolarData.planet(id: id) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    parent.onTapPlanet(p)
                    return
                }
            }
        }

        @objc func handleDoubleTap(_ g: UITapGestureRecognizer) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            resetCamera()
            parent.onReset?()
        }
    }
}
