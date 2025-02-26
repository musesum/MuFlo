import UIKit

/// Archives are Zip files with extension ".mu"
///
/// Each MU archive usually contains the file entries:
///
///     - full.flo.h // flo script snapshot
///     - icon.png // displayed in picker
///     - pipe.draw.png // cellular automata texture
///
///     // there may be other entries, in the future
///
/// Use Cases that load an archive
///
///     1) User downlads App and onboads for first time
///     2) User exits and restart app
///     3) User selects a MU archive
///         a) from App's Archive Picker
///         b) from a message or email
///         c) from a bonjour session -- unimplementd
///     4) User manually changes Snapshot.mu on Mac
///     5) Xcode developer changes a script and runs
///
/// Code details:
///
/// 1 - `SkyBase` inits `ArchiveFlo` with files from Bundle.
/// When user exits, a Snapshot.mu archive is created and saved
/// in the Documents directory.
///
/// 2 - `SkyBase` inits `ArchiveFlo` and finds that the date for
/// `Snapshot.mu` file is newer than the bundle.
///
/// 3 - `SkyApp` handles a `.onOpenURL`, which loads from URL.
/// Since the app is already running, each flo.exprs is merged
/// with exisiting runtime flo graph. This is accomplished via
/// the dictionary hashFloTime, which addresses each Flo node.
///
///     Note - The runtime graph will NOT add new nodes from MU archive.
///     This is important for devices which have different capabilities --
///     such as the VisionPro, which doesn't support camera feed. Also,
///     maybe be a safety feature where some graphs may mask unwanted nodes.
///
/// 4 - User manually edits script by
///
///     - plugging iPhone into Mac via cable
///     - in finder reveal the "Deep Muse" app's `files`,
///     - copies `Snapshot.mu` file to Mac
///     - double-click to expand the file in a directory
///     - edit the `full.flo.h` script directly
///
///     - compress directory back to a `Snapshot.zip`,
///     - rename extension to `Snapshot.mu`,
///     - copies back to iPhone, `Deep Muse` directory
///     - and overwrite to old snapshot
///
/// Note - optionally, to save a unique patch, replace last 4 steps with
///
///     - rename the "Snapshot" directory to something like "Hello World"
///     - compress the directory to `Hello World.zip`
///     - rename the extention to `Hello World.mu`
///     - copy the new `.mu` file to iPhone
///     - new archive will appear in Archive picker
///
/// 5 - XCode developers may want to iterate with script changes and debug
/// via Mac. So, files in the Bundle that are newer than exposed `.flo` Script files,
/// in the Documents directory, and newer than the `Snapshot.mu` archive will
/// load exclusively from the App Bundle. So, redoing the onboarding of 1)
///
open class ArchiveFlo: NSObject {

    private var scriptNames: [String]
    private var textureNames: [String]
    private var bundles: [Bundle]
    private let Files = FileManager.default

    public var nameTex = [String: MTLTexture?]()
    //... public let root˚ = Flo.root˚

    public init(_ bundles      : [Bundle],
                _ snapName     : String,
                _ scriptNames  : [String],
                _ textureNames : [String]) {

        self.bundles = bundles
        self.scriptNames = scriptNames
        self.textureNames = textureNames
        //TODO: get textureNames from pipe.flo
        for textureName in textureNames {
            nameTex[textureName] = nil as MTLTexture?
        }
        super.init()

        if !parseSnapshot(snapName) {
            parseAppStartupScripts()
        } else {
            //DebugLog { P("√ {\n \(self.root˚.scriptFull) }\n") }
        }
    }

    /// called via AppSky::
    public func readUrl(_ url: URL, local: Bool) {

        if  let zip = ArchiveZip(url, accessMode: .read) {
            readZip(zip) // from email
        } else if url.startAccessingSecurityScopedResource(),
                  let zip = ArchiveZip(url, accessMode: .read) {
            readZip(zip) // from Files directorys, such as downloads
        } else {
            PrintLog("⁉️ ArchiveFlo::readUrl could not read \(url.path())")
        }

        func readZip(_ zip: ArchiveZip) {
            if let data = zip.readFile("full.flo.h"),
               let script = dropRoot(String(data: data, encoding: .utf8)) {

                let mergeRoot = Flo("√")
                if FloParse.shared.parseRoot(mergeRoot, script) {
                    Flo.root˚.mergeFloValues(mergeRoot)
                }
            } else {
                parseAppStartupScripts()
            }
            unzipPngTextures(zip)

            // remove file from Inbox -- but not from downloads
            if url.path.contains("/Inbox") {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    /// get list of script file dates inside `library` directory -- updated by Xcode
    func getApplicationTime() -> TimeInterval {
        var newestTime = TimeInterval(0)
        for name in scriptNames {
            for bundle in bundles {
                if let floPath = bundle.path(forResource: name, ofType: ".flo.h") {

                    let floTime = Files.pathDate(floPath)
                    if floTime > newestTime {
                        newestTime = floTime
                    }
                    continue
                }
            }
        }
        return newestTime
    }

    /// via app reading archive called "Snapshot.mu" which was autosaved
    func parseSnapshot(_ snapName: String) -> Bool {

        if let archive = ArchiveZip(snapName, "mu", .read),
           archive.archiveTime > getApplicationTime() {

            if let data = archive.readFile("full.flo.h"),
               let script = dropRoot(String(data: data, encoding: .utf8)) {

                if FloParse.shared.parseRoot(Flo.root˚, script) {
                    Flo.root˚.activateAllValues() //...
                }
            } else {
                parseAppStartupScripts()
            }
            unzipPngTextures(archive)
            return true

        } else {
            return false
        }
    }

    func unzipPngTextures (_ zip: ArchiveZip?) {

        guard let zip else { return }

        for name in nameTex.keys {

            if let data = zip.readFile(name + ".png"),
               let tex = pngDataToTexture(data) {
                tex.label = name
                self.nameTex[name] = tex
            }
        }
    }

    /// remove ove leading "√ { \n" from script file if it exists
    func dropRoot(_ script: String?) -> String? {

        if let script = script {
            var hasRoot = false
            var index = 0
        scan:
            for char in script {
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

    /// New install or user manually removed snapshot file
    func parseAppStartupScripts() {
        for scriptName in scriptNames {
            _ = parseFlo(Flo.root˚, scriptName)
        }
    }

    func parseFlo(_ root: Flo,
                  _ fname: String,
                  _ ext: String = "flo.h") -> Bool {

        guard let script = read(fname, ext) ?? read(fname, ext) else { return false }
        let success = FloParse().parseRoot(root, script)
        PrintLog(fname + (success ? " ✓" : " ⁉️ parse failed"))
        return success
    }

    func read(_ fname: String,
              _ ext: String) -> String? {

        for bundle in bundles {
            if let path = bundle.path(forResource: fname, ofType: ext) {
                do {
                    return try String(contentsOfFile: path)
                } catch {
                    PrintLog("⁉️ filename:: error:\(error) loading contents of:\(path)")
                }
            }
        }
        return nil
    }
}
public protocol ArchiveProto {

    func readUserArchive(_ url: URL, local: Bool)

    func saveArchive (_ title: String,
                      _ description: String,
                      _ completion: @escaping CallVoid)
}
