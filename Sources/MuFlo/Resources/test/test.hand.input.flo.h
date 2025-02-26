hand {left right}.{
    thumb  {      knuc base inter tip }
    index  { meta knuc base inter tip }
    middle { meta knuc base inter tip }
    ring   { meta knuc base inter tip }
    little { meta knuc base inter tip }
    wrist
    forearm
}
hand˚.(x -0.3…0.3, y 0.8…1.2, z -0.5…0.01, time, phase, joint)
touch (x -0.3…0.3, y 0.8…1.2, z -0.5…0.01, time, phase, joint, <- hand˚middle.tip)
