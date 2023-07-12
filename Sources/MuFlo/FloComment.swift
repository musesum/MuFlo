//
//  FloComment.swift
//  
//
//  Created by warren on 11/27/20.
//

import Foundation
import MuPar

public enum FloCommentType { case unknown, child, edges }

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
    var haveType = Set<FloCommentType>()

    public func copy() -> FloComments {
        let copy = FloComments()
        for comment in comments {
            copy.comments.append(comment.copy())
        }
        copy.haveType = haveType
        return copy
    }


    public func addComment(_ flo: Flo, _ parItem: ParItem, _ prior: String) {
        if parItem.node?.pattern == "comment",
           let value = parItem.nextPars.first?.value {

            func insertComment(_ type: FloCommentType, _ index: Int ) {
                let floComment = FloComment(type, flo.name, value, index)
                haveType.insert(type)
                comments.append(floComment)
            }
            switch prior {
                case "child": insertComment(.child, flo.children.count)
                case "edges": insertComment(.edges, flo.edgeDefs.edgeDefs.count)
                default:      insertComment(.unknown, 0)
            }
        }
    }

    public func mergeComments(_ flo: Flo, _ merge: Flo) {

        //??? flo.comments.comments.append(contentsOf: merge.comments.comments) // TODO really  merge both
        flo.comments.haveType = flo.comments.haveType.union(merge.comments.haveType)

        var nameIndex = [String: Int]()
        var index = 0
        for child in flo.children {
            index += 1
            nameIndex[child.name] = index
        }
        for comment in comments {
            if comment.type == .child {
                comment.index = nameIndex[comment.name] ?? 0
            }
        }
    }

    public func have(type: FloCommentType) -> Bool {
        return haveType.contains(type)
    }

    public func getComments(_ getType: FloCommentType,
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
