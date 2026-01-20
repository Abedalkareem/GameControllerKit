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

  // MARK: - Static Properties

  /// Ensures controller assignment only happens once globally
  private static var didSetupGlobalObserver = false
  /// Maps each GCController to a PlayerIndex - this is our source of truth, not GCController.playerIndex
  private static var controllerToPlayerMap = [ObjectIdentifier: PlayerIndex]()
  private static var gamepadInstances = [WeakGamepad]()

  // MARK: - Properties

  public var arrowAxis = Axis(x: 0, y: 0)
  public var pressedKeys = Set<Keys>()
  public var player: Player
  public var index: PlayerIndex {
    player.index
  }

  /// Returns the GCController assigned to this player based on our internal mapping
  public var controller: GCController? {
    let controllers = GCController.controllers()
    return controllers.first(where: { gcController in
      let id = ObjectIdentifier(gcController)
      return Gamepad.controllerToPlayerMap[id] == player.index
    })
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
    Gamepad.registerInstance(self)
    Gamepad.setupGlobalObserverIfNeeded()
    startWirelessControllerDiscovery()
  }

  private func startWirelessControllerDiscovery() {
    GCController.startWirelessControllerDiscovery()
  }

  // MARK: - Static Methods for Global Controller Management

  private static func registerInstance(_ gamepad: Gamepad) {
    // Clean up deallocated instances
    gamepadInstances.removeAll(where: { $0.gamepad == nil })
    gamepadInstances.append(WeakGamepad(gamepad))
  }

  private static func setupGlobalObserverIfNeeded() {
    guard !didSetupGlobalObserver else { return }
    didSetupGlobalObserver = true

    NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { _ in
      Gamepad.assignControllers()
      Gamepad.notifyAllInstances()
    }

    NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { _ in
      Gamepad.assignControllers()
      Gamepad.notifyAllInstances()
    }

    // Initial assignment
    Gamepad.assignControllers()
  }

  /// Assigns controllers to players based on connection order
  /// This uses our own mapping instead of relying on GCController.playerIndex
  private static func assignControllers() {
    let controllers = GCController.controllers()

    // Remove disconnected controllers from our map
    let connectedIds = Set(controllers.map { ObjectIdentifier($0) })
    controllerToPlayerMap = controllerToPlayerMap.filter { connectedIds.contains($0.key) }

    // Find which player indices are already assigned
    let assignedIndices = Set(controllerToPlayerMap.values)

    // Available indices in order
    var availableIndices: [PlayerIndex] = [.index1, .index2, .index3, .index4]
      .filter { !assignedIndices.contains($0) }

    // Assign unassigned controllers to available indices
    for gcController in controllers {
      let id = ObjectIdentifier(gcController)
      if controllerToPlayerMap[id] == nil && !availableIndices.isEmpty {
        let assignedIndex = availableIndices.removeFirst()
        controllerToPlayerMap[id] = assignedIndex
        // Also set the GCController's playerIndex for visual feedback (LED indicators)
        gcController.playerIndex = GCControllerPlayerIndex(rawValue: assignedIndex.rawValue) ?? .index1
      }
    }
  }

  /// Notifies all Gamepad instances to update their key observers
  private static func notifyAllInstances() {
    // Clean up deallocated instances
    gamepadInstances.removeAll(where: { $0.gamepad == nil })

    let controllerCount = GCController.controllers().count

    for weakGamepad in gamepadInstances {
      weakGamepad.gamepad?.onControllersChanged(count: controllerCount)
    }
  }

  private func onControllersChanged(count: Int) {
    observeForKeys()

    if count == 0 {
      gamepadStateUpdated?(.noControllersConnected)
    } else if count == 1 {
      gamepadStateUpdated?(.oneControllerConnected)
    } else {
      gamepadStateUpdated?(.allGood)
    }
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
    Gamepad.assignControllers()
    onControllersChanged(count: GCController.controllers().count)
  }

  public func observeForGamepadStateUpdated(_ callback: @escaping GamepadStateUpdated) {
    self.gamepadStateUpdated = callback
    Gamepad.assignControllers()
    onControllersChanged(count: GCController.controllers().count)
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

// MARK: - WeakGamepad

/// Wrapper to hold weak references to Gamepad instances
private class WeakGamepad {
  weak var gamepad: Gamepad?

  init(_ gamepad: Gamepad) {
    self.gamepad = gamepad
  }
}
#endif
