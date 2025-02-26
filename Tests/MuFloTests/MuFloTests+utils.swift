// created by musesum on 2/11/25

import Foundation
@testable import MuFlo
extension MuFloTests {

    func headline(_ title: String) {
        //let titled = title.titleCase()
        print("\n━━━━━━━━━━━━━━━━━━━━━━ \(title) ━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    func subhead(_ title: String) {
        //let titled = title.titleCase()
        print("━━━━━━━━━━━ \(title) ━━━━━━━━━━━")
    }

    func read(_ filename: String) -> String? {
        let url = Bundle.module.url(forResource: filename, withExtension: "flo.h")
        if let path = url?.path {
            do { return try String(contentsOfFile: path) } catch {}
        }
        PrintLog("⁉️ \(#function) cannot find:\(filename)")
        return nil
    }
    func parse(_ name: String,_ root: Flo) -> Int {
        if let script = read(name),
           floParse.parseRoot(root, script) {
            print (name +  " ✓")
            return 0
        } else {
            print(name + " ⁉️ parse failed")
            return 1
        }
    }
    /** Test script produces expected output
     - parameter script: test script
     - parameter expected: exected output after parse
     */
    func test(_ script: String,
              _ expected: String? = nil,
              _ scriptOps: FloScriptOps = FloScriptOps.All) -> Int {

        var err = 0

        print("\n# " + script)
        let root = Flo("√")
        let expected = expected ?? script

        if floParse.parseRoot(root, script) {
            let actual = root.scriptRoot(scriptOps)
            err = Parsin.testCompare(expected, actual)
        } else  {
            print(" ⁉️ failed parse")
            err += 1  // error found
        }
        return err
    }

    func testFile(_ input: String,
                  out: String,
                  _ ops: FloScriptOps) -> Int {

        if let inScript = read(input) {
            let outScript = read(out) ?? inScript
            let root = Flo("√")

            if floParse.parseRoot(root, inScript) {
                print (name +  " ✓")
                let actual = root.scriptRoot(ops)
                let err = Parsin.testCompare(outScript, actual)
                return err
            }
        }
        return 1 // error
    }

} 
