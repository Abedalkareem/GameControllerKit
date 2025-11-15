//
//  Gamepad.swift
//  
//
//  Created by abedalkareem omreyh on 29/07/2022.
//

#if !os(watchOS)
import Foundation
import GameController
import Combine

public class Gamepad: Controller {
  
  public typealias GamepadStateUpdated = (GamepadState) -> Void

  // MARK: - Properties
  
  public var arrowAxis = Axis(x: 0, y: 0)
  public var pressedKeys = Set<Keys>()
  public var player: Player
  public var index: PlayerIndex {
    player.index
  }

  public var controller: GCController? {
    GCController.controllers()
      .first(where: { $0.playerIndex == GCControllerPlayerIndex(rawValue: player.index.rawValue) })
  }
  
  // MARK: - Private Properties
  
  private var controllerConnected: Bool {
    return controller != nil
  }
  private var controllerCallback: ControllerCallback?
  private var gamepadStateUpdated: GamepadStateUpdated?
  private var axisCallback: AxisCallback?

  // MARK: - init
  
  public required init(player: Player) {
    self.player = player
    observeForControllers()
    startWirelessControllerDiscovery()
  }
  
  private func startWirelessControllerDiscovery() {
    GCController.startWirelessControllerDiscovery()
  }
  
  private func observeForControllers() {
    NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { [weak self] notification in
      self?.checkControllers()
    }
    
    NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] notification in
      self?.checkControllers()
    }
  }
  
  private func checkControllers() {
    var controllers: [GCController] = GCController.controllers().reversed()
    guard controllers.count >= 1 else {
      gamepadStateUpdated?(.noControllersConnected)
      return
    }

    guard controllers.count >= 2 else {
      controllers.first?.playerIndex = .index1
      observeForKeys()
      gamepadStateUpdated?(.oneControllerConnected)
      return
    }

    var allIndexes: [GCControllerPlayerIndex] = [.index1, .index2, .index3, .index4]
    if controllers.count > 4 {
      controllers = controllers.filter({ $0.extendedGamepad != nil })
    }
    controllers.forEach({ controller in allIndexes.removeAll(where: { index in index.rawValue == controller.playerIndex.rawValue }) })
    let controllersWithoutIndex = controllers.filter({ $0.playerIndex == .indexUnset })
    controllersWithoutIndex.forEach({ $0.playerIndex = allIndexes.removeFirst() })
    observeForKeys()
    gamepadStateUpdated?(.allGood)
  }
  
  private func observeForKeys() {
    guard let controller = self.controller else {
      return
    }
    
    let dpadValueChangedHandler: GCControllerDirectionPadValueChangedHandler = { [weak self] value, x, y in
      self?.arrowAxis = Axis(x: CGFloat(x), y: CGFloat(y))
      self?.axisCallback?(self?.arrowAxis ?? .init(x: 0, y: 0))
      if let arrowAxis = self?.arrowAxis {
        // Remove all directional keys first
        self?.pressedKeys.remove(.leftArrow)
        self?.pressedKeys.remove(.rightArrow)
        self?.pressedKeys.remove(.upArrow)
        self?.pressedKeys.remove(.downArrow)
        
        // Add pressed keys based on axis values
        if arrowAxis.x < -0.5 {
          self?.pressedKeys.insert(.leftArrow)
        } else if arrowAxis.x > 0.5 {
          self?.pressedKeys.insert(.rightArrow)
        }
        
        if arrowAxis.y < -0.5 {
          self?.pressedKeys.insert(.downArrow)
        } else if arrowAxis.y > 0.5 {
          self?.pressedKeys.insert(.upArrow)
        }
        
        self?.controllerCallback?(self?.pressedKeys ?? [])
      }
    }
    controller.microGamepad?.dpad.valueChangedHandler = dpadValueChangedHandler
    controller.extendedGamepad?.leftThumbstick.valueChangedHandler = dpadValueChangedHandler
    
    controller.microGamepad?.buttonA.valueChangedHandler = getValueChangedHandler(for: .buttonA)
    controller.microGamepad?.buttonX.valueChangedHandler = getValueChangedHandler(for: .buttonX)
    controller.extendedGamepad?.buttonA.valueChangedHandler = getValueChangedHandler(for: .buttonA)
    controller.extendedGamepad?.buttonX.valueChangedHandler = getValueChangedHandler(for: .buttonX)

    controller.extendedGamepad?.buttonB.valueChangedHandler = getValueChangedHandler(for: .buttonB)
    controller.extendedGamepad?.buttonY.valueChangedHandler = getValueChangedHandler(for: .buttonY)
  }
  
  private func getValueChangedHandler(for button: Keys) -> GCControllerButtonValueChangedHandler {
    let valueChangedHandler: GCControllerButtonValueChangedHandler = { [weak self] _, value, isPressed in
      if isPressed {
        self?.pressedKeys.insert(button)
      } else {
        self?.pressedKeys.remove(button)
      }
      self?.controllerCallback?(self?.pressedKeys ?? [])
    }
    return valueChangedHandler
  }
  
  // MARK: - Public methods
  
  public func observeForControllerCallback(_ callback: @escaping ControllerCallback) {
    self.controllerCallback = callback
    checkControllers()
  }
  
  public func observeForGamepadStateUpdated(_ callback: @escaping GamepadStateUpdated) {
    self.gamepadStateUpdated = callback
    checkControllers()
  }
  
  public func observeForControllerAxisCallback(_ callback: @escaping AxisCallback) {
    self.axisCallback = callback
  }
}

// MARK: -

public enum GamepadState {
  
  public var message: String {
    switch self {
    case .allGood:
      return ""
    case .noControllersConnected:
      return "No Controllers Connected"
    case .oneControllerConnected:
      return "One controller connected, Please connect another one"
    }
  }
  
  case noControllersConnected
  case oneControllerConnected
  case allGood
}
#endif
