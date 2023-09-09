//  ParTypes.swift
//
//  Created by warren on 7/3/17.
//  Copyright © 2017 DeepMuse 
//  License: Apache 2.0 - see License file

import Foundation

public typealias MatchStr = (_ str: Substring) -> String?
public typealias CallVoid = (()->())
public typealias CallBool = ((Bool)->())
public typealias CallFloat = ((Float)->())
public typealias CallAny = ((Any)->())
