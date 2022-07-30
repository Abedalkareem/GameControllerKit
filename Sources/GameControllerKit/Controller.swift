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
  
  static let defaultFirst = Player(keys: ControllerKeys(down: .downArrow, up: .upArrow, left: .leftArrow, right: .rightArrow,
                                                        a: .l, b: .k, x: .j, y: .h,
                                                        leftShoulder: .u, rightShoulder: .p, leftTrigger: .i, rightTrigger: .o),
                                   index: .index1)
  static let defaultSecond = Player(keys:  ControllerKeys(down: .s, up: .w, left: .a, right: .d,
                                                          a: .z, b: .x, x: .c, y: .v,
                                                          leftShoulder: .r, rightShoulder: .t, leftTrigger: .f, rightTrigger: .g),
                                    index: .index2)
  
  public let keys: ControllerKeys
  public let index: PlayerIndex
  
}

public enum PlayerIndex: Int {
  case index1 = 0
  case index2
  case index3
  case index4
}

public struct ControllerKeys {
  public let down: Keys
  public let up: Keys
  public let left: Keys
  public let right: Keys
  
  public let a: Keys
  public let b: Keys
  public let x: Keys
  public let y: Keys
  
  public let leftShoulder: Keys
  public  let rightShoulder: Keys
  
  public let leftTrigger: Keys
  public  let rightTrigger: Keys
  
  public var all: [Keys] {
    [down, up, left, right, a, b, x, y, leftShoulder, rightShoulder, leftTrigger, rightTrigger]
  }
}
