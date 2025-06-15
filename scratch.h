Here is a link to the WWDC25 talk: https://developer.apple.com/videos/play/wwdc2025/301
```
sky ('synthesizer') {
    main ('main controls') {
        run (x 0…1=1 : 0.2 ,'run shader')
        anim(x 0…1=0.5 : 0.1 ,'animation transition speed')
    }
}
```

here is a verbal description:
```
sky comment 'synthesizer'
sky.main comment 'main controls'
sky.main.run range 0 to 1 default 1 current value is 0.2 comment 'run shader’
sky.main.anim range 0 to 1 default 0.5 current value is 0.1 comment 'animation transition speed'
```
The model may call a Tool to get the current range and value like so
`currentValue("sky.main.run") -> (MinVal, MaxVal, NowVal) // returns (0, 1, 0.2)
