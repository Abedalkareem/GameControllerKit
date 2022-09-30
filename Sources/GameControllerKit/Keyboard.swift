//
//  Keyboard.swift
//
//  Created by abedalkareem omreyh on 22/05/2022.
//

#if os(macOS)
import AppKit

public class Keyboard: Controller {
    
  // MARK: - Properties
  
  public var arrowAxis = Axis(x: 0, y: 0)
  public var pressedKeys = Set<Keys>()
  public var player: Player
  public var index: PlayerIndex {
    player.index
  }

  // MARK: - Private Properties
  
  private var eventHandler: Any?
  private var callback: ControllerCallback?
  
  // MARK: - init
  
  public required init(player: Player) {
    self.player = player
    addLocalMonitorForEvents()
  }
  
  // MARK: - Private Methods
  
  private func addLocalMonitorForEvents() {
    eventHandler = NSEvent
      .addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event -> NSEvent? in
        guard let self = self else { return event }
        
        guard let key = Keys(rawValue: event.keyCode), self.player.keyboardToControllerKeysMap.all.contains(key) else {
          return event
        }
        
        let mappedKey = self.player.keyboardToControllerKeysMap.getMappedKeyFor(key: key) ?? key
        if event.type == .keyDown {
          self.pressedKeys.insert(mappedKey)
        } else if event.type == .keyUp {
          self.pressedKeys.remove(mappedKey)
        }
        
        self.updateAxis()
        
        self.callback?(self.pressedKeys)

        return nil
      }
  }
  
  private func updateAxis() {
    let controllerKeys = self.player.keyboardToControllerKeysMap
    switch pressedKeys {
    case let keys where keys.isSuperset(of: [controllerKeys.up, controllerKeys.left]):
      arrowAxis = Axis(x: -1, y: 1)
    case let keys where keys.isSuperset(of: [controllerKeys.up, controllerKeys.right]):
      arrowAxis = Axis(x: 1, y: 1)
    case let keys where keys.isSuperset(of: [controllerKeys.down, controllerKeys.left]):
      arrowAxis = Axis(x: -1, y: -1)
    case let keys where keys.isSuperset(of: [controllerKeys.down, controllerKeys.right]):
      arrowAxis = Axis(x: 1, y: -1)
    case let keys where keys.contains(controllerKeys.up):
      arrowAxis = Axis(x: 0, y: 1)
    case let keys where keys.contains(controllerKeys.down):
      arrowAxis = Axis(x: 0, y: -1)
    case let keys where keys.contains(controllerKeys.left):
      arrowAxis = Axis(x: -1, y: 0)
    case let keys where keys.contains(controllerKeys.right):
      arrowAxis = Axis(x: 1, y: 0)
    default:
      arrowAxis = Axis(x: 0, y: 0)
    }
  }
  
  private func removeMonitorForEvents() {
    guard let eventHandler = eventHandler else {
      return
    }
    NSEvent.removeMonitor(eventHandler)
  }
  
  // MARK: - Public Method
  
  public func observeForControllerCallback(_ callback: @escaping ControllerCallback) {
    self.callback = callback
  }
  
  // MARK: - deinit
  
  deinit {
    removeMonitorForEvents()
  }
}
#endif
