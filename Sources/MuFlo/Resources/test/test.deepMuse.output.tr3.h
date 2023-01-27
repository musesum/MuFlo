sky { // visual music program

    main { // main controls

        frame (0) // frame counter
        fps (1…60=60) // frames per second
        run (1) // currently running
    }
    pipeline { // default metal pipeline at atartup

        draw ("draw") // drawing layer
        ave ("compute") // compute layer
        color ("color") // colorizing layer
        render ("render") // render layer al
    }
    color { // false color mapping palette

        pal0 ("roygbik") // palette 0: (r)ed (o)range (y)ellow …
        pal1 ("wKZ") // palette 1: (w)hite blac(K) fractali(Z)e
        xfade (0…1=0.5)
    }
    input { // phone and tablet pencil input
        azimuth (x -0.2…0.2, y -0.2…0.2) // pen tilt
        accel (x -0.3…0.3, y -0.3…0.3, z -0.3…0.3) { // accelerometer
            on (0…1)
        }
        radius (1…92=9) // finger silhouette
        tilt (0…1) // use tilt
        force (0…0.5) >> sky.draw.brush.size // pen pressure
    }
    draw { // draw on metal layer

        screen { // fill 32 bit universe

            fill (0) // all zeros 0x00000000
        }
        brush { // type of brush and range

            type ("dot") // draw a circle
            size (1…64=10) // range of radius
            press (0…1=1) // pressure changes size
            index (1…255=127) // index in 256 color palette
                                // <<(osc.tuio.z osc.manos˚z) // redirect from OSC
        }
        line { // place holder for line drawing

            prev (x 0…1, y 0…1) // staring point of segment
            next (x 0…1, y 0…1) // endint point of segment
        }
    }
}
shader {
    model {
        cell {
            fade (0…1=0.5) {
                on (0…1=0) >> (shader.model.cell.fade.on(0) , shader.model.cell.ave.on(0) , shader.model.cell.melt.on(0) , shader.model.cell.tunl.on(0) , shader.model.cell.slide.on(0) , shader.model.cell.fred.on(0) , shader.model.cell.zha.on(0) )<< shader.model.cell.fade
            }
            ave (0…1=0.5) {
                on (0…1=1) >> (shader.model.cell.fade.on(0) , shader.model.cell.ave.on(0) , shader.model.cell.melt.on(0) , shader.model.cell.tunl.on(0) , shader.model.cell.slide.on(0) , shader.model.cell.fred.on(0) , shader.model.cell.zha.on(0) )<< shader.model.cell.ave
            }
            melt (0…1=0.5) {
                on (0…1=0) >> (shader.model.cell.fade.on(0) , shader.model.cell.ave.on(0) , shader.model.cell.melt.on(0) , shader.model.cell.tunl.on(0) , shader.model.cell.slide.on(0) , shader.model.cell.fred.on(0) , shader.model.cell.zha.on(0) )<< shader.model.cell.melt
            }
            tunl (0…5=1) {
                on (0…1=0) >> (shader.model.cell.fade.on(0) , shader.model.cell.ave.on(0) , shader.model.cell.melt.on(0) , shader.model.cell.tunl.on(0) , shader.model.cell.slide.on(0) , shader.model.cell.fred.on(0) , shader.model.cell.zha.on(0) )<< shader.model.cell.tunl
            }
            slide (0…7=3) {
                on (0…1=0) >> (shader.model.cell.fade.on(0) , shader.model.cell.ave.on(0) , shader.model.cell.melt.on(0) , shader.model.cell.tunl.on(0) , shader.model.cell.slide.on(0) , shader.model.cell.fred.on(0) , shader.model.cell.zha.on(0) )<< shader.model.cell.slide
            }
            fred (0…4=4) {
                on (0…1=0) >> (shader.model.cell.fade.on(0) , shader.model.cell.ave.on(0) , shader.model.cell.melt.on(0) , shader.model.cell.tunl.on(0) , shader.model.cell.slide.on(0) , shader.model.cell.fred.on(0) , shader.model.cell.zha.on(0) )<< shader.model.cell.fred
            }
            zha (0…6=2) {
                on (0…1=0) >> (shader.model.cell.fade.on(0) , shader.model.cell.ave.on(0) , shader.model.cell.melt.on(0) , shader.model.cell.tunl.on(0) , shader.model.cell.slide.on(0) , shader.model.cell.fred.on(0) , shader.model.cell.zha.on(0) )<< shader.model.cell.zha
                bits (2…4=3)
                loops (11)
            }
        }
        pipe {
            draw (x 0…1=0.5, y 0…1=0.5)
            record (0)
            camera (0) {
                flip (0)
            }
            camix (0)
            color (0…1=0.1) // bitplane
            render {
                frame (x 0, y 0, w 1080, h 1920)
                repeat (x, y)
                mirror (x, y)
            }
        }
    }
    file {
        cell {
            fade ("cell.fader.metal")
            ave ("cell.ave.metal")
            melt ("cell.melt.metal")
            tunl ("cell.tunl.metal")
            slide ("cell.slide.metal")
            fred ("cell.fred.metal")
            zha ("cell.zha.metal")
        }
        pipe {
            record camera ("cell.camera.metal")
            camix ("cell.camix.metal")
            draw ("pipe.draw.metal")
            render ("pipe.render.metal")
            color ("pipe.color.metal")
        }
    }
}
midi { // musical instrument device interface

    input { // midi input

        note { // note on/off from 0 thru 127

            on (num 0…127, velo 0…127, chan 1…32, port 1…16, time 0)
            off (num 0…127, velo 0…127, chan 1…32, port 1…16, time 0)
        }
        controller (num 0…127, val 0…127, chan 1…32, port 1…16, time 0)
        afterTouch (num 0…127, val 0…127, chan 1…32, port 1…16, time 0)
        pitchBend (val 0…16384=8192, chan 1…32, port 1…16, time 0)
        programChange (num 0…255, chan 1…32, port 1…16, time 0) //1, 632, 255
    }
    output @ input {
        note { // note on/off from 0 thru 127

            on (num 0…127, velo 0…127, chan 1…32, port 1…16, time 0)
            off (num 0…127, velo 0…127, chan 1…32, port 1…16, time 0)
        }
        controller (num 0…127, val 0…127, chan 1…32, port 1…16, time 0)
        afterTouch (num 0…127, val 0…127, chan 1…32, port 1…16, time 0)
        pitchBend (val 0…16384=8192, chan 1…32, port 1…16, time 0)
        programChange (num 0…255, chan 1…32, port 1…16, time 0) //1, 632, 255
    }
    cc {
        main {
            modWheel (num == 1, val, chan, time)
            volume (num == 7, val, chan, time)
            balance (num == 8, val, chan, time)
            panPosition (num == 10, val, chan, time)
            expression (num == 11, val, chan, time)
            controller (num in 32…63, val, chan, time) // controller 0…31
            portamento {
                time (num == 5, val, chan, time)
                amount (num == 84, val, chan, time)
            }
        }
        pedal {
            hold (num == 64, val, chan, time)
            porta (num == 65, val, chan, time)
            sosta (num == 66, val, chan, time)
            _soft (num == 67, val, chan, time)
            _legato (num == 68, val, chan, time)
            _hold2 (num == 69, val, chan, time)
        }
        _cc {
            _main2 {
                bankSelect (num == 0, val, chan, time)
                breathCtrl (num == 2, val, chan, time)
                footPedal (num == 4, val, chan, time)
                dataEntry (num == 6, val, chan, time)
                effectControl1 (num == 12, val, chan, time)
                effectControl2 (num == 13, val, chan, time)
            }
            _sound {
                soundVariation (num == 70, val, chan, time)
                resonance (num == 71, val, chan, time)
                soundReleaseTime (num == 72, val, chan, time)
                soundAttackTime (num == 73, val, chan, time)
                frequencyCutoff (num == 74, val, chan, time)
                timbre (num == 71, val, chan, time)
                brightness (num == 74, val, chan, time)
            }
            _button {
                button1 (num == 80, val, chan, time)
                button2 (num == 81, val, chan, time)
                button3 (num == 82, val, chan, time)
                button4 (num == 83, val, chan, time)
                decayor (num == 80, val, chan, time)
                hiPassFilter (num == 81, val, chan, time)
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
                reverbLevel (num == 91, val, chan, time)
                tremoloLevel (num == 92, val, chan, time)
                chorusLevel (num == 93, val, chan, time)
                detuneLevel (num == 94, val, chan, time)
                phaserLevel (num == 95, val, chan, time)
            }
            _parameter {
                dataButtonIncrement (num == 96, val, chan, time)
                dataButtonDecrement (num == 97, val, chan, time)
                nonregisteredParameterLSB (num == 98, val, chan, time)
                nonregisteredParameterMSB (num == 99, val, chan, time)
                registeredParameterLSB (num == 100, val, chan, time)
                registeredParameterMSB (num == 101, val, chan, time)
            }
            _soundControl {
                soundControl6 (num == 75, val, chan, time)
                soundControl7 (num == 76, val, chan, time)
                soundControl8 (num == 77, val, chan, time)
                soundControl9 (num == 78, val, chan, time)
                soundControl10 (num == 79, val, chan, time)
            }
            _undefined {
                undefined_3 (num == 3, val, chan, time)
                undefined_9 (num == 9, val, chan, time)
                undefined_14_31 (num in 14…31, val, chan, time)
                undefined_85_90 (num in 85…90, val, chan, time)
                undefined_102_119 (num in 102…119, val, chan, time)
            }
            _mode {
                allSoundOff (num == 120, val, chan, time)
                allControllersOff (num == 121, val, chan, time)
                localKeyboard (num == 122, val, chan, time)
                allNotesOff (num == 123, val, chan, time)
                monoOperation (num == 126, val, chan, time)
                polyMode (num == 127, val, chan, time)
            }
            _omni {
                omniModeOff (num == 124, val, chan, time)
                omniModeOn (num == 125, val, chan, time)
                omniMode (0…1) << (midi.cc._cc._omni.omniModeOff(0) , midi.cc._cc._omni.omniModeOn(1) )
            }
        }
    }
}
