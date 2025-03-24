sky ('visual music synth') {
    main ('main controls') {
        run (x 0…1~1,'currently running')
        anim(x 0…1~0.5,'animation transition speed')
    }
    network {
        bonjour('bonjour status')
        follow (x 0…1~1,'follow remote events')
        midi   (x 0…1~1,'follow midi events')
    }
    color ('false color mapping palette') {
        pal0 ("roygbik", 'red orange yellow green blue indigo black')
        pal1 ("wKZ", 'white & blacK with capital K meaning both sides, Z means with Zeno fractal')
        xfade (x 0…1~0.5, 'cross fade btween pal0 and pal1')
    }
    input ('phone and tablet pencil input') {
        azimuth (x -0.2…0.2, y -0.2…0.2, -> pipe.draw.shift)
        accel   (x -0.3…0.3, y -0.3…0.3, z -0.3…0.3,'accelerometer')
        radius  (x 1…92~9,'for iPhone, finger silhouette changes brush size')
        tilt    (x 0…1~1, 'for iPad pen, allow tilt to shift screen')
        force   (x 0…0.5, -> draw.brush.size, 'iPad pen, pressure with change brush size')
    }
    draw ('draw on metal layer') {
        screen.fill(x 0…1~0,'fill cellular automata universe')
        brush ('type of brush and range') {
            size  (x 1…64~10:10,'range of radius')
            press (x 0…1~1,'pressure changes size')
            index (x 1…255~127,'index in 256 color palette')
        }
        line ('place holder for line drawing') {
            prev (x 0…1, y 0…1,'staring point of segment')
            next (x 0…1, y 0…1,'endint point of segment')
        }
        dot {
            on  (x 0_11, y 0_11, z 0_127)
            off (x 0_11, y 0_11, z 0_127)
        }
    }
    pov (x -0.3…0.3, y 0.8…1.2, z -0.5…0.01, time, 'point of view')
}
pipe (on 1) {

    draw (on 1) {
        in (tex, <- cell.out)
        out (tex, archive, 'archive: save snapshot of drawing surface')
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
            *(-> *(on 0), 'solo only one rule')
            ˚version(-> ..(on 1),'changing `version` auto switches rule')
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
                mixcube (buf, x 0…1 : 1, ^- sky.main.anim)
            }
        }
        plato (on 1) {
            cube (tex, <- map.cube.cudex)
            pal  (tex, <- color.pal)
            range01 (buf, x 0…1)
            shading (buf)
        }
    }
}
plato ('platonic solids',
       columns 2,
       svg "icon.plato.icosa") {

    show ('show / hide the platonic object',
          tog, x 1,
          sym "eye",
          <> pipe.render.plato(on : x)) {

        material ('gradient xy and transparencey z',
                  xyz, x 0…1~0, y 0…1~0,z 0…1~0.75,
                  svg "icon.opacity",
                  ^- sky.main.anim)
    }
    harmonic ('number of face triangle subdivisions',
              seg, x 0_6,
              svg "icon.subtriangle")

    phase ('phase between tetra, cube, octa, dodec, icosa',
           seg, x 0_10 : 1,
           svg "icon.plato.phase")

    convex ('inward / outward of subdivided triangles',
            val, x 0.9…1.1 : 0.98,
            svg "icon.convex")

    zoom ('zoom into and around platonic object',
          val, y 0…1~0,
          sym "square.arrowtriangle.4.outward",d
          ^- sky.main.anim)

    cubemap ('show cubemap or flat screen (ignored on AVP',
             tog, x 0_1 : 1,
             sym "cube",
             <> pipe.render.map.cube.mixcube)

    _run ( 'run the platonic transformation',
          tog, x 0_1 : 1,
          svg "icon.counter")

    _wire ( 'show wireframe',
           tog, x 0_1 : 0,
           svg "icon.wireframe")

    _counter('absolute counter',
             svg "icon.counter")
}

