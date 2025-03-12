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
        screen {
            fill(0)
        }
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
    touching
}
pipe(on : 1) {
    draw(on : 1) {
        in(tex)
        out(tex, archive)
        shift(buf, x : 0.5, y : 0.5)
    }
    camera(on : 0) {
        out(tex)
        front(buf, x : 0)
    }
    cell(on : 1) {
        fake(tex)
        real(tex)
        out(tex)
        rule(on : 1) {
            slide(on : 1) {
                version(buf, x : 3)
                loops(buf, z : 0)
            }
            zha(on : 0) {
                version(buf, x : 2)
                loops(buf, z : 10)
            }
            ave(on : 0) {
                version(buf, x : 0.5)
                loops(buf, y : 0)
            }
            fade(on : 0) {
                version(buf, x : 1.2)
                loops(buf, y : 0)
            }
            melt(on : 0) {
                version(buf, x : 0.5)
                loops(buf, y : 0)
            }
            tunl(on : 0) {
                version(buf, x : 1)
                loops(buf, y : 0)
            }
            fred(on : 0) {
                version(buf, x : 4)
                loops(buf, y : 0)
            }
        }
    }
    color(on : 1) {
        in(tex)
        out(tex)
        pal(tex, w : 256, h : 1)
        plane(buf, y : 0)
    }
    camix(on : 0) {
        in(tex)
        cam(tex)
        out(tex)
        mix(buf, x : 1)
        frame(buf)
    }
    tile(on : 1) {
        in(tex)
        out(tex)
        repeat(buf, x : 0, y : 0)
        mirror(buf, x : 0, y : 0)
    }
    render(on : 1) {
        in(tex)
        map(on : 1) {
            flat(on : 1)
            cube(on : 1) {
                cudex(tex)
                mix(buf, x : 1)
            }
        }
        plato(on : 1) {
            cube(tex)
            pal(tex)
            range01(buf, x : 0)
            shading(buf)
        }
    }
}
model {
    canvas(columns : 2) {
        color(xy, x : 0, y : 0)
        brush(val, x : 255)
        repeat(xy, x : 0, y : 0)
        mirror(xy, x : 0, y : 0)
        size(val, x : 12)
        press(tog, x : 1)
        tilt(tog, x : 0)
        shift(xy, x : 0.5, y : 0.5)
        fill(val,  : 0)
    }
    plato(columns : 2) {
        show(tog, x : 1)
        cubemap(tog, x : 1)
        material(xyz, x : 0, y : 0, z : 0.75)
        harmonic(val, x : 1)
        phase(val, x : 1)
        convex(val, x : 0.98)
        zoom(val, y : 0)
        _run(tog, x : 1)
        _wire(tog, x : 0)
        _counter
    }
    cell(columns : 2) {
        slide(seg, x : 3)
        zha(seg, x : 2)
        ave(val, x : 0.5)
        fade(val, x : 1)
        melt(val, x : 0.5)
        tunl(seg, x : 1)
        fred(seg, x : 4)
    }
    camera {
        stream(tog, x : 0)
        front(tog, x : 1)
        cubemap(tog, x : 1)
        mix(xy, x : 1, y : 0)
        color(xy, x : 0, y : 0)
    }
    bonjour(peer)
    archive(arch)
    _more {
        fps(val,  : 60)
        anim(val,  : 0.24)
        _snapshot(tog, x : 0)
        _motion(tog, x : 1)
        _rotate(xy, x : 0, y : 0)
        _canvas(tog, x : 0)
        _follow(tog, x : 1)
        _midi(tog, x : 1)
    }
}
menu {
    canvas(svg) {
        color(sym)
        brush(sym)
        repeat(svg)
        mirror(svg)
        size(svg)
        press(sym)
        tilt(sym)
        shift(svg)
        fill(sym)
    }
    plato(svg) {
        show(sym)
        zoom(sym)
        material(svg)
        cubemap(sym)
        harmonic(svg)
        phase(svg)
        convex(svg)
        wire(svg)
        run(svg)
    }
    cell(svg) {
        slide(img)
        zha(img)
        ave(img)
        fade(img)
        melt(img)
        tunl(img)
        fred(img)
    }
    camera(sym) {
        stream(sym)
        front(svg)
        cubemap(sym)
        mask(svg)
        mix(sym)
        color(sym)
    }
    bonjour(sym)
    archive(sym)
    more(svg) {
        fps(img)
        anim(sym)
        _snapshot(sym)
        _motion(sym)
        _rotate(svg)
        _canvas(svg)
        _network(sym) {
            follow(sym)
            midi(sym)
        }
    }
}
midi {
    input {
        note {
            on(num : 0, velo : 0, chan : 1, port : 1, time)
            off(num : 0, velo : 0, chan : 1, port : 1, time)
        }
        afterTouch(num : 0, val : 0, chan : 1, port : 1, time)
        pitchBend(val : 8192, chan : 1, port : 1, time)
        program(num : 0, chan : 1, port : 1, time)
        nrpn(num : 0, val : 0, chan, time)
        controller(cc : 0, val : 0, chan : 1, port : 1, time)
    }
    output {
        note {
            on(num : 0, velo : 0, chan : 1, port : 1, time)
            off(num : 0, velo : 0, chan : 1, port : 1, time)
        }
        afterTouch(num : 0, val : 0, chan : 1, port : 1, time)
        pitchBend(val : 8192, chan : 1, port : 1, time)
        program(num : 0, chan : 1, port : 1, time)
        nrpn(num : 0, val : 0, chan, time)
        controller(cc : 0, val : 0, chan : 1, port : 1, time)
    }
    skypad {
        plane(num == 129, val : 0, chan, time)
        fade(num == 130, val : 0, chan, time)
    }
    cc {
        dispatch skypad {
            zoom(cc == 4, val : 0)
            convex(cc == 5, val : 0)
            colorY(cc == 6, val : 0)
            camix(cc == 9, val : 0)
            fade(cc == 10, val : 0)
            plane(cc == 11, val : 0)
            shiftX(cc == 12, val : 0)
            shiftY(cc == 13, val : 0)
            repeatX(cc == 14, val : 0)
            repeatY(cc == 15, val : 0)
        }
        roli {
            lightpad {
                x(cc == 114, val : 0)
                y(cc == 113, val : 0)
                z(cc == 115, val : 0)
            }
            loopblock {
                mode(cc == 102, val : 0)
                mute(cc == 103, val : 0)
                metro(cc == 104, val : 0)
                skip(cc == 105, val : 0)
                back(cc == 106, val : 0)
                play(cc == 107, val : 0)
                record(cc == 108, val : 0)
                learn(cc == 109, val : 0)
                prev(cc == 110, val : 0)
                next(cc == 111, val : 0)
            }
        }
        main {
            modWheel(num == 1, val, chan, time)
            volume(num == 7, val, chan, time)
            balance(num == 8, val, chan, time)
            panPosition(num == 10, val, chan, time)
            expression(num == 11, val, chan, time)
            controller(num : 32, val, chan, time)
            portamento {
                time(num == 5, val, chan, time)
                amount(num == 84, val, chan, time)
            }
        }
        pedal {
            hold(num == 64, val, chan, time)
            porta(num == 65, val, chan, time)
            sosta(num == 66, val, chan, time)
            _soft(num == 67, val, chan, time)
            _legato(num == 68, val, chan, time)
            _hold2(num == 69, val, chan, time)
        }
        _main2 {
            bankSelect(num == 0, val, chan, time)
            breathCtrl(num == 2, val, chan, time)
            footPedal(num == 4, val, chan, time)
            dataEntry(num == 6, val, chan, time)
            effectCtrl1(num == 12, val, chan, time)
            effectCtrl2(num == 13, val, chan, time)
        }
        _sound {
            soundVariation(num == 70, val, chan, time)
            resonance(num == 71, val, chan, time)
            soundReleaseTime(num == 72, val, chan, time)
            soundAttackTime(num == 73, val, chan, time)
            frequencyCutoff(num == 74, val, chan, time)
            timbre(num == 71, val, chan, time)
            brightness(num == 74, val, chan, time)
        }
        _button {
            button1(num == 80, val, chan, time)
            button2(num == 81, val, chan, time)
            button3(num == 82, val, chan, time)
            button4(num == 83, val, chan, time)
            decayor(num == 80, val, chan, time)
            hiPassFilter(num == 81, val, chan, time)
            generalPurpose82(num == 82, val, chan, time)
            generalPurpose83(num == 83, val, chan, time)
        }
        _roland {
            rolandToneLevel1(num == 80, val, chan, time)
            rolandToneLevel2(num == 81, val, chan, time)
            rolandToneLevel3(num == 82, val, chan, time)
            rolandToneLevel4(num == 83, val, chan, time)
        }
        _level {
            reverbLevel(num == 91, val, chan, time)
            tremoloLevel(num == 92, val, chan, time)
            chorusLevel(num == 93, val, chan, time)
            detuneLevel(num == 94, val, chan, time)
            phaserLevel(num == 95, val, chan, time)
        }
        _parameter {
            dataButtonIncrement(num == 96, val, chan, time)
            dataButtonDecrement(num == 97, val, chan, time)
            nonregisteredParameterLSB(num == 98, val, chan, time)
            nonregisteredParameterMSB(num == 99, val, chan, time)
            registeredParameterLSB(num == 100, val, chan, time)
            registeredParameterMSB(num == 101, val, chan, time)
        }
        _soundControl {
            soundControl6(num == 75, val, chan, time)
            soundControl7(num == 76, val, chan, time)
            soundControl8(num == 77, val, chan, time)
            soundControl9(num == 78, val, chan, time)
            soundControl10(num == 79, val, chan, time)
        }
        _undefined {
            undefined_3(num == 3, val, chan, time)
            undefined_9(num == 9, val, chan, time)
            undefined_14_31(num : 14, val, chan, time)
            undefined_85_90(num : 85, val, chan, time)
            undefined_102_119(num : 102, val, chan, time)
        }
        _mode {
            allSoundOff(num == 120, val, chan, time)
            allControllersOff(num == 121, val, chan, time)
            localKeyboard(num == 122, val, chan, time)
            allNotesOff(num == 123, val, chan, time)
            monoOperation(num == 126, val, chan, time)
            polyMode(num == 127, val, chan, time)
        }
        _omni {
            omniModeOff(num == 124, val, chan, time)
            omniModeOn(num == 125, val, chan, time)
            omniMode(0)
        }
    }
    draw {
        dot {
            on(x, y, z)
            off(x, y, z)
        }
    }
}
