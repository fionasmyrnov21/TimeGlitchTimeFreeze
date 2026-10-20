import SpriteKit
import UIKit
import SwiftUI

final class GameScene: SKScene {
    var onFrame: ((Double) -> Void)?
    var onSelect: ((Int) -> Void)?
    private let world = SKNode()
    private let traveler = SKNode()
    private let cameraNode = SKCameraNode()
    private var objectNodes: [Int: SKNode] = [:]
    private var outlines: [Int: SKShapeNode] = [:]
    private var lastTime: TimeInterval = 0
    private var currentLevel: Level?
    private var effectsReduced = false
    private let lime = UIColor(red: 0.79, green: 0.97, blue: 0.36, alpha: 1)
    private let violet = UIColor(red: 0.65, green: 0.55, blue: 1, alpha: 1)

    func configure(engine: TimeEngine, reducedEffects: Bool) {
        removeAllChildren()
        world.removeAllChildren()
        traveler.removeAllChildren()
        objectNodes = [:]
        outlines = [:]
        currentLevel = engine.level
        effectsReduced = reducedEffects
        backgroundColor = UIColor(Palette.background)
        scaleMode = .resizeFill
        addChild(world)
        addChild(cameraNode)
        camera = cameraNode
        drawBackdrop()
        for rect in engine.level.floors {
            let floor = shape(rect: rect, color: UIColor(red: 0.12, green: 0.16, blue: 0.19, alpha: 1), radius: 3)
            floor.strokeColor = UIColor(white: 1, alpha: 0.15)
            world.addChild(floor)
            let edge = SKShapeNode(rect: CGRect(x: rect.minX, y: rect.maxY - 2, width: rect.width, height: 2))
            edge.fillColor = lime.withAlphaComponent(0.55)
            edge.strokeColor = .clear
            world.addChild(edge)
            for x in stride(from: rect.minX + 10, to: rect.maxX, by: 24) {
                let hatch = SKShapeNode()
                let path = CGMutablePath()
                path.move(to: CGPoint(x: x, y: rect.minY + 8))
                path.addLine(to: CGPoint(x: x + 18, y: rect.minY + 26))
                hatch.path = path
                hatch.strokeColor = UIColor(white: 1, alpha: 0.06)
                world.addChild(hatch)
            }
        }
        for object in engine.objects { makeObject(object) }
        makeTraveler()
        makeExit(x: engine.level.exit, floor: engine.level.exitHeight)
        world.addChild(traveler)
        lastTime = 0
        render(engine)
    }

    private func shape(rect: CGRect, color: UIColor, radius: CGFloat = 6) -> SKShapeNode {
        let node = SKShapeNode(rect: rect, cornerRadius: radius)
        node.fillColor = color
        node.strokeColor = color
        return node
    }

    private func drawBackdrop() {
        let fieldEnd = Int(currentLevel?.worldEnd ?? 1250) + 200
        for x in stride(from: -300, through: fieldEnd, by: 48) {
            for y in stride(from: -100, through: 800, by: 48) {
                let dot = SKShapeNode(circleOfRadius: 1)
                dot.position = CGPoint(x: x, y: y)
                dot.fillColor = UIColor(white: 1, alpha: 0.09)
                dot.strokeColor = .clear
                dot.zPosition = -5
                world.addChild(dot)
            }
        }
        for i in 0..<(fieldEnd / 180 + 2) {
            let column = shape(rect: CGRect(x: CGFloat(i * 180) - 180, y: 60, width: 100, height: CGFloat(160 + (i * 73) % 160)), color: UIColor(red: 0.065, green: 0.085, blue: 0.12, alpha: 1), radius: 0)
            column.zPosition = -3
            world.addChild(column)
        }
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = "SECTOR 0\(((currentLevel?.id ?? 1) - 1) / 5 + 1)  /  TEMPORAL FIELD"
        label.fontSize = 12
        label.fontColor = UIColor(white: 1, alpha: 0.18)
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: 20, y: 355)
        world.addChild(label)
        let route = SKLabelNode(fontNamed: "Menlo")
        route.text = currentLevel?.focus.uppercased()
        route.fontSize = 10
        route.fontColor = violet.withAlphaComponent(0.55)
        route.horizontalAlignmentMode = .left
        route.position = CGPoint(x: 20, y: 330)
        world.addChild(route)
    }

    private func makeObject(_ object: TemporalObject) {
        let group = SKNode()
        group.name = "object_\(object.id)"
        let size = object.spec.size
        let color: UIColor = object.spec.kind == .laser ? UIColor(red: 1, green: 0.4, blue: 0.44, alpha: 1) : object.spec.kind == .door ? violet : lime
        let body = shape(rect: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height), color: color.withAlphaComponent(0.17))
        body.strokeColor = color
        body.lineWidth = 2
        body.name = "body"
        group.addChild(body)
        if object.spec.kind == .laser {
            let beam = shape(rect: CGRect(x: -2, y: -size.height / 2, width: 4, height: size.height), color: color)
            beam.name = "beam"
            beam.glowWidth = effectsReduced ? 0 : 8
            group.addChild(beam)
        } else {
            let symbol = SKLabelNode(fontNamed: "Menlo-Bold")
            symbol.text = object.spec.kind == .platform ? object.spec.axis == .horizontal ? "↔" : "↕" : object.spec.kind == .block ? "↓" : "≡"
            symbol.fontSize = object.spec.kind == .platform ? 12 : 22
            symbol.fontColor = color
            symbol.verticalAlignmentMode = .center
            group.addChild(symbol)
        }
        let outline = SKShapeNode(rectOf: CGSize(width: max(size.width + 18, 48), height: max(size.height + 18, 48)), cornerRadius: 10)
        outline.strokeColor = .white
        outline.lineWidth = 1.5
        outline.isHidden = true
        group.addChild(outline)
        outlines[object.id] = outline
        let marker = SKLabelNode(fontNamed: "Menlo")
        marker.text = String(format: "%02d", object.id + 1)
        marker.fontSize = 10
        marker.fontColor = color
        marker.position = CGPoint(x: 0, y: size.height / 2 + 20)
        group.addChild(marker)
        world.addChild(group)
        objectNodes[object.id] = group
    }

    private func makeTraveler() {
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 30, height: 7))
        shadow.fillColor = lime.withAlphaComponent(0.18)
        shadow.strokeColor = .clear
        shadow.position.y = -20
        traveler.addChild(shadow)
        let body = shape(rect: CGRect(x: -10, y: -12, width: 20, height: 24), color: UIColor(white: 0.88, alpha: 1), radius: 5)
        traveler.addChild(body)
        let helmet = shape(rect: CGRect(x: -13, y: 3, width: 26, height: 23), color: .white, radius: 9)
        traveler.addChild(helmet)
        let visor = shape(rect: CGRect(x: -4, y: 9, width: 18, height: 10), color: UIColor(red: 0.09, green: 0.15, blue: 0.18, alpha: 1), radius: 4)
        traveler.addChild(visor)
        let glint = shape(rect: CGRect(x: 4, y: 14, width: 7, height: 2), color: lime, radius: 1)
        traveler.addChild(glint)
        for x: CGFloat in [-6, 6] {
            let foot = shape(rect: CGRect(x: x - 3, y: -19, width: 7, height: 10), color: UIColor(white: 0.65, alpha: 1), radius: 2)
            traveler.addChild(foot)
        }
        let pack = shape(rect: CGRect(x: -15, y: -7, width: 7, height: 17), color: violet, radius: 2)
        traveler.addChild(pack)
        traveler.zPosition = 5
    }

    private func makeExit(x: CGFloat, floor: CGFloat) {
        let arch = shape(rect: CGRect(x: x - 22, y: floor, width: 44, height: 90), color: lime.withAlphaComponent(0.08), radius: 20)
        arch.strokeColor = lime
        arch.lineWidth = 2
        arch.glowWidth = effectsReduced ? 0 : 4
        world.addChild(arch)
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = "EXIT"
        label.fontSize = 11
        label.fontColor = lime
        label.position = CGPoint(x: x, y: floor + 112)
        world.addChild(label)
    }

    func setReducedEffects(_ reduced: Bool) {
        effectsReduced = reduced
        func updateEffects(in node: SKNode) {
            if let shape = node as? SKShapeNode, reduced { shape.glowWidth = 0 }
            for child in node.children { updateEffects(in: child) }
        }
        updateEffects(in: world)
    }

    func select(_ id: Int) {
        for (key, outline) in outlines { outline.isHidden = key != id }
    }

    func render(_ engine: TimeEngine) {
        traveler.position = engine.traveler
        for object in engine.objects {
            guard let node = objectNodes[object.id] else { continue }
            node.position = CGPoint(x: object.rect.midX, y: object.rect.midY)
            if object.spec.kind == .laser {
                node.childNode(withName: "beam")?.alpha = object.active ? 1 : 0.08
                node.childNode(withName: "body")?.alpha = object.active ? 1 : 0.25
            }
            let outline = outlines[object.id]
            outline?.strokeColor = object.power == .freeze ? lime : object.power == .rewind ? violet : .white
            outline?.lineWidth = object.remaining > 0 ? 3 : 1.5
        }
        updateCamera()
    }

    private func updateCamera() {
        guard size.height > 0 else { return }
        let scale = 390 / size.height
        cameraNode.setScale(scale)
        let halfWidth = size.width * scale / 2
        let worldEnd = currentLevel?.worldEnd ?? 1250
        let minimumX = halfWidth - 30
        let maximumX = worldEnd - halfWidth
        let x = maximumX < minimumX ? (worldEnd - 30) / 2 : max(minimumX, min(traveler.position.x + halfWidth * 0.27, maximumX))
        cameraNode.position = CGPoint(x: x, y: max(195, traveler.position.y + 80))
    }

    override func didChangeSize(_ oldSize: CGSize) { updateCamera() }

    override func update(_ currentTime: TimeInterval) {
        let delta = lastTime > 0 ? min(currentTime - lastTime, 1.0 / 30) : 0
        lastTime = currentTime
        onFrame?(delta)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: world) else { return }
        let closest = objectNodes.min { a, b in
            hypot(a.value.position.x - point.x, a.value.position.y - point.y) < hypot(b.value.position.x - point.x, b.value.position.y - point.y)
        }
        if let closest, let level = currentLevel, let spec = level.objects.first(where: { $0.id == closest.key }), abs(closest.value.position.x - point.x) <= max(35, spec.size.width / 2 + 12), abs(closest.value.position.y - point.y) <= max(35, spec.size.height / 2 + 12) {
            select(closest.key)
            onSelect?(closest.key)
        }
    }
}
