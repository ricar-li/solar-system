import SwiftUI
import SceneKit

/// 3D 太阳系。行星绕太阳公转、自转，可拖动旋转视角、双指缩放、点击查看天体。
struct SpaceView: UIViewRepresentable {
    var speed: Double
    var paused: Bool
    var showOrbits: Bool
    var showLabels: Bool
    var selectedID: String?
    var onTapPlanet: (Planet) -> Void

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
        v.addGestureRecognizer(UIPanGestureRecognizer(
            target: context.coordinator, action: #selector(Coordinator.handlePan(_:))))
        v.addGestureRecognizer(UIPinchGestureRecognizer(
            target: context.coordinator, action: #selector(Coordinator.handlePinch(_:))))
        v.addGestureRecognizer(UITapGestureRecognizer(
            target: context.coordinator, action: #selector(Coordinator.handleTap(_:))))
        context.coordinator.scnView = v
        return v
    }

    func updateUIView(_ v: SCNView, context: Context) {
        let c = context.coordinator
        c.parent = self
        c.setOrbitsVisible(showOrbits)
        c.setLabelsVisible(showLabels)
        c.applySelection(selectedID)
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject, SCNSceneRendererDelegate {
        var parent: SpaceView
        let scene = SCNScene()
        weak var scnView: SCNView?

        let systemNode = SCNNode()      // 容纳太阳与所有轨道
        let cameraNode = SCNNode()
        private var cameraDistance: Float = 24

        /// 需要每帧旋转的节点（绕自身 Y 轴）+ 角速度(弧度/秒, speed=1)
        private struct Spinner { let node: SCNNode; let omega: Float }
        private var spinners: [Spinner] = []
        private var lastTime: TimeInterval = 0

        private var planetNodes: [String: SCNNode] = [:]
        private var orbitRings: [SCNNode] = []
        private var labelNodes: [SCNNode] = []
        private var selectionRing: SCNNode?

        init(_ parent: SpaceView) {
            self.parent = parent
            super.init()
            scene.background.contents = TextureGenerator.starfield()
            scene.rootNode.addChildNode(systemNode)
            buildSun()
            for p in SolarData.planets { buildPlanet(p) }
            setupCameraAndLight()
        }

        private func omega(_ period: Double) -> Float { Float(2 * Double.pi / period) }

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
            // 公转节点
            let orbit = SCNNode()
            orbit.eulerAngles.y = Float.random(in: 0 ..< (2 * Float.pi))
            systemNode.addChildNode(orbit)
            spinners.append(Spinner(node: orbit, omega: omega(p.orbitPeriod)))

            // 位置节点
            let holder = SCNNode()
            holder.position = SCNVector3(Float(p.orbitRadius), 0, 0)
            orbit.addChildNode(holder)

            // 轴倾角节点
            let tilt = SCNNode()
            tilt.eulerAngles.z = Float(p.axialTilt * Double.pi / 180)
            holder.addChildNode(tilt)

            // 行星本体（自转）
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

            if p.hasRing { addRing(to: tilt, planet: p) }
            if p.id == "earth" { addMoon(to: holder, planetRadius: p.displayRadius) }

            addOrbitRing(radius: p.orbitRadius)
            addLabel(for: p, on: holder, yOffset: Float(p.displayRadius + 0.5))
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
            moon.name = "planet:earth"
            moon.position = SCNVector3(Float(planetRadius + 0.55), 0, 0)
            moonOrbit.addChildNode(moon)
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

        // MARK: 渲染循环（手动驱动公转/自转，便于控制速度与暂停）
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            defer { lastTime = time }
            guard lastTime > 0 else { return }
            var dt = Float(time - lastTime)
            if dt > 0.1 { dt = 0.1 }
            let mult = parent.paused ? 0 : Float(parent.speed)
            guard mult > 0 else { return }
            for s in spinners {
                s.node.eulerAngles.y += dt * s.omega * mult
            }
        }

        // MARK: 状态应用
        func setOrbitsVisible(_ on: Bool) { orbitRings.forEach { $0.isHidden = !on } }
        func setLabelsVisible(_ on: Bool) { labelNodes.forEach { $0.isHidden = !on } }

        func applySelection(_ id: String?) {
            selectionRing?.removeFromParentNode()
            selectionRing = nil
            guard let id, let target = planetNodes[id], let p = SolarData.planet(id: id) else { return }
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
            if g.state == .changed {
                cameraDistance = max(6, min(60, cameraDistance / Float(g.scale)))
                cameraNode.position = SCNVector3(0, cameraDistance * 0.38, cameraDistance)
                cameraNode.look(at: SCNVector3Zero)
                g.scale = 1
            }
        }

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let v = scnView else { return }
            let hits = v.hitTest(g.location(in: v),
                                 options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue])
            for h in hits {
                if let name = h.node.name, name.hasPrefix("planet:") {
                    let id = String(name.dropFirst("planet:".count))
                    if let p = SolarData.planet(id: id) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        parent.onTapPlanet(p)
                        return
                    }
                }
            }
        }
    }
}
