
a: 1 ( b:2, c:3, d: b+c << e ) e @ a

a(1) (b(2) c(3) d(b+c)<<e)

a: b: 1     🚫     <=  a.b: 1
a (b: 1)            =>  a.b: 1
a(b c).d            =>  a(b:d, c:d)
a(b c).(d e)        =>  a( b ( d e ) c (d e))
a(b c).(1)          =>  a(b:1, c:1)
a(1).b(2)           => a:1 (b:2)

a(1).b(2).c(3)      =>  a:1 (b:2 (c:3))
=>  a 1 ( b 2 (c 3)) 🚫

a(b c).(d e).(1)   =>  a ( b ( d(1) e(1) ) c ( d(1) e(1) ) ) 🚫
=>  a ( b ( d:1, e:1 ), c ( d:1, e:1 ) )
a(x:y) << b(x:c, y:d)
a(x+y) << b(x:c, y:d)
a(s:x+y) << b(x:c, y:d)
a.s:x+y, a<< b(x:c, y:d)


a(0…2~0=1)

a(x(1) y(2))
a(x:1, y:2)

a(0…1~0=1)

b(x/2) a<<b(x/2)

m(1, 2, 3), n>>m(4, 5, 6)

a(b,2,3

  a(0…1~0=1)
  a(0…1~0)

  cell.one(1).two(2).three(3)

  a(0…1~0=1)

  b(0…1)

  c(0…1=1)

  a(1) b >> a(2)

  a("b")

  a.b c@a
  a (b) c@a (b)

  b(x/2) a << b(x/2)

  a b << a(* 10)

  a (x=1, y=2)

  m (1, 2, 3), n >> m(4, 5, 6)

  a ( b c ) a.*( d )

  a (b c) a.*(d(0…1) >> a˚on(0))
  a (b (d(0…1) >> a˚on(0))
     c (d(0…1) >> a˚on(0)))

  a (b c) a˚.( d(0…1) >> a˚.on(0))
  a (b(d(0…1) >> a˚.on(0))
     c(d(0…1) >> a˚.on(0)))

  i(0…1~0.5, 0…1~0.5, 0…1~0.5)

  a (b(c(1))) a.b.c(2)
  a (b(c(1))) z@a (b(c(2)))        [.parens]
  a (b(c:1))  z@a (b(c:2))         [.colons]

  a (b(c:1)) a.b.c(2)
  a (b(c(1))) z@a (b(c(2)))       [.parens]
  a (b(c:1))  z@a (b(c:2))        [.colons]

  a.b.c(0…1) z@a b.c(0…1~1)
  a   (b.c:0…1  )                [.compact, .colon]
  z@a (b.c:0…1~1)

  a   ( b ( c(0…1  ) ) )
  z@a ( b ( c(0…1~1) ) )

  a (b c).(d e).(f g).(h i) z >> a.b˚g.   [.expand]
  a (b(d(f(h i) g(h i)) e(f(h i) g(h i)))
     c(d(f(h i) g(h i)) e(f(h i) g(h i))))
  z >> (a.b.d.g.h, a.b.e.g.h)

  a (b(d(f(h i) g(h,i)) e(f(h,i) g(h,i)))  [.def, .comma]
     c(d(f(h i) g(h,i)) e(f(h,i) g(h,i))))
  z >> a.b˚g

  a (b c).(d e f>>b(1) ) z@a z.b.f⟡→c(1)
  a    ( b ( d e f>>a.b(1) ) c ( d e f>>a.b(1) ) )
  z@a  ( b ( d e f⟡→z.c(1) ) c ( d e f>>z.b(1) )

        a._c   ( d ( e ( f ("ff") ) ) ) a.c.z @ _c ( d ( e.f   ("ZZ") ) )
        a ( _c ( d ( e ( f ("ff") ) ) ) c ( z @ _c ( d ( e ( f ("ZZ") ) ) ) ) )

        a.b ( _c ( d e.f(0…1) g) z @ _c ( g ) )
        a ( b ( _c ( d e ( f(0…1) ) g ) z @ _c ( d e ( f(0…1) ) g ) ) )

        a.b._c (d(1)) a.b.e@_c
        a ( b ( _c ( d(1) ) e@_c ( d(1) ) ) )

        a b >> a(1)

        a << (b c)

        a.b ( c d ) a.e@a.b ( f g )
        a ( b ( c d ) e@a.b ( c d f g ) )

        a ( b c ) d@a ( e f ) g@d ( h i ) j@g ( k l )
        a ( b c ) d@a ( b c e f ) g@d ( b c e f h i ) j@g ( b c e f h i k l )

        a ( b c ) h@a ( i j )
        a ( b c ) h@a ( b c i j )

        a ( b c ) \n h@a ( i j )
        a ( b c ) h@a ( b c i j )
        )))

body {left right}
    .{shoulder.elbow.wrist
        {thumb index middle ring pinky}
            .{meta prox dist }
        hip.knee.ankle.toes}
˚˚ <> .. // nervous system
˚˚ {pos(x 0…1, y 0…1, z 0…1)
    angle(roll %360, pitch %360, yaw %360)
    mm(0…3000)})


model.canvas
 (cube
  (motion (tog, 0…1~1)
   rotate (vxy, x: -1…1~0, y: -1…1~0)
   back   (tog, 0…1~1)
   show   (tog, 0…1~0) <> shader.render.cubemap.on
   )
  )
_menu.canvas
 (cube ("cube.sf")
  (motion ("gyroscope.sf")
   rotate ("icon.direction.svg")
   back   ("cube.sf")
   show   ("cube.fill.sf")
   )
  )

model
 (
  canvas
  (
   tile
   (
    mirror (vxy, x: 0…1~0, y: 0…1~0)
    <> shader.render˚mirror
    ^ sky.main.anim

    repeat (vxy, x: -1…1~0, y: -1…1~0)
    <> shader.render˚repeat
    ^ sky.main.anim

    shift (vxy, x: 0…1~0.5, y: 0…1~0.5)
    <> shader.compute.draw
    ^ sky.main.anim
    )
   color
   (
    fade (val, 0…1~0.5) <> sky.color.xfade ^ sky.main.anim
    plane (val, 0…1~0.1) <> shader.compute.color ^ sky.main.anim
    fill_0 (tap, 0…1) <> sky.draw.screen.fill(0)
    fill_1 (tap, 0…1) <> sky.draw.screen.fill(1)
    )
   speed
   (
    fps  (seg, 0…60~60 ) <> sky.main.fps
    run  (tog, 0…1~1   ) <> sky.main.run
    anim (val, 0…1~0.24) <> sky.main.anim
    )
   )
  brush
  (
   size  (val, 0…1~0.5)   <> sky.draw.brush.size
   press (tog, 0…1~1  )   <> sky.draw.brush.press
   tilt  (tog, 0…1~0)     <> sky.input.tilt
   index (seg, 1…255~127) <> sky.draw.brush.index
   )
  cell
  (
   fade  (val, 1.61…3~1.61) <> shader.cell.fade
   ave   (val, 0…1~0.5    ) <> shader.cell.ave
   melt  (val, 0…1~0.5    ) <> shader.cell.melt
   tunl  (seg, 0…5~1      ) <> shader.cell.tunl
   zha   (seg, 0…6~2      ) <> shader.cell.zha
   slide (seg, 0…7~3      ) <> shader.cell.slide
   fred  (seg, 0…4~4      ) <> shader.cell.fred
   )
  camera
  (
   stream (tog, 0…1~0  ) <> shader.compute.camera.on
   facing (tog, 0…1~1  ) <> shader.compute.camera.flip
   mask   (tog, 0…1~1  )
   mix    (val, 0…1~0.5) <> shader.compute.camix.mix
   )
  network
  (
   bonjour (peer, "bonjour") <> sky.main.peer.bonjour
   follow  (tog, 0…1~1) <> sky.main.peer.follow
   midi    (tog, 0…1~1) <> sky.main.peer.midi
   )
  )
_menu.canvas ("icon.canvas.svg")
(
 tile ("icon.tile.svg")
 (
  mirror ("icon.mirror.svg")
  repeat ("icon.repeat.arrows.svg")
  shift  ("icon.direction.svg")
  )
 color("icon.pal.main.png")
 (
  fade   ("icon.gradient.svg")
  plane  ("icon.layers.svg")
  fill_0 ("drop.sf")
  fill_1 ("drop.fill.sf")
  )
 speed ("icon.speed.png")
 (
  fps  ("speedometer.sf")
  run  ("goforward.sf")
  anim ("bolt.fill.sf")
  )
 brush ("icon.brush.svg")
 (
  size  ("icon.size.dot.svg")
  press ("scribble.variable.sf")
  tilt  ("angle.sf")
  index ("calendar.day.timeline.left.sf")
  )
 cell ("icon.ca.grid.svg")
 (
  fade  ("icon.cell.fade.png" )
  ave   ("icon.cell.ave.png"  )
  melt  ("icon.cell.melt.png" )
  tunl  ("icon.cell.tunl.png" )
  zha   ("icon.cell.zha.png"  )
  slide ("icon.cell.slide.png")
  fred  ("icon.cell.fred.png" )
  )
 camera ("camera.sf")
 (
  stream ("video.sf")
  facing ("icon.camera.facing.svg")
  mask   ("icon.face.svg")
  mix    ("camera.filters.sf")
  )
 network ("network.sf")
 (
  bonjour ("bonjour.sf")
  follow  ("shared.with.you.sf")
  midi    ("pianokeys.inverse.sf")
  )

 model.canvas.plato
 (
  shade
  (
   phase  (vxy, x: 0…1, y: 0.9…1.1)
   convex (var, 0.9…1.1~1) ^ sky.main.anim
   colors (vxy, x: 0…255~0, y: 0…1~0)
   shadow (vxy, x: 0…1~0, y: 0…1~0)
   invert (val, 0…1~1)
   )
  zoom  (val, 0…1~1) ^ sky.main.anim
  wire  (tog, 0…1~0)
  morph (tog, 0…1~1)
  show  (tog, 0…1~0) <> shader.render.plato.on
  )
 _menu.canvas.plato("icon.plato.wire.svg")
 (
  shade ("icon.peacock.svg")
  (
   phase  ("calendar.day.timeline.left.sf")
   convex ("icon.convex.svg")
   colors ("figure.stair.stepper.sf")
   shadow ("shadow.sf")
   invert ("circle.lefthalf.filled.sf")
   )
  zoom  ("icon.zoom.svg")
  morph ("icon.counter.svg")
  wire  ("icon.wireframe.svg")
  show  ("icon.plato.show.svg")
  )

 midi.cc.skypad
 (
  zoom    (cc ≈  4, val 0_127~0, chan, time).val <> model.canvas.plato.zoom
  convex  (cc ≈  5, val 0_127~0, chan, time).val <> model.canvas.plato.shade.convex
  colorY  (cc ≈  6, val 0_127~0, chan, time).val <> model.canvas.plato.shade.colors.y
  camix   (cc ≈  9, val 0_127~0, chan, time).val <> model.camera.mix
  fade    (cc ≈ 10, val 0_127~0, chan, time).val <> model.canvas.color.fade
  plane   (cc ≈ 11, val 0_127~0, chan, time).val <> model.canvas.color.plane
  shift.x (cc ≈ 12, val 0_127~0, chan, time).val <> model.canvas.tile.shift.x
  shift.y (cc ≈ 13, val 0_127~0, chan, time).val <> model.canvas.tile.shift.y
  repeat.x(cc ≈ 14, val 0_127~0, chan, time).val <> model.canvas.tile.repeat.x
  repeat.y(cc ≈ 15, val 0_127~0, chan, time).val <> model.canvas.tile.repeat.y
  )
 sky 'visual music synth'
 (
  main 'main controls'
  (
   fps   : 1…60~60 'frames per second'
   run  : 0…1~1   'currently running'
   anim : 0…1~0.9 'animation transition speed'
   )
  network
  (
   bonjour         'bonjour status'
   (
    follow : 0…1~1  'follow remote events'
    midi   : 0…1~1  'follow midi events'
    )
   color 'false color mapping palette'
   (pal0:"roygbik", pal1:"wKZ", xfade: 0…1~0.5)
   input 'phone and tablet pencil input'
   (
    azimuth  (x: -0.2…0.2, y: -0.2…0.2)  >> shader.compute.draw
    accel    (x: -0.3…0.3, y: -0.3…0.3, z: -0.3…0.3)  'accelerometer'
    accel.on : 0…1~1
    radius   : 1…92~9     'finger silhouette'
    tilt     : 0…1~1
    force    : 0…0.5  >> draw.brush.size
    )
   draw                   'draw on metal layer'
   (
    screen.fill : 0…1~0   'fill cellular automata universe'
    brush                 'type of brush and range'
    (
     size  : 1…64~10     'range of radius'
     press : 0…1~1       'pressure changes size'
     index : 1…255~127   'index in 256 color palette'
     )
    line                  'place holder for line drawing'
    (
     prev (x: 0…1, y: 0…1) 'staring point of segment
     next (x: 0…1, y: 0…1) 'endint point of segment
     )
    dot
    (
     on (x, y, z)
     off (x, y, z)
     )
    )
   )
  shader
  (
   pipeline(draw, slide, color, flatmap)
   cell
   (
    fade  (1.62…3~1.62, on: 0…1~0 >> cell˚on(0) << .. )
    ave   (0…1~0.5    , on: 0…1~1 >> cell˚on(0) << .. )
    melt  (0…1~0.5    , on: 0…1~0 >> cell˚on(0) << .. )
    tunl  (0…5~1      , on: 0…1~0 >> cell˚on(0) << .. )
    slide (0…7~3      , on: 0…1~0 >> cell˚on(0) << .. )
    fred  (0…4~4      , on: 0…1~0 >> cell˚on(0) << .. )
    zha   (0…6~2      , on: 0…1~0 >> cell˚on(0) << .. , bit: 2…4~3, loops: 11)
    )
   compute
   (
    draw (x: 0…1~0.5, y: 0…1~0.5, on: 0…1~1)
    record (on: 0…1~0)
    camera (on: 0…1~0, flip: 0)
    camix  (mix: 0…1~0.5)
    color (0…1~0.1)
    tile
    (
     repeat(x: -1…1~0, y: -1…1~0)
     mirror(x: 0…1~0, y: 0…1~0)
     )
    )
   render
   (
    flatmap
    (
     frame(x: 0, y: 0, w: 1080, h: 1920)
     repeat(x: -1…1~0, y: -1…1~0)
     mirror(x:  0…1~0, y:  0…1~0)
     )
    cubemap
    (
     frame(x: 0, y: 0, w: 1080, h: 1920)
     repeat(x: -1…1~0, y: -1…1~0)
     mirror(x: 0…1~0, y: 0…1~0)
     gravity(0…2~0)
     on(0…1~0)
     )
    plato
    ( on(0…1~0) )
    )
   )

  body(left right)
  .(shoulder.elbow.wrist
    (thumb index middle ring pinky)
    .(meta prox dist)
    hip.knee.ankle.toes)
  ˚˚ (joint(x, y, z) )

  skeleton
  (left
   (shoulder
    (elbow
     (wrist
      (thumb
       (meta.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        prox.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        dist.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
       index
       (meta.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        prox.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        dist.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
       middle
       (meta.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        prox.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        dist.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
       ring
       (meta.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        prox.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        dist.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
       pinky
       (meta.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        prox.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        dist.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
       bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
      bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
     bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
    hip
    (knee
     (ankle
      (toes.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
       bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
      bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
     bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
    bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
    )
   right
   (shoulder
    (elbow
     (wrist
      (thumb
       (meta.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        prox.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        dist.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
       index
       (meta.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        prox.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        dist.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
       middle
       (meta.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        prox.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        dist.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
       ring
       (meta.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        prox.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        dist.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
       pinky
       (meta.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        prox.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        dist.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
        bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
       bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
      bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
     bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
     )
    hip
    (knee
     (ankle
      (toes.bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
       bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
      bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
     bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
    bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000))
   bone (x: 0…1, y: 0…1, z: 0…1, roll: %360, pitch: %360, yaw: %360, mm: 0…1000)
   )
  ˚˚ <> ..
