// revised by musesum on 1/3/25

import Foundation

enum ParType: String {

    case def   // name of rule
    case or    // first subParser is true
    case and   // all subParsers must be true
    case regx  // regular 'expression'
    case quote // quoted "string"
}
