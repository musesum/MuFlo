import UIKit
import MuPar
import MuVisit

public class FloArchive: NSObject {

    static let logSnapshot = false

    public let root˚ = Flo.root˚
    private var touchRepeat˚: Flo?

    public var archive: MuArchive?
    private var fromSnapshot = true

    private var archiveName: String
    private var archiveDate = TimeInterval(0)

    private var scriptNames: [String]
    public var textureData = [String: Data?]()

    private var bundleNameDates = [String: TimeInterval]()
    private var documentNameDates = [String: TimeInterval]()
    private var bundle: Bundle

    public init(bundle: Bundle,
                archive: String,
                scripts: [String],
                textures: [String]) {

        self.bundle = bundle
        self.archiveName = archive
        self.scriptNames = scripts
        for texture in textures {
            textureData[texture] = nil
        }
        super.init()

        // parse Sky Snapshot scripts
        let fname = archiveName + ".zip"
        if let archive = MuArchive.readArchive(fname) {

            archiveDate = MuFile.shared.documentDate(archiveName)
            print(String(format: "Documents/\(fname) %.2f Δ 0", archiveDate))
            getFloBundleChanges()
            getDocumentChanges()

            if bundleHasChanged() {
                parseBundleScriptFiles()
            } else {
                parseSnapshot(archive)
            }
        } else {
            parseBundleScriptFiles()
        }

        /// get list of script file dates inside `library` directory -- updated by Xcode
        func getFloBundleChanges() {

            for name in scriptNames {
                if let floPath = bundle.path(forResource: name, ofType: ".flo.h") {
                    let date = MuFile.shared.pathDate(floPath)
                    if date > 0 {
                        bundleNameDates[name] = date
                        print(String(format: "Bundle/%@ %.2f Δ %.f", name, date, date - archiveDate))
                    }
                }
            }
        }
        /// get list of script file dates inside `documents` directory -- updated manually by user
        func getDocumentChanges() {
            for name in scriptNames {
                let date = MuFile.shared.documentDate(name + ".flo.h")
                if date > 0 {
                    bundleNameDates[name] = date
                    print(String(format: "Documents/%@ %.2f Δ %.f", name, date, date - archiveDate))
                }
            }
        }

        /// Merge changes to flo script that user manually copied to documents directory.
        /// Only works once, as new snapshot will have a later date
        func mergeUserDocumentChanges() {
            for (name, date) in documentNameDates {
                if date > archiveDate {
                    _ = mergeFlo(root˚, name)
                }
            }
        }
        func mergeFlo(_ root: Flo,
                      _ fname: String,
                      _ ext: String = "flo.h") -> Bool {

            guard let script = read(fname, ext) ?? read(fname, ext) else {
                return false
            }
            return mergeScript(root, script)
        }
        func mergeScript(_ root: Flo,
                                       _ script: String) -> Bool {

            let mergeFlo = Flo("√")
            let success = FloParse().parseScript(mergeFlo, script)
            if success {
                mergeNow(mergeFlo, with: root)
            }
            return success
        }
        func mergeNow(_ mergeFlo: Flo, with root: Flo) {
            if let dispatch = root.dispatch?.dispatch,
               let (flo,_) = dispatch[mergeFlo.hash],
               let mergeExprs = mergeFlo.exprs,
               let floExprs = flo.exprs {

                _ = floExprs.setFromAny(mergeExprs, Visitor(0))
            }
        }


        /// Developer made changes to .flo files and redeployed via XCode
        func bundleHasChanged() -> Bool {
            for date in bundleNameDates.values {
                if date > archiveDate {
                    return true
                }
            }
            return false
        }

        func parseSnapshot(_ archive: MuArchive) {
            self.archive = archive
            let fname = archiveName + ".full.flo.h"
            archive.get(fname, 1000000) { data in
                if let data {
                    parseFloData(data) {
                        mergeUserDocumentChanges()
                        // getRuntimeChanges()
                        getTextureData()
                    }
                }
                else {
                    self.parseBundleScriptFiles()
                    getTextureData()
                }
            }

            func getRuntimeChanges() {
                let fname = archiveName + ".now.flo.h"
                archive.get(fname, 1_000_000) { data in
                    if let data {

                        if FloArchive.logSnapshot {
                            
                            let before = self.root˚.scriptFlo([.parens, .def, .edge])
                            parseFloData(data, merge: true) {
                                let after = self.root˚.scriptFlo([.parens, .def, .edge])
                                _ = ParStr.testCompare(before, after)
                            }
                        } else {

                            parseFloData(data, merge: true)
                        }

                    }
                }
            }
            func getTextureData () {
                for name in textureData.keys {
                    let fname = name + ".txt"
                    archive.get(fname, 1_000_000) { data in
                        self.textureData[name] = data
                    }
                }
// ???               archive.get("Snapshot.tex", 30_000_000) { data in
//                    if let data {
//                        print("--- archive.get Snapshot.tex \(data.count)")
//                         TextureData.shared.data = data
//                    }
//                }
            }

            func parseFloData(_ data: Data, merge: Bool = false, finished: CallVoid? = nil) {
                if let script = self.dropRoot(String(data: data, encoding: .utf8)) {
                    if merge {
                        _ = FloParse.shared.mergeScript(self.root˚, script)
                    } else {
                        _ =  FloParse.shared.parseScript(self.root˚, script)
                    }
                }
                finished?()
            }
        }
    }



    /// remove ove leading "√ { \n" from script file if it exists
    func dropRoot(_ script: String?) -> String? {
        if let script = script {
            var hasRoot = false
            var index = 0
            scan: for char in script {
                switch char {
                    case "√": hasRoot = true; index += 1
                    case " ", "\n", "\t": index += 1
                    case "{": if hasRoot { index += 1 }
                    default: break scan
                }
            }
            if hasRoot {
                let start = String.Index(utf16Offset: index, in: script)
                let end = String.Index(utf16Offset: script.count, in: script)
                let sub = script[start ..< end]
                return String(sub)
            }
        }
        return script
    }

    func parseArchive(_ archive: MuArchive) {
        // get script and parse
        let fname = archiveName + ".flo"
        archive.get(fname, 1_000_000) { data in
            if  let data,
                let script = self.dropRoot(String(data: data, encoding: .utf8)) {

                print(script)
                let _ = FloParse.shared.parseScript(self.root˚, script)
            }
        }
    }
    /// New install or user manually removed snapshot file
    func parseBundleScriptFiles() {
        for scriptName in scriptNames {
            _ = parseFlo(root˚, scriptName)
        }
        //let script = root.scriptRoot()
        //print("\n\n" + script + "\n\n")
    }
    func parseFlo(_ root: Flo,
                  _ fname: String,
                  _ ext: String = "flo.h") -> Bool {

        guard let script = read(fname, ext) ?? read(fname, ext) else {
            return false
        }
        let success = FloParse().parseScript(root, script)
        print(fname + (success ? " ✓" : " ⁉️ parse failed"))
        return success
    }
    func read(_ fname: String,
              _ ext: String) -> String? {

        guard let path = bundle.path(forResource: fname, ofType: ext)  else {
            print("⁉️ FloBundle:: couldn't find file: \(fname).\(ext)")
            return nil
        }
        do {
            return try String(contentsOfFile: path) }
        catch {
            print("⁉️ filename:: error:\(error) loading contents of:\(path)")
        }
        return nil
    }

}
