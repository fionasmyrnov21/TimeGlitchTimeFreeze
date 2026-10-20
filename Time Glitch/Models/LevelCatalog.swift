import Foundation
import CoreGraphics

enum LevelCatalog {
    private static func ground(_ start: CGFloat, _ end: CGFloat, _ top: CGFloat = 100) -> CGRect {
        CGRect(x: start, y: top - 60, width: end - start, height: 60)
    }

    private static func lift(_ id: Int, _ x: CGFloat, _ top: CGFloat = 108, width: CGFloat = 116, travel: CGFloat = 36, period: Double = 4.8, offset: Double = 0, axis: MotionAxis = .vertical) -> ObjectSpec {
        ObjectSpec(id: id, kind: .platform, origin: CGPoint(x: x, y: top - 9), size: CGSize(width: width, height: 18), travel: travel, period: period, offset: offset, axis: axis)
    }

    private static func block(_ id: Int, _ x: CGFloat, _ lowTop: CGFloat = 166, width: CGFloat = 54, travel: CGFloat = 110, period: Double = 4.6, offset: Double = 0.8) -> ObjectSpec {
        ObjectSpec(id: id, kind: .block, origin: CGPoint(x: x, y: lowTop - width / 2), size: CGSize(width: width, height: width), travel: travel, period: period, offset: offset)
    }

    private static func beam(_ id: Int, _ x: CGFloat, _ floor: CGFloat = 100, period: Double = 4.8, offset: Double = 0, duty: Double = 0.45) -> ObjectSpec {
        ObjectSpec(id: id, kind: .laser, origin: CGPoint(x: x, y: floor + 65), size: CGSize(width: 12, height: 130), travel: 0, period: period, offset: offset, activeFraction: duty)
    }

    private static func door(_ id: Int, _ x: CGFloat, _ floor: CGFloat = 100, period: Double = 4.8, offset: Double = 1.5, duty: Double = 0.48) -> ObjectSpec {
        ObjectSpec(id: id, kind: .door, origin: CGPoint(x: x, y: floor + 60), size: CGSize(width: 28, height: 120), travel: 140, period: period, offset: offset, activeFraction: duty)
    }

    private static func level(_ id: Int, _ title: String, _ focus: String, _ hint: String, par: Int, speed: CGFloat = 52, floors: [CGRect], objects: [ObjectSpec], exit: CGFloat) -> Level {
        let chapters = ["THE AWAKENING", "SHIFTING MATTER", "BROKEN SECONDS", "THE CONVERGENCE"]
        return Level(id: id, title: title, chapter: chapters[(id - 1) / 5], hint: hint, focus: focus, par: par, speed: speed, objects: objects, floors: floors, exit: exit)
    }

    static let levels: [Level] = [
        level(1, "First fracture", "A single crossing", "Hold the lift near path height to bridge your first gap.", par: 2, speed: 48,
              floors: [ground(-120, 290), ground(390, 790)],
              objects: [lift(0, 340, travel: 140, offset: 1.4)], exit: 700),
        level(2, "A moment held", "Matter becomes a bridge", "Catch the descending block level with the shores before it drops into the gap. It becomes your stepping stone.", par: 2, speed: 48,
              floors: [ground(-120, 320), ground(400, 850)],
              objects: [block(0, 360, -100, width: 88, travel: 280, period: 5.2, offset: 0.43333333333333335)], exit: 760),
        level(3, "Against the current", "A corridor of pulses", "There is no gap here. Hold each laser while dim; their clocks are independent.", par: 3,
              floors: [ground(-120, 940)],
              objects: [beam(0, 340, period: 4.6, offset: 0.6), beam(1, 650, period: 5.1, offset: 2.2)], exit: 850),
        level(4, "Double time", "The waiting room", "The traveler waits at closed doors. Accelerate a door to bring its opening closer.", par: 3,
              floors: [ground(-120, 1020)],
              objects: [door(0, 300, period: 6.2, offset: 0, duty: 0.7), door(1, 590, period: 5.6, offset: 1, duty: 0.65), beam(2, 800, period: 5.2, offset: 1)], exit: 930),
        level(5, "The crossing", "Two separate islands", "Save one freeze for each crossing. The small central island is safe ground.", par: 3, speed: 50,
              floors: [ground(-120, 270), ground(370, 610), ground(710, 1070)],
              objects: [lift(0, 320, travel: 140, offset: 2), lift(1, 660, travel: 48, period: 5.4, offset: 2)], exit: 980),
        level(6, "Falling into place", "The ascending staircase", "The traveler climbs small steps automatically. Hold blocks overhead to keep the staircase clear, or catch them low as steps.", par: 3,
              floors: [ground(-120, 260), ground(260, 490, 150), ground(490, 730, 200), ground(730, 1120, 150)],
              objects: [block(0, 365, 208, travel: 100, period: 5.2), block(1, 620, 258, travel: 95, period: 4.5, offset: 2)], exit: 1030),
        level(7, "Red intervals", "Three independent rhythms", "Three lasers, three rhythms. A frozen laser stays safe only if you catch its dim phase.", par: 4, speed: 55,
              floors: [ground(-120, 1190)],
              objects: [beam(0, 300, period: 4.3, offset: 0.3), beam(1, 610, period: 5.3, offset: 1.7), beam(2, 930, period: 4.7, offset: 3.1)], exit: 1100),
        level(8, "An open moment", "The sliding bridge", "The platform moves sideways. Freeze it when it spans both shores, then open the door ahead.", par: 3,
              floors: [ground(-120, 320), ground(420, 990)],
              objects: [lift(0, 370, 108, width: 140, travel: 100, period: 5.6, offset: 1.8666666666666665, axis: .horizontal), door(1, 720, period: 5.8, offset: 2)], exit: 900),
        level(9, "Perfect alignment", "A bridge in two pieces", "The long chasm needs both platforms. Align and hold each half before the traveler reaches it.", par: 3, speed: 50,
              floors: [ground(-120, 300), ground(500, 1060)],
              objects: [lift(0, 345, 108, width: 112, travel: 140, period: 5.6, offset: 1.8666666666666665), lift(1, 455, 116, width: 112, travel: 34, period: 5.1, offset: 2.3)], exit: 970),
        level(10, "Borrowed seconds", "A block and a pulse", "Make a bridge from the block, then prepare the laser while you are still on solid ground.", par: 3,
              floors: [ground(-120, 300), ground(386, 1010)],
              objects: [block(0, 343, -100, width: 94, travel: 280, period: 5.4, offset: 0), beam(1, 690, period: 5.5, offset: 0.8)], exit: 920),
        level(11, "The long pause", "A raised crossing", "Climb to the upper ledge. The lift must connect the raised shores, not the lower path.", par: 4, speed: 54,
              floors: [ground(-120, 260), ground(260, 440, 155), ground(550, 800, 155), ground(800, 1200, 100)],
              objects: [lift(0, 495, 163, width: 130, travel: 140, period: 5.8, offset: 0.24166666666666667), beam(1, 710, 155, period: 5.1, offset: 2.1)], exit: 1110),
        level(12, "Echo chamber", "Doors between pulses", "A closed door can give you time to set up the next laser. Change the obstacle that matters next.", par: 5,
              floors: [ground(-120, 1390)],
              objects: [door(0, 270, period: 5.6, offset: 0.2), beam(1, 510, period: 5.3, offset: 1.8), door(2, 780, period: 6.1, offset: 2.2), beam(3, 1100, period: 5.9, offset: 0.7)], exit: 1300),
        level(13, "Out of sequence", "Two suspended blocks", "Each block has its own clock. Leave the first behind and turn the second into a bridge.", par: 4, speed: 50,
              floors: [ground(-120, 280), ground(364, 690), ground(774, 1190)],
              objects: [block(0, 322, -100, width: 92, travel: 280, period: 5.1, offset: 1.275), block(1, 732, 122, width: 92, travel: 145, period: 5.8, offset: 2.3)], exit: 1100),
        level(14, "Narrow escape", "Cross, then synchronize", "Hold the sideways platform across the gap. The two lasers beyond it are deliberately out of phase.", par: 5, speed: 56,
              floors: [ground(-120, 300), ground(410, 1300)],
              objects: [lift(0, 355, 108, width: 154, travel: 40, period: 5.2, offset: 0.21666666666666667, axis: .horizontal), beam(1, 680, period: 5.2, offset: 0.2), beam(2, 1010, period: 5.2, offset: 2.6)], exit: 1210),
        level(15, "Two timelines", "Up and down", "Height changes the route. Hold a block overhead or low enough to climb, then open the door on the summit.", par: 5,
              floors: [ground(-120, 240), ground(240, 480, 145), ground(480, 720, 195), ground(720, 950, 145), ground(950, 1350, 100)],
              objects: [block(0, 350, 205, travel: 105, offset: 1.3), door(1, 610, 195, period: 5.7, offset: 1), block(2, 830, 205, travel: 120, period: 5.3, offset: 2.6)], exit: 1260),
        level(16, "Chain reaction", "Three crossings, three heights", "Each island is higher than the last. Use the height of the next shore to judge the platform's alignment.", par: 5, speed: 54,
              floors: [ground(-120, 260), ground(360, 570, 135), ground(680, 900, 170), ground(1010, 1430, 135)],
              objects: [lift(0, 310, 126, width: 130, travel: 180, period: 5.8, offset: 2.658333333333333), lift(1, 625, 161, width: 138, travel: 36, period: 5.5, offset: 1.6), lift(2, 955, 178, width: 138, travel: 38, period: 5.7, offset: 2.8)], exit: 1340),
        level(17, "Critical window", "The alternating corridor", "Doors divide four different clock cycles. Work from left to right and avoid changing a distant gate too early.", par: 6, speed: 57,
              floors: [ground(-120, 1530)],
              objects: [beam(0, 300, period: 5.4, offset: 1.125, duty: 0.58), door(1, 580, period: 5.8, offset: 2.6, duty: 0.62), beam(2, 880, period: 5.7, offset: 1.6, duty: 0.58), door(3, 1190, period: 6.2, offset: 0.4, duty: 0.65)], exit: 1440),
        level(18, "The last interval", "An archipelago of time", "The final island is not the finish. Save a safe laser phase for the run after three separate crossings.", par: 6, speed: 55,
              floors: [ground(-120, 240), ground(340, 540), ground(640, 850), ground(950, 1510)],
              objects: [lift(0, 290, width: 122, travel: 140, period: 5.6, offset: 0.2333333333333333), lift(1, 590, width: 140, travel: 34, period: 5.4, offset: 1.7, axis: .horizontal), block(2, 900, 115, width: 110, travel: 120, period: 5.8, offset: 2.4), beam(3, 1220, period: 5.6, offset: 2)], exit: 1420),
        level(19, "Beyond the clock", "The broken summit", "Cross the high gap, descend through a pulse, then prepare the moving bridge on the lower path.", par: 6, speed: 56,
              floors: [ground(-120, 240), ground(240, 440, 150), ground(550, 780, 150), ground(780, 1000, 100), ground(1110, 1550, 100)],
              objects: [lift(0, 495, 158, width: 132, travel: 140, period: 5.5, offset: 0.22916666666666666), beam(1, 860, period: 5.4, offset: 1.3), lift(2, 1055, 108, width: 150, travel: 32, period: 5.1, offset: 2.2, axis: .horizontal), door(3, 1320, period: 5.7, offset: 1.8)], exit: 1460),
        level(20, "Time, rewritten", "Every clock has a part", "A lift, a suspended block, a sliding bridge, and two gates. Solve each local timeline to restore the whole route.", par: 8, speed: 55,
              floors: [ground(-120, 260), ground(360, 590, 135), ground(680, 970, 135), ground(1080, 1690, 100)],
              objects: [lift(0, 310, 126, width: 130, travel: 32, period: 5.9, offset: 0.7), block(1, 635, 145, width: 102, travel: 120, period: 5.6, offset: 1.4), door(2, 820, 135, period: 5.8, offset: 2), lift(3, 1025, 128, width: 150, travel: 34, period: 5.5, offset: 2.7, axis: .horizontal), beam(4, 1360, period: 5.7, offset: 0.9)], exit: 1600)
    ]
}
