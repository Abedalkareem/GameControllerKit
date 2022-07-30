//
//  Gamepad.swift
//  
//
//  Created by abedalkareem omreyh on 29/07/2022.
//

import Foundation
import GameController

public class Gamepad: Controller {
  
  public typealias GamepadStateUpdated = (GamepadState) -> Void
    
  // MARK: - Properties
  
  public var arrowAxis = Axis(x: 0, y: 0)
  public var pressedKeys = Set<Keys>()
  public var player: Player

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

  // MARK: - init
  
  public required init(player: Player) {
    self.player = player
    startWirelessControllerDiscovery()
    observeForControllers()
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
    
    controllers.first?.playerIndex = .index1
    observeForKeys()
    
    guard controllers.count >= 2 else {
      gamepadStateUpdated?(.justOneControllerConnected)
      return
    }
    
    let extendedGamepads = controllers.filter({ $0.extendedGamepad != nil })
    if extendedGamepads.count >= 2 {
      controllers = extendedGamepads
    }
    
    controllers.enumerated().forEach({ $1.playerIndex = GCControllerPlayerIndex(rawValue: $0)! })
    gamepadStateUpdated?(.allGood)
    observeForKeys()
  }
  
  private func observeForKeys() {
    guard let controller = self.controller else {
      return
    }
    
    let dpadValueChangedHandler: GCControllerDirectionPadValueChangedHandler = { [weak self] value, x, y in
      self?.arrowAxis = Axis(x: CGFloat(x), y: CGFloat(y))
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
        self?.pressedKeys.insert(button)
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
}

// MARK: -

public enum GamepadState {
  
  public var message: String {
    switch self {
    case .allGood:
      return ""
    case .noControllersConnected:
      return "No Controllers Connected"
    case .justOneControllerConnected:
      return "One controller connected, Please connect another one"
    }
  }
  
  case noControllersConnected
  case justOneControllerConnected
  case allGood
}
