sky {
    main {
        run(x : 1)
        anim(x : 0.5)
    }
    network {
        bonjour follow(x : 1)
        midi(x : 1)
    }
    color {
        pal0 pal1 xfade(x : 0.5)
    }
    input {
        azimuth(x : 0, y : 0)
        accel(x : 0, y : 0, z : 0)
        radius(x : 9)
        tilt(x : 1)
        force(x : 0)
    }
    draw {
        screen.fill(x : 0)
        brush {
            size(x : 10)
            press(x : 1)
            index(x : 127)
        }
        line {
            prev(x : 0, y : 0)
            next(x : 0, y : 0)
        }
        dot {
            on(x : 0, y : 0, z : 0)
            off(x : 0, y : 0, z : 0)
        }
    }
    pov(x : 0, y : 0.8, z : 0, time)
}
