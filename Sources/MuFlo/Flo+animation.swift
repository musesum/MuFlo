//  Created by warren on 1/24/23.


import Foundation

extension Flo { // + animation

    func setAnimation(_ fromFlo: Flo) {
        guard let val else { return }
        val.valOps += .anim
        switch val {
            case let v as FloValScalar: v.setAnimation(fromFlo)
            case let v as FloValExprs:     v.setAnimation(fromFlo)
            default: break
        }
    }
}
extension FloValScalar {

    func setAnimation(_ fromFlo: Flo) {

        switch fromFlo.val {

            case let from as FloValScalar:

                setAnim(from.now)

            case let from as FloValExprs:

                for fromAny in from.nameAny.values {

                    if let fromScalar = fromAny as? FloValScalar {

                        setAnim(fromScalar.now)
                        return // use only the first scalar it sees
                    }
                }

            default: break
        }
    }
}

extension FloValExprs {

    func setAnimation(_ fromFlo: Flo) {

        switch fromFlo.val {

            case let fromScalar as FloValScalar:

                for (destName,any) in nameAny {

                    if let destScalar = any as? FloValScalar {

                        destScalar.setAnim(fromScalar.now)
                    }
                }
            case let fromExprs as FloValExprs:

                for (fromName,fromAny) in fromExprs.nameAny {

                    if let destScalar = nameAny[fromName] as? FloValScalar,
                       let fromScalar = fromAny as? FloValScalar {

                        destScalar.setAnim(fromScalar.now)
                    }
                }
            default: break
        }
    }
}
