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
  public var x: CGFloat
  public var y: CGFloat
}

// MARK: -

public struct Player {
  
  public static var defaultFirst = Player(keys: ControllerKeys(down: .downArrow, up: .upArrow, left: .leftArrow, right: .rightArrow,
                                                               a: .l, b: .k, x: .j, y: .h,
                                                               leftShoulder: .u, rightShoulder: .p, leftTrigger: .i, rightTrigger: .o),
                                          index: .index1)
  public static var defaultSecond = Player(keys:  ControllerKeys(down: .s, up: .w, left: .a, right: .d,
                                                                 a: .z, b: .x, x: .c, y: .v,
                                                                 leftShoulder: .r, rightShoulder: .t, leftTrigger: .f, rightTrigger: .g),
                                           index: .index2)
  
  public var keys: ControllerKeys
  public let index: PlayerIndex
  
}

public enum PlayerIndex: Int {
  case index1 = 0
  case index2
  case index3
  case index4
}

public struct ControllerKeys {
  public var down: Keys
  public var up: Keys
  public var left: Keys
  public var right: Keys
  
  public var a: Keys
  public var b: Keys
  public var x: Keys
  public var y: Keys
  
  public var leftShoulder: Keys
  public  var rightShoulder: Keys
  
  public var leftTrigger: Keys
  public  var rightTrigger: Keys
  
  public var all: [Keys] {
    [down, up, left, right, a, b, x, y, leftShoulder, rightShoulder, leftTrigger, rightTrigger]
  }
}
