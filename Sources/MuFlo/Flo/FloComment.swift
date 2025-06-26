//  created by musesum on 11/27/20.

import Foundation

public enum FloCommentType { case unknown, branch, edge }

public class FloComment {
    let type: FloCommentType
    let name: String
    let text: String
    var index: Int

    init(_ type: FloCommentType, _ name: String, _ text: String, _ index: Int) {
        self.type  = type
        self.name  = name
        self.text  = text
        self.index = index
    }
    func copy() -> FloComment {
        return FloComment(type, name, text, index)
    }
}
public class FloComments {

    var comments = [FloComment]()
    var hasType = Set<FloCommentType>()

    public func copy() -> FloComments {
        let copy = FloComments()
        for comment in comments {
            copy.comments.append(comment.copy())
        }
        copy.hasType = hasType
        return copy
    }

    public func mergeComments(_ flo: Flo, _ merge: Flo) {

        flo.comments.hasType = flo.comments.hasType.union(merge.comments.hasType)

        var nameIndex = [String: Int]()
        var index = 0
        for child in flo.children {
            index += 1
            nameIndex[child.name] = index
        }
        for comment in comments {
            if comment.type == .branch {
                comment.index = nameIndex[comment.name] ?? 0
            }
        }
    }

    public func have(type: FloCommentType) -> Bool {
        return hasType.contains(type)
    }

    public func scriptComments(_ getType: FloCommentType,
                            _ scriptOpts: FloScriptOps) -> String {
        var result = ""
        if scriptOpts.comment, have(type: getType) {
            for comment in comments {
                if comment.type == getType {
                    switch comment.text.prefix(1) {
                        case ",": result += ","
                        default: result.spacePlus(comment.text)
                    }
                }
            }
        }
        return result
    }
}
