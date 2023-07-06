model.canvas.tile {
    repeat (x -1…1~0, y -1…1~0)
    <> shader.render˚repeat ^ sky.main.anim
    >> (midi.cc.skypad.repeatX(val x)
        midi.cc.skypad.repeatY(val y))
}
midi {
    input.controller >> cc˚.
    cc.skypad.repeatX (cc == 14, val 0_127) <> model.canvas.tile.repeat(x val)

}
shader {
    compute.tile.repeat  (x -1…1~0, y -1…1~0)
    render.flatmap.repeat(x -1…1~0, y -1…1~0)
}

🎚14 = 127
🎚14 ⫸ 127 output.controller: (input.controller:3856
                               skypad.repeatX:3935
                               output.controller:4302)

􁒖 x:-1086 canvas.tile.repeat(val/twe: 0.98/0.71)(input.controller:3856
                                                  skypad.repeatX:3935
                                                  output.controller:4302)

􁒖 y:-1087 canvas.tile.repeat(val/twe: 0.84/0.84)(input.controller:3856
                                                  skypad.repeatX:3935
                                                  output.controller:4302)

🎚14 = 127
🎚14 ⫸ 127 output.controller: (input.controller:3856
                               skypad.repeatX:3935
                               output.controller:4302)

􁒖 x:-1086 canvas.tile.repeat(val/twe: 0.98/0.71)(input.controller:3856
                                                  skypad.repeatX:3935
                                                  output.controller:4302)

􁒖 y:-1087 canvas.tile.repeat(val/twe: 0.84/0.84)(input.controller:3856
                                                  skypad.repeatX:3935
                                                  output.controller:4302)

🎚14 ⫸ 64 output.controller: (tile.repeat:1084
                              skypad.repeatX:3935
                              output.controller:4302)
