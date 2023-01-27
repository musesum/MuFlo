//
//  FloDefs.swift
//
//  Created by warren on 3/12/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation
import MuPar

// Flo
public typealias FloVisitor = ((Flo, Visitor)->())
public typealias FloPriorParItem = ((Flo, String, ParItem, Int)->(Flo))
