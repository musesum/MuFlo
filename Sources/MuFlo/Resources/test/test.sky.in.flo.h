sky { // visual music synth
    main { // main controls
        run (x 0…1~1) // currently running
        anim(x 0…1~0.5) // animation transition speed
    }
    network {
        bonjour // bonjour status
        follow (x 0…1~1) // follow remote events
        midi   (x 0…1~1)   // follow midi events
    }
    color { // false color mapping palette
        pal0 ("roygbik") 
        pal1 ("wKZ")
        xfade (x 0…1~0.5)
    }
    input { // phone and tablet pencil input
        azimuth (x -0.2…0.2, y -0.2…0.2, -> pipe.draw.shift)
        accel   (x -0.3…0.3, y -0.3…0.3, z -0.3…0.3)  // accelerometer
        radius  (x 1…92~9) // finger silhouette
        tilt    (x 0…1~1)
        force   (x 0…0.5, -> draw.brush.size)
    }
    draw { // draw on metal layer
        screen.fill(0…1~0) // fill cellular automata universe
        brush { // type of brush and range
            size  (x 1…64~10)   // range of radius
            press (x 0…1~1)     // pressure changes size
            index (x 1…255~127) // index in 256 color palette
        }
        line { // place holder for line drawing
            prev (x 0…1, y 0…1) // starting point of segment
            next (x 0…1, y 0…1) // ending point of segment
        }
        dot {
            on  (x 0_11, y 0_11, z 0_127)
            off (x 0_11, y 0_11, z 0_127)
        }
    }
    pov (x -0.3…0.3, y 0.8…1.2, z -0.5…0.01, time)
    touching (<- model.hand˚middle.tip)
}
pipe (on 1) {

    draw (on 1) {
        in (tex, <- cell.out)
        out (tex, archive)  // archive: save snapshot of drawing surface
        shift (buf, x 0…1~0.5,  y 0…1~0.5)
    }
    camera (on 0) {
        out (tex)
        front (buf, x 0)
    }
    cell (on 1) {
        fake (tex, <- draw.out)
        real (tex, <- (draw.out, camera.out))
        out (tex)
        rule (on 1) {
            slide(on 1) { version (buf, x 0…7 : 3)   loops (buf, z 0) }
            zha  (on 0) { version (buf, x 0…6 : 2)   loops (buf, z 10) }
            ave  (on 0) { version (buf, x 0…1 : 0.5) loops (buf, y 0…99~0) }
            fade (on 0) { version (buf, x 1…3 : 1.2) loops (buf, y 0…32~0) }
            melt (on 0) { version (buf, x 0…1 : 0.5) loops (buf, y 0…32~0) }
            tunl (on 0) { version (buf, x 0…5 : 1)   loops (buf, y 0…32~0) }
            fred (on 0) { version (buf, x 0…4 : 4)   loops (buf, y 0…32~0) }
            *(-> *(on 0)) // solo only one rule
            ˚version(-> ..(on 1)) // changing `version` auto switches rule
        }
    }
    color (on 1) {
        in (tex, <- (camera.out, cell.out))
        out (tex)
        pal (tex, w 256, h 1)
        plane (buf, y 0…1)
    }
    camix (on 0, <- camera) {
        in  (tex, <- color.out)
        cam (tex, <- camera.out)
        out (tex)
        mixcam (buf, x 0…1~1)
        frame(buf)
    }
    tile (on 1) {
        in (tex, <- (color.out, camix.out))
        out (tex)
        repeat (buf, x -1…1~0, y -1…1~0)
        mirror (buf, x  0…1~0, y  0…1~0)
    }
    render (on 1) {
        in (tex, <- tile.out)
        map (on 1)  {
            flat(on 1)
            cube(on 1) {
                cudex (tex)
                mixcube (buf, x 0…1 : 1)
            }
            *(-> *(on 0)) // solo flat or cube
        }
        plato (on 1) {
            cube (tex, <- map.cube.cudex)
            pal  (tex, <- color.pal)
            range01 (buf, x 0…1)
            shading (buf)
        }
    }
}
model {
    canvas (columns 2) {

        color (xy, x 0…1, y 0…1,
               <> (pipe.color.plane, sky.color.xfade),
               ^- sky.main.anim)

        brush (val, x 1_255~255,
               <> sky.draw.brush.index)

        repeat (xy, x -1…1~0, y -1…1~0,
                <> pipe˚.repeat,
                -> (midi.cc.skypad.repeatX(val x),
                    midi.cc.skypad.repeatY(val y)),
                ^- sky.main.anim)

        mirror (xy, x 0…1~0, y 0…1~0,
                <> pipe˚.mirror,
                ^- sky.main.anim)

        size  (val, x 1_64~12, <> (sky.draw.brush.size, press(0)))
        press (tog, x 1, <> sky.draw.brush.press)
        tilt  (tog, x 0, <> sky.input.tilt)

        shift (xy, x 0…1~0.5, y 0…1~0.5,
               <> pipe.draw.shift,
               ^- sky.main.anim)

        fill  (val, 0…1, <> sky.draw.screen.fill)
    }

    plato (columns 2) {
        show     (tog, x 1, <> pipe.render.plato(on x))
        cubemap  (tog, x 1, <> pipe.render.map.cube.mixcube)
        material (xyz, x 0…1~0, y 0…1~0,z 0…1~0.75, ^- sky.main.anim)

        harmonic (val, x 0_6 : 1)
        phase    (val, x 0_10 : 1)
        convex   (val, x 0.9…1.1 : 0.98)
        zoom     (val, y 0…1~0, ^- sky.main.anim)
        _run     (tog, x 1)
        _wire    (tog, x 0)
        _counter
    }
    cell (columns 2) {
        slide (seg, x 0_7~3,   <> pipe.cell˚slide.version)
        zha   (seg, x 0_6~2,   <> pipe.cell˚zha.version)
        ave   (val, x 0…1~0.5, <> pipe.cell˚ave.version)
        fade  (val, x 0.2…2~1, <> pipe.cell˚fade.version)
        melt  (val, x 0…1~0.5, <> pipe.cell˚melt.version)
        tunl  (seg, x 0_5~1,   <> pipe.cell˚tunl.version)
        fred  (seg, x 0_4~4,   <> pipe.cell˚fred.version)
    }
    camera {
        stream  (tog, x 0, <> (pipe.camera(on x), cubemap(x 0)))
        front   (tog, x 1, <> pipe.camera.front)
        cubemap (tog, x 1, <> pipe.render.map.cube.mixcube)
        mix     (xy,  x 1, y 0…1~0,
                 <> (pipe.camix.mixcam,
                     pipe.cell.rule˚loops(y)))

        color (xy, x 0…1~0, y 0…1~0, <> canvas.color)
    }
    bonjour (peer "bonjour", <> sky.network.bonjour)
    archive (arch)
    _more {
        fps (val, 0_60~60,  <> sky.main.fps)
        anim(val, 0…1~0.24, <> sky.main.anim)

        _snapshot(tog, x 0)
        _motion  (tog, x 1)
        _rotate  (xy,  x -1…1~0, y -1…1~0, <> pipe.render.cubemap.rotate)
        _canvas  (tog, x 0)
        _follow  (tog, x 1, <> sky.network.follow)
        _midi    (tog, x 1, <> sky.network.midi)
    }
}
menu {
    canvas     (svg "icon.canvas") {
        color  (sym "paintpalette")
        brush  (sym "paintbrush.pointed")
        repeat (svg "icon.repeat.arrows")
        mirror (svg "icon.mirror")
        size   (svg "icon.size.dot")
        press  (sym "scribble.variable")
        tilt   (sym "angle")
        shift  (svg "icon.direction")
        fill   (sym "drop")
    }
    plato (svg "icon.plato.icosa") {
        show     (sym "eye")
        zoom     (sym "square.arrowtriangle.4.outward")
        material (svg "icon.opacity")
        cubemap  (sym "cube")
        harmonic (svg "icon.subtriangle")
        phase    (svg "icon.plato.phase")
        convex   (svg "icon.convex")
        wire     (svg "icon.wireframe")
        run      (svg "icon.counter")
    }
    cell (svg "icon.cellular.automata") {
        slide (img "icon.cell.slide")
        zha   (img "icon.cell.zha"  )
        ave   (img "icon.cell.ave"  )
        fade  (img "icon.cell.fade" )
        melt  (img "icon.cell.melt" )
        tunl  (img "icon.cell.tunl" )
        fred  (img "icon.cell.fred" )
    }
    camera (sym "camera") {
        stream (sym "video")
        front  (svg "icon.camera.facing")
        cubemap(sym "cube")
        mask   (svg "icon.face")
        mix    (sym "camera.filters")
        color  (sym "paintpalette")
    }
    bonjour (sym "bonjour")
    archive (sym "building.columns")
    more (svg "icon.more") {
        fps  (img "icon.speed")
        anim (sym "bolt.fill")
        _snapshot(sym "camera.shutter.button")
        _motion (sym "gyroscope")
        _rotate (svg "icon.rotate")
        _canvas (svg "icon.canvas")
        _network (sym "bonjour") {
            follow (sym "app.connected.to.app.below.fill")
            midi   (sym "pianokeys.inverse")
        }
    }
}
midi { // musical instrument device interface
    input { // midi input
        note { // note on/off from 0 thru 127
            on  (num 0_127, velo 0_127, chan 1_32, port 1_16, time)
            off (num 0_127, velo 0_127, chan 1_32, port 1_16, time)
        }
        afterTouch (num 0_127, val 0_127, chan 1_32, port 1_16, time)
        pitchBend (val 0_16384~8192, chan 1_32, port 1_16, time)
        program (num 0_255, chan 1_32, port 1_16, time)
        nrpn (num 0_16383, val 0…1, chan, time, -> skypad˚.)
        controller (cc 0_127, val 0_127, chan 1_32, port 1_16, time, -> cc.dispatch)
    }
    output : input { controller(<- cc.dispatch)  }

    skypad {
        plane(num == 129, val 0…1, chan, time, <> model.canvas.color.fade(x = val))
        fade (num == 130, val 0…1, chan, time, <> model.canvas.color.fade(y = val))
    }
    cc {
        dispatch (<> (skypad˚., roli.lightpad˚.))
        skypad {
            zoom    (cc ==  4, val 0_127, <> model.plato.zoom)
            convex  (cc ==  5, val 0_127, <> model.plato.shade.convex)
            colorY  (cc ==  6, val 0_127, <> model.plato.shade.colors(y = val))
            camix   (cc ==  9, val 0_127, <> model.camera.mix(val))
            fade    (cc == 10, val 0_127, <> model.canvas.color.fade(x = val))
            plane   (cc == 11, val 0_127, <> model.canvas.color.fade(y = val))
            shiftX  (cc == 12, val 0_127, <> model.canvas.tile.shift(x = val))
            shiftY  (cc == 13, val 0_127, <> model.canvas.tile.shift(y = val))
            repeatX (cc == 14, val 0_127, <> model.canvas.tile.repeat(x = val))
            repeatY (cc == 15, val 0_127, <> model.canvas.tile.repeat(y = val))
            // skypad˚. >> output.note.on(num val)
        }
        roli {
            lightpad {
                x (cc == 114, val 0_127) //, <> sky.draw.dot.on(x val))
                y (cc == 113, val 0_127) //, <> sky.draw.dot.on(y val))
                z (cc == 115, val 0_127) //, <> (sky.draw.dot.on(z val))
                                         //    sky.color.xfade(x val))
            }
            loopblock {
                mode   (cc == 102, val 0_127)
                mute   (cc == 103, val 0_127)
                metro  (cc == 104, val 0_127)
                skip   (cc == 105, val 0_127)
                back   (cc == 106, val 0_127)
                play   (cc == 107, val 0_127)
                record (cc == 108, val 0_127)
                learn  (cc == 109, val 0_127)
                prev   (cc == 110, val 0_127)
                next   (cc == 111, val 0_127)
            }
        }
        main {
            modWheel    (num ==  1, val, chan, time)
            volume      (num ==  7, val, chan, time)
            balance     (num ==  8, val, chan, time)
            panPosition (num == 10, val, chan, time)
            expression  (num == 11, val, chan, time)
            controller  (num in 32_63, val, chan, time)
            portamento {
                time   (num ==  5, val, chan, time)
                amount (num == 84, val, chan, time)
            }
        }
        pedal {
            hold    (num == 64, val, chan, time)
            porta   (num == 65, val, chan, time)
            sosta   (num == 66, val, chan, time)
            _soft   (num == 67, val, chan, time)
            _legato (num == 68, val, chan, time)
            _hold2  (num == 69, val, chan, time)
        }

        _main2 {
            bankSelect  (num == 0, val, chan, time)
            breathCtrl  (num == 2, val, chan, time)
            footPedal   (num == 4, val, chan, time)
            dataEntry   (num == 6, val, chan, time)
            effectCtrl1 (num == 12, val, chan, time)
            effectCtrl2 (num == 13, val, chan, time)
        }
        _sound {
            soundVariation  (num == 70, val, chan, time)
            resonance       (num == 71, val, chan, time)
            soundReleaseTime(num == 72, val, chan, time)
            soundAttackTime (num == 73, val, chan, time)
            frequencyCutoff (num == 74, val, chan, time)

            timbre          (num == 71, val, chan, time)
            brightness      (num == 74, val, chan, time)
        }
        _button {
            button1 (num == 80, val, chan, time)
            button2 (num == 81, val, chan, time)
            button3 (num == 82, val, chan, time)
            button4 (num == 83, val, chan, time)

            decayor          (num == 80, val, chan, time)
            hiPassFilter     (num == 81, val, chan, time)
            generalPurpose82 (num == 82, val, chan, time)
            generalPurpose83 (num == 83, val, chan, time)
        }
        _roland {
            rolandToneLevel1 (num == 80, val, chan, time)
            rolandToneLevel2 (num == 81, val, chan, time)
            rolandToneLevel3 (num == 82, val, chan, time)
            rolandToneLevel4 (num == 83, val, chan, time)
        }
        _level {
            reverbLevel  (num == 91, val, chan, time)
            tremoloLevel (num == 92, val, chan, time)
            chorusLevel  (num == 93, val, chan, time)
            detuneLevel  (num == 94, val, chan, time)
            phaserLevel  (num == 95, val, chan, time)
        }
        _parameter {
            dataButtonIncrement       (num ==  96, val, chan, time)
            dataButtonDecrement       (num ==  97, val, chan, time)
            nonregisteredParameterLSB (num ==  98, val, chan, time)
            nonregisteredParameterMSB (num ==  99, val, chan, time)
            registeredParameterLSB    (num == 100, val, chan, time)
            registeredParameterMSB    (num == 101, val, chan, time)
        }
        _soundControl {
            soundControl6  (num == 75, val, chan, time)
            soundControl7  (num == 76, val, chan, time)
            soundControl8  (num == 77, val, chan, time)
            soundControl9  (num == 78, val, chan, time)
            soundControl10 (num == 79, val, chan, time)
        }
        _undefined {
            undefined_3       (num == 3,       val, chan, time)
            undefined_9       (num == 9,       val, chan, time)
            undefined_14_31   (num in 14_31,   val, chan, time)
            undefined_85_90   (num in 85_90,   val, chan, time)
            undefined_102_119 (num in 102_119, val, chan, time)
        }
        _mode {
            allSoundOff       (num == 120, val, chan, time)
            allControllersOff (num == 121, val, chan, time)
            localKeyboard     (num == 122, val, chan, time)
            allNotesOff       (num == 123, val, chan, time)
            monoOperation     (num == 126, val, chan, time)
            polyMode          (num == 127, val, chan, time)
        }
        _omni {
            omniModeOff       (num == 124, val, chan, time)
            omniModeOn        (num == 125, val, chan, time)
            omniMode(0_1, <- (omniModeOff(0), omniModeOn(1)))
        }
    }
    draw {
        dot.on (x num % 12, y num / 12, z velo, -> sky.draw.dot.on)
        dot.off(x num % 12, y num / 12, z velo, -> sky.draw.dot.off)
        input.note.on (-> draw.dot.on)
        input.note.off(-> draw.dot.off)
    }
}

