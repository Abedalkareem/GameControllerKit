//
//  Keyboard.swift
//
//  Created by abedalkareem omreyh on 22/05/2022.
//

#if os(macOS)
import AppKit

public class Keyboard: Controller {
    
  // MARK: - Properties
  
  var arrowAxis = Axis(x: 0, y: 0)
  var pressedKeys = Set<Keys>()
  var player: Player

  // MARK: - Private Properties
  
  private var eventHandler: Any?
  private var callback: ControllerCallback?
  
  // MARK: - init
  
  required init(player: Player) {
    self.player = player
    addLocalMonitorForEvents()
  }
  
  // MARK: - Private Methods
  
  private func addLocalMonitorForEvents() {
    eventHandler = NSEvent
      .addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event -> NSEvent? in
        guard let self = self else { return event }
        
        guard let key = Keys(rawValue: event.keyCode), self.player.keys.all.contains(key) else {
          return event
        }
        
        if event.type == .keyDown {
          self.pressedKeys.insert(key)
        } else if event.type == .keyUp {
          self.pressedKeys.remove(key)
        }
        
        self.updateAxis()
        
        self.callback?(self.pressedKeys)

        return nil
      }
  }
  
  private func updateAxis() {
    switch pressedKeys {
    case let keys where keys.isSuperset(of: [player.keys.up, player.keys.left]):
      arrowAxis = Axis(x: -1, y: 1)
    case let keys where keys.isSuperset(of: [player.keys.up, player.keys.right]):
      arrowAxis = Axis(x: 1, y: 1)
    case let keys where keys.isSuperset(of: [player.keys.down, player.keys.left]):
      arrowAxis = Axis(x: -1, y: -1)
    case let keys where keys.isSuperset(of: [player.keys.down, player.keys.right]):
      arrowAxis = Axis(x: 1, y: -1)
    case let keys where keys.contains(player.keys.up):
      arrowAxis = Axis(x: 0, y: 1)
    case let keys where keys.contains(player.keys.down):
      arrowAxis = Axis(x: 0, y: -1)
    case let keys where keys.contains(player.keys.left):
      arrowAxis = Axis(x: -1, y: 0)
    case let keys where keys.contains(player.keys.right):
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
  
  func observeForControllerCallback(_ callback: @escaping ControllerCallback) {
    self.callback = callback
  }
  
  // MARK: - deinit
  
  deinit {
    removeMonitorForEvents()
  }
}
#endif
