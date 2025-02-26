model {
    canvas (columns 2) {

        color (xy, x 0…1, y 0…1,
               -> (pipe.color.plane, sky.color.xfade),
               ^- sky.main.anim)

        brush (val,  x 1_255~255,
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
        press (tap, x %2=1,    <> sky.draw.brush.press)
        tilt  (tog, x %2=0,    <> sky.input.tilt)

        shift (xy, x 0…1~0.5, y 0…1~0.5,
               <> pipe.draw.shift,
               ^- sky.main.anim)

        fill  (val, 0…1, <> sky.draw.screen.fill)
    }

    plato (columns 2) {
        show     (tog, x %2=1, <> pipe.render.plato(on x))
        cubemap  (tog, x %2=1, <> pipe.render.map˚mix)
        material (xyz, x 0…1~0, y 0…1~0,z 0…1~0.75, ^- sky.main.anim)

        harmonic (val, x 0_6=1)
        phase    (val, x 0_10=1)
        convex   (val, x 0.9…1.1=0.98)
        zoom     (val, x 0…1~0, ^- sky.main.anim)
        _run     (tog, x x%2=1)
        _wire    (tog, x x%2=0)
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
        stream  (tog, x %2=0, -> (pipe.camera(on x), cubemap(x 0)))
        front   (tog, x %2=1, <> pipe.camera.front)
        cubemap (tog, x %2=1, <> pipe.render.map˚mix)
        mix     (xy,  x 0…1~1, y 0…1~0, -> (pipe.camix.mix,
                                            pipe.cell.rule˚loops(y)))
        color (xy, x 0…1~0, y 0…1~0, <> canvas.color)
    }
    bonjour (peer "bonjour", <> sky.network.bonjour)
    archive (arch)
    _more {
        fps (val, 0_60~60,  <> sky.main.fps)
        anim(val, 0…1~0.24, <> sky.main.anim)

        _snapshot(tog, x %2~0)
        _motion  (tog, x %2~1)
        _rotate  (xy,  x -1…1~0, y -1…1~0, <> pipe.render.cubemap.rotate)
        _canvas  (tog, x %2~0)
        _follow  (tog, x %2~1, <> sky.network.follow)
        _midi    (tog, x %2~1, <> sky.network.midi)
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
        _shadow   (sym "shadow")
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
