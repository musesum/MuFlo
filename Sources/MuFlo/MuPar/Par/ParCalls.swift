//  ParTypes.swift
//  created by musesum on 7/3/17.

import Foundation

public typealias CallVoid = (()->())
public typealias CallBool = ((Bool)->())
public typealias CallFloat = ((Float)->())
public typealias CallAny = ((Any)->())
public typealias MakeAny = (()->(Any?))

#if !os(watchOS)
import Metal
public typealias CallAspect = ((Aspect)->())
public typealias MakeTexture = (()->(MTLTexture?))
#endif
