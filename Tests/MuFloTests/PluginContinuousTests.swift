#if !os(watchOS)
import Foundation
import XCTest

@testable import MuFlo

/// plugin edge `^- path` tweens continuous scalars;
/// a discrete `m_n` rangei scalar keeps value and tween instant
final class PluginContinuousTests: XCTestCase {

    let floParse = FloParse()
    let sky = "sky { main { anim(x 0…10=2) } }"

    /// T1: capture set of a mixed host holds the continuous scalar only
    func testPluginCapturesContinuous() {
        let root = Flo("√")
        let script = sky + " a(x 0_10=1, y 0…1=0, ^- sky.main.anim)"
        guard floParse.parseRoot(root, script),
              let a = root.findPath("a") else {
            return XCTFail("parse failed: \(script)")
        }
        XCTAssertEqual(a.plugins.count, 1, "a expected 1 plugin, got \(a.plugins.count)")
        let names = a.plugins.first?.floScalars.map { $0.name } ?? []
        XCTAssertEqual(names, ["y"], "capture set expected [y], got \(names)")
    }

    /// T2: discrete x passes through to tween, continuous y defers tween to plugin
    func testDiscreteWriteIsInstant() {
        let root = Flo("√")
        let script = sky + " a(x 0_10=1, y 0…1=0, ^- sky.main.anim)"
        guard floParse.parseRoot(root, script),
              let a = root.findPath("a"),
              let exprs = a.exprs else {
            return XCTFail("parse failed: \(script)")
        }
        a.setNameNums([("x", 7), ("y", 0.8)], .fire)

        XCTAssertEqual(a.val("x"), 7, "x value expected 7, got \(String(describing: a.val("x")))")
        XCTAssertEqual(exprs["x", .tween], 7, "x tween expected 7, got \(String(describing: exprs["x", .tween]))")
        XCTAssertEqual(a.val("y"), 0.8, "y value expected 0.8, got \(String(describing: a.val("y")))")
        XCTAssertEqual(exprs["y", .tween], 0, "y tween expected prior 0, got \(String(describing: exprs["y", .tween]))")
    }

    /// T3: continuous y tweens across frames towards its value
    func testContinuousTweenConverges() {
        let root = Flo("√")
        let script = sky + " a(x 0_10=1, y 0…1=0, ^- sky.main.anim)"
        guard floParse.parseRoot(root, script),
              let a = root.findPath("a"),
              let exprs = a.exprs else {
            return XCTFail("parse failed: \(script)")
        }
        a.setNameNums([("y", 0.8)], .fire)

        driveFrames(0.4)
        let midTween = exprs["y", .tween] ?? -1
        XCTAssert(midTween > 0 && midTween < 0.8,
                  "mid-flight y tween expected between 0 and 0.8, got \(midTween)")

        driveFrames(2.2) // 2.6s total, past the 2.0s duration
        let endTween = exprs["y", .tween] ?? -1
        XCTAssert(abs(endTween - 0.8) < 0.01,
                  "settled y tween expected 0.8, got \(endTween)")
    }

    /// T4: a host of only discrete scalars gets no plugin
    func testDiscreteOnlyHost() {
        let root = Flo("√")
        let script = sky + " b(x 0_10=1, ^- sky.main.anim)"
        guard floParse.parseRoot(root, script),
              let b = root.findPath("b"),
              let exprs = b.exprs else {
            return XCTFail("parse failed: \(script)")
        }
        XCTAssertEqual(b.plugins.count, 0, "b expected 0 plugins, got \(b.plugins.count)")

        b.setNameNums([("x", 5)], .fire)
        XCTAssertEqual(b.val("x"), 5, "x value expected 5, got \(String(describing: b.val("x")))")
        XCTAssertEqual(exprs["x", .tween], 5, "x tween expected 5, got \(String(describing: exprs["x", .tween]))")
    }

    /// T5: a host of only continuous scalars captures all of them
    func testContinuousOnlyHost() {
        let root = Flo("√")
        let script = sky + " c(x 0…1, y 0…1, ^- sky.main.anim)"
        guard floParse.parseRoot(root, script),
              let c = root.findPath("c"),
              let exprs = c.exprs else {
            return XCTFail("parse failed: \(script)")
        }
        XCTAssertEqual(c.plugins.count, 1, "c expected 1 plugin, got \(c.plugins.count)")
        let names = c.plugins.first?.floScalars.map { $0.name }.sorted() ?? []
        XCTAssertEqual(names, ["x", "y"], "capture set expected [x, y], got \(names)")

        c.setNameNums([("x", 0.4), ("y", 0.6)], .fire)
        XCTAssertEqual(c.val("x"), 0.4, "x value expected 0.4, got \(String(describing: c.val("x")))")
        XCTAssertEqual(exprs["x", .tween], 0, "x tween expected prior 0, got \(String(describing: exprs["x", .tween]))")
    }

    /// T6: scoped `^- path(z)` captures only the named host scalar
    func testMappedPluginCapturesNamed() {
        let root = Flo("√")
        let script = sky + " d(x 0…1, y 0…1, z 0…1, ^- sky.main.anim(z))"
        guard floParse.parseRoot(root, script),
              let d = root.findPath("d"),
              let exprs = d.exprs else {
            return XCTFail("parse failed: \(script)")
        }
        XCTAssertEqual(d.plugins.count, 1, "d expected 1 plugin, got \(d.plugins.count)")
        let names = d.plugins.first?.floScalars.map { $0.name } ?? []
        XCTAssertEqual(names, ["z"], "capture set expected [z], got \(names)")

        d.setNameNums([("x", 0.4), ("y", 0.6), ("z", 0.8)], .fire)
        XCTAssertEqual(d.val("x"), 0.4, "x value expected 0.4, got \(String(describing: d.val("x")))")
        XCTAssertEqual(exprs["x", .tween], 0.4, "unnamed x tween expected instant 0.4, got \(String(describing: exprs["x", .tween]))")
        XCTAssertEqual(exprs["y", .tween], 0.6, "unnamed y tween expected instant 0.6, got \(String(describing: exprs["y", .tween]))")
        XCTAssertEqual(d.val("z"), 0.8, "z value expected 0.8, got \(String(describing: d.val("z")))")
        XCTAssertEqual(exprs["z", .tween], 0, "named z tween expected prior 0, got \(String(describing: exprs["z", .tween]))")
    }

    /// T7: mergeFloValues (snapshot restore) arms the plugin so tween converges
    func testMergeArmsPlugin() {
        let rootA = Flo("√")
        let rootB = Flo("√")
        let scriptA = sky + " a(x 0_10=1, y 0…1=0, ^- sky.main.anim)"
        let scriptB = sky + " a(x 0_10=3, y 0…1=0.9, ^- sky.main.anim)"
        guard floParse.parseRoot(rootA, scriptA),
              floParse.parseRoot(rootB, scriptB),
              let a = rootA.findPath("a"),
              let exprs = a.exprs else {
            return XCTFail("parse failed")
        }
        rootA.bindHashFlo()
        rootB.bindHashFlo()
        rootA.mergeFloValues(rootB)

        XCTAssertEqual(a.val("y"), 0.9, "merged y value expected 0.9, got \(String(describing: a.val("y")))")
        XCTAssertEqual(exprs["x", .tween], 3, "discrete x tween snaps on merge, got \(String(describing: exprs["x", .tween]))")

        driveFrames(2.6) // past the 2.0s duration
        let endTween = exprs["y", .tween] ?? -1
        XCTAssert(abs(endTween - 0.9) < 0.01,
                  "restored y tween expected 0.9, got \(endTween)")
    }

    /// CADisplayLink stays paused under XCTest, so each frame is forced
    func driveFrames(_ seconds: TimeInterval) {
        let until = Date().timeIntervalSince1970 + seconds
        while Date().timeIntervalSince1970 < until {
            _ = NextFrame.shared.nextFrame(force: true)
            Thread.sleep(forTimeInterval: 0.016)
        }
    }

    /// T8: named z tweens across frames while unnamed x stays instant
    func testMappedTweenConverges() {
        let root = Flo("√")
        let script = sky + " d(x 0…1, y 0…1, z 0…1, ^- sky.main.anim(z))"
        guard floParse.parseRoot(root, script),
              let d = root.findPath("d"),
              let exprs = d.exprs else {
            return XCTFail("parse failed: \(script)")
        }
        d.setNameNums([("x", 0.4), ("z", 0.8)], .fire)

        driveFrames(0.4)
        XCTAssertEqual(exprs["x", .tween], 0.4, "x tween expected 0.4 mid-flight, got \(String(describing: exprs["x", .tween]))")
        let midTween = exprs["z", .tween] ?? -1
        XCTAssert(midTween > 0 && midTween < 0.8,
                  "mid-flight z tween expected between 0 and 0.8, got \(midTween)")

        driveFrames(2.2) // 2.6s total, past the 2.0s duration
        let endTween = exprs["z", .tween] ?? -1
        XCTAssert(abs(endTween - 0.8) < 0.01,
                  "settled z tween expected 0.8, got \(endTween)")
    }

    /// T9: a scope naming a discrete or unknown scalar captures nothing, so no plugin
    func testMappedDiscreteOrUnknownName() {
        let root = Flo("√")
        let script = sky + " e(x 0_10=1, y 0…1, ^- sky.main.anim(x)) f(y 0…1, ^- sky.main.anim(q))"
        guard floParse.parseRoot(root, script),
              let e = root.findPath("e"),
              let exprsE = e.exprs,
              let f = root.findPath("f"),
              let exprsF = f.exprs else {
            return XCTFail("parse failed: \(script)")
        }
        XCTAssertEqual(e.plugins.count, 0, "e expected 0 plugins (x is discrete), got \(e.plugins.count)")
        XCTAssertEqual(f.plugins.count, 0, "f expected 0 plugins (q unknown), got \(f.plugins.count)")

        e.setNameNums([("x", 5), ("y", 0.7)], .fire)
        XCTAssertEqual(exprsE["x", .tween], 5, "e.x tween expected instant 5, got \(String(describing: exprsE["x", .tween]))")
        XCTAssertEqual(exprsE["y", .tween], 0.7, "e.y tween expected instant 0.7, got \(String(describing: exprsE["y", .tween]))")
        f.setNameNums([("y", 0.3)], .fire)
        XCTAssertEqual(exprsF["y", .tween], 0.3, "f.y tween expected instant 0.3, got \(String(describing: exprsF["y", .tween]))")
    }

    /// T10: the plato.flo.h phase declaration, verbatim: only zoom z is plugged
    func testPlatoPhaseDeclaration() {
        let root = Flo("√")
        let script = sky + """
         plato { phase ('x tetra-cube-octa-dodec-icosa, y subdivisions, z zoom',
                        xyz, x 0…10=1, y 0…6=0, z 0…1=0,
                        svg "icon.plato.phase",
                        ^- sky.main.anim(z)) }
        """
        guard floParse.parseRoot(root, script),
              let phase = root.findPath("plato.phase"),
              let exprs = phase.exprs else {
            return XCTFail("parse failed: \(script)")
        }
        XCTAssertEqual(phase.plugins.count, 1, "phase expected 1 plugin, got \(phase.plugins.count)")
        let names = phase.plugins.first?.floScalars.map { $0.name } ?? []
        XCTAssertEqual(names, ["z"], "capture set expected [z], got \(names)")

        phase.setNameNums([("x", 7), ("y", 3), ("z", 0.5)], .fire)
        XCTAssertEqual(exprs["x", .tween], 7, "phase x tween expected instant 7, got \(String(describing: exprs["x", .tween]))")
        XCTAssertEqual(exprs["y", .tween], 3, "phase y tween expected instant 3, got \(String(describing: exprs["y", .tween]))")
        XCTAssertEqual(phase.val("z"), 0.5, "phase z value expected 0.5, got \(String(describing: phase.val("z")))")
        XCTAssertEqual(exprs["z", .tween], 0, "phase z tween expected prior 0, got \(String(describing: exprs["z", .tween]))")

        driveFrames(2.6)
        let endTween = exprs["z", .tween] ?? -1
        XCTAssert(abs(endTween - 0.5) < 0.01,
                  "settled phase z tween expected 0.5, got \(endTween)")
    }

    /// T11: a scoped plugin edge scripts back with its scope
    func testMappedPluginScripts() {
        let root = Flo("√")
        let script = sky + " d(x 0…1, z 0…1, ^- sky.main.anim(z))"
        guard floParse.parseRoot(root, script),
              let d = root.findPath("d") else {
            return XCTFail("parse failed: \(script)")
        }
        _ = d
        let out = root.scriptRoot([.def, .edge, .parens, .noLF])
        let packed = out.replacingOccurrences(of: " ", with: "")
        XCTAssert(packed.contains("^-sky.main.anim(z)"),
                  "script expected to keep the scope, got \(out)")
    }

    /// T12: anim.x is the duration in seconds; a runtime change applies to the next arm
    func testDurationFromAnim() {
        let root = Flo("√")
        let script = sky + " d(z 0…1, ^- sky.main.anim(z))"
        guard floParse.parseRoot(root, script),
              let anim = root.findPath("sky.main.anim"),
              let d = root.findPath("d"),
              let exprs = d.exprs else {
            return XCTFail("parse failed: \(script)")
        }
        XCTAssertEqual(d.plugins.first?.duration, 2, "duration expected 2 from anim.x, got \(String(describing: d.plugins.first?.duration))")

        anim.setNameNums([("x", 0.5)], .fire)
        XCTAssertEqual(d.plugins.first?.duration, 0.5, "duration expected 0.5 after anim.x edit, got \(String(describing: d.plugins.first?.duration))")

        d.setNameNums([("z", 0.8)], .fire)
        driveFrames(0.2)
        let midTween = exprs["z", .tween] ?? -1
        XCTAssert(midTween > 0 && midTween < 0.8,
                  "mid-flight z tween expected between 0 and 0.8, got \(midTween)")
        driveFrames(0.5) // 0.7s total, past the 0.5s duration
        let endTween = exprs["z", .tween] ?? -1
        XCTAssert(abs(endTween - 0.8) < 0.01,
                  "settled z tween expected 0.8 by 0.7s, got \(endTween)")
    }

    /// T13: anim.x of zero snaps the plugged tween to its value; no frames needed
    func testZeroDurationSnaps() {
        let root = Flo("√")
        let script = "sky { main { anim(x 0…10=0) } } d(z 0…1, ^- sky.main.anim(z))"
        guard floParse.parseRoot(root, script),
              let d = root.findPath("d"),
              let exprs = d.exprs else {
            return XCTFail("parse failed: \(script)")
        }
        XCTAssertEqual(d.plugins.count, 1, "d expected 1 plugin, got \(d.plugins.count)")
        d.setNameNums([("z", 0.8)], .fire)
        XCTAssertEqual(exprs["z", .tween], 0.8, "zero duration expected instant tween 0.8, got \(String(describing: exprs["z", .tween]))")
    }

    /// T14: the earlier `(z: x)` form still parses and scopes to z
    func testColonFormStillScopes() {
        let root = Flo("√")
        let script = sky + " d(x 0…1, z 0…1, ^- sky.main.anim(z: x))"
        guard floParse.parseRoot(root, script),
              let d = root.findPath("d") else {
            return XCTFail("parse failed: \(script)")
        }
        let names = d.plugins.first?.floScalars.map { $0.name } ?? []
        XCTAssertEqual(names, ["z"], "capture set expected [z], got \(names)")
    }
}
#endif
