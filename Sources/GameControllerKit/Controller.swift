//
//  Controller.swift
//
//  Created by abedalkareem omreyh on 18/07/2022.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#else
import Cocoa
#endif

public protocol Controller {
  
  init(player: Player)
  
  typealias ControllerCallback = (Set<Keys>) -> Void

  var arrowAxis: Axis { get set }
  var pressedKeys: Set<Keys> { get set }
  
  func observeForControllerCallback(_ callback: @escaping ControllerCallback)
}

// MARK: -

public struct Axis {
  var x: CGFloat
  var y: CGFloat
}

// MARK: -

public enum Player {
  
  var keys: ControllerKeys {
    switch self {
    case .first:
      return  ControllerKeys(down: .downArrow, up: .upArrow, left: .leftArrow, right: .rightArrow,
                             a: .l, b: .k, x: .j, y: .h,
                             leftShoulder: .u, rightShoulder: .p, leftTrigger: .i, rightTrigger: .o)
    case .second:
      return  ControllerKeys(down: .s, up: .w, left: .a, right: .d,
                             a: .z, b: .x, x: .c, y: .v,
                             leftShoulder: .r, rightShoulder: .t, leftTrigger: .f, rightTrigger: .g)
    }
  }
  
  case first
  case second
}

public struct ControllerKeys {
  let down: Keys
  let up: Keys
  let left: Keys
  let right: Keys

  let a: Keys
  let b: Keys
  let x: Keys
  let y: Keys

  let leftShoulder: Keys
  let rightShoulder: Keys

  let leftTrigger: Keys
  let rightTrigger: Keys
  
  var all: [Keys] {
    [down, up, left, right, a, b, x, y, leftShoulder, rightShoulder, leftTrigger, rightTrigger]
  }
}
