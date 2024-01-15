//
//  Controller.swift
//
//  Created by abedalkareem omreyh on 18/07/2022.
//

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#else
import Cocoa
#endif

public protocol Controller {
  
  init(player: Player)
  
  typealias ControllerCallback = (Set<Keys>) -> Void
  typealias AxisCallback = (Axis) -> Void

  var arrowAxis: Axis { get set }
  var pressedKeys: Set<Keys> { get set }
  var index: PlayerIndex { get }

  func observeForControllerCallback(_ callback: @escaping ControllerCallback)
  func observeForControllerAxisCallback(_ callback: @escaping AxisCallback)
}

// MARK: -

public struct Axis {
  public var x: CGFloat
  public var y: CGFloat
}

// MARK: -

public struct Player {
  
  public static var defaultFirst = Player(keyboardToControllerKeysMap: KeyboardToControllerKeysMap(down: .downArrow, up: .upArrow, left: .leftArrow, right: .rightArrow,
                                                                                                   a: .l, b: .k, x: .j, y: .h,
                                                                                                   leftShoulder: .u, rightShoulder: .p, leftTrigger: .i, rightTrigger: .o),
                                          index: .index1)
  public static var defaultSecond = Player(keyboardToControllerKeysMap: KeyboardToControllerKeysMap(down: .s, up: .w, left: .a, right: .d,
                                                                                                    a: .z, b: .x, x: .c, y: .v,
                                                                                                    leftShoulder: .r, rightShoulder: .t, leftTrigger: .f, rightTrigger: .g),
                                           index: .index2)
  
  public var keyboardToControllerKeysMap: KeyboardToControllerKeysMap
  public var index: PlayerIndex
  
  public init(keyboardToControllerKeysMap: KeyboardToControllerKeysMap, index: PlayerIndex) {
    self.keyboardToControllerKeysMap = keyboardToControllerKeysMap
    self.index = index
  }
}

public enum PlayerIndex: Int {
  case index1 = 0
  case index2
  case index3
  case index4
}

public struct KeyboardToControllerKeysMap {

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

  public init(down: Keys, up: Keys, left: Keys, right: Keys, a: Keys, b: Keys, x: Keys, y: Keys, leftShoulder: Keys, rightShoulder: Keys, leftTrigger: Keys, rightTrigger: Keys) {
    self.down = down
    self.up = up
    self.left = left
    self.right = right
    self.a = a
    self.b = b
    self.x = x
    self.y = y
    self.leftShoulder = leftShoulder
    self.rightShoulder = rightShoulder
    self.leftTrigger = leftTrigger
    self.rightTrigger = rightTrigger
  }
  
  public var all: [Keys] {
    [down, up, left, right, a, b, x, y, leftShoulder, rightShoulder, leftTrigger, rightTrigger]
  }
  
  public func getMappedKeyFor(key: Keys) -> Keys? {
    switch key {
    case self.down:
      return .downArrow
    case self.up:
      return .upArrow
    case self.left:
      return .leftArrow
    case self.right:
      return .rightArrow
    case self.a:
      return .buttonA
    case self.b:
      return .buttonB
    case self.x:
      return .buttonX
    case self.y:
      return .buttonY
    case self.leftShoulder:
      return .leftShoulder
    case self.rightShoulder:
      return .rightShoulder
    case self.leftTrigger:
      return .leftTrigger
    case self.rightTrigger:
      return .rightTrigger
    default:
      return nil
    }
  }
}
