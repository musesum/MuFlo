//  ParTypes.swift
//  created by musesum on 7/3/17.

import Foundation
import Metal

public typealias CallVoid = (()->())
public typealias CallBool = ((Bool)->())
public typealias CallFloat = ((Float)->())
public typealias CallAny = ((Any)->())
public typealias CallAspect = ((Aspect)->())
public typealias MakeAny = (()->(Any?))
public typealias MakeTexture = (()->(MTLTexture?))
