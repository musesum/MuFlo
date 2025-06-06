| timeNow send rcvd deltaTime    timeLag               timeNext             |
|     0     A    -                                                          |
|     1                                                                     |
|     2     B    A    2                             -> 2+2 = 4              |
|     3     C    B    1      (2.0+1.0)/2  = 1.50    -> 3+1.50 = 4.5         |
|     4          C    1      (1.5+1.0)/2  = 1.25    -> 4+1.25 = 5.25        |
|     5     D    -                                                          |
|     6     E    D    1      (1.25+1)/2   = 1.125   -> 6+1.24 = 7.25        |
|     7          -                                                          |
|     8     F    E    2      (1.125+2)/2  = 1.5625  -> 8+1.5625 = 9.5625    |
|     9     G    F    1      (1.5625+1)/2 = 1.28125 -> 9+1.28125 = 10.28125 |

For the sake of simplicity, we are showing time as integers
whereas `time` is really Date().timeIntervalSince1970
`time` is shared between sender `send` and receiver `rcvd`
each symbol A B C D E F G represent a distinct message
`delta` is rcvd.time - send.time
`timeLag` is is previous timeLag plus delta / 2
`timeNext` time in which to process rcvd message is rcvd.time + timeLag


