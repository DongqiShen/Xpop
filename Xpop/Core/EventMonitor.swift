//
//  EventMonitor.swift
//  Xpop
//
//  Created by Dongqi Shen on 2025/1/8.
//

import Cocoa
import SwiftUI

// 定义输入事件类型
enum InputEvent {
    case mouseDown(NSEvent)
    case mouseDragged(NSEvent)
    case mouseUp(NSEvent)
    case mouseMoved(NSEvent)
    case scrollWheel(NSEvent)
    case keyDown(NSEvent)
    case keyUp(NSEvent)
}

// 定义一个抽象的输入事件组合
protocol InputEventCombination {
    var identifier: String { get }
    func handleEvent(_ event: InputEvent) -> Bool
    var onTrigger: (() -> Void)? { get set }
}

// 输入事件监控类
class InputEventMonitor {
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var eventCombinations: [InputEventCombination] = []

    // 最近的鼠标按下和弹起位置（只允许外部读取）
    private(set) var lastMouseDownLocation: NSPoint? // 只读
    private(set) var lastMouseUpLocation: NSPoint? // 只读

    init() {}

    // 注册本地事件监控
    func startLocalMonitoring() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [
            .leftMouseDown,
            .leftMouseUp,
            .leftMouseDragged,
            .mouseMoved,
            .scrollWheel,
            .keyDown,
            .keyUp,
        ]) { [weak self] event in
            self?.handleEvent(event)
            return event
        }
    }

    // 注册全局事件监控
    func startGlobalMonitoring() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [
            .leftMouseDown,
            .leftMouseUp,
            .leftMouseDragged,
            .mouseMoved,
            .scrollWheel,
            .keyDown,
            .keyUp,
        ]) { [weak self] event in
            self?.handleEvent(event)
        }
    }

    // 停止事件监控
    public func stopMonitoring() {
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        localMonitor = nil
        globalMonitor = nil
    }

    // 添加输入事件组合
    func addCombination(_ combination: InputEventCombination) {
        eventCombinations.append(combination)
    }

    // 处理事件并分发给组合
    private func handleEvent(_ event: NSEvent) {
        let inputEvent: InputEvent
        switch event.type {
        case .leftMouseDown:
            inputEvent = .mouseDown(event)
            lastMouseDownLocation = event.locationInWindow // 记录鼠标按下位置
        case .leftMouseDragged:
            inputEvent = .mouseDragged(event)
        case .leftMouseUp:
            inputEvent = .mouseUp(event)
            lastMouseUpLocation = event.locationInWindow // 记录鼠标弹起位置
        case .scrollWheel:
            inputEvent = .scrollWheel(event) // 处理滚轮事件
        case .mouseMoved:
            inputEvent = .mouseMoved(event)
        case .keyDown:
            inputEvent = .keyDown(event)
        case .keyUp:
            inputEvent = .keyUp(event)
        default:
            return
        }

        for combination in eventCombinations where combination.handleEvent(inputEvent) {
            // 添加延迟以处理鼠标抖动
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                combination.onTrigger?()
            }
        }
    }
}

// 鼠标双击事件的组合
class DoubleClickCombination: InputEventCombination {
    let identifier: String
    var onTrigger: (() -> Void)?

    init(identifier: String = "DoubleClick") {
        self.identifier = identifier
    }

    func handleEvent(_ event: InputEvent) -> Bool {
        switch event {
        case let .mouseDown(mouseEvent):
            // 检查是否为双击事件
            if mouseEvent.clickCount == 2 {
                return true
            }
        default:
            break
        }
        return false
    }
}

// 滚轮事件的组合
class ScrollCombination: InputEventCombination {
    let identifier: String
    var onTrigger: (() -> Void)?

    init(identifier: String = "Scroll") {
        self.identifier = identifier
    }

    func handleEvent(_ event: InputEvent) -> Bool {
        switch event {
        case .scrollWheel:
            return true
        default:
            break
        }
        return false
    }
}

// 一个具体的鼠标拖拽 + 鼠标弹起的组合操作
class DragAndDropCombination: InputEventCombination {
    let identifier: String
    private var dragEvents: [NSEvent] = []
    var onTrigger: (() -> Void)?

    private let dragThreshold: Int

    init(identifier: String = "DragAndDrop", dragThreshold: Int = 3) {
        self.identifier = identifier
        self.dragThreshold = dragThreshold
    }

    func handleEvent(_ event: InputEvent) -> Bool {
        switch event {
        case .mouseDown:
            // 清空记录并记录按下事件
            dragEvents.removeAll()
        case let .mouseDragged(mouseEvent):
            // 记录拖拽事件
            dragEvents.append(mouseEvent)
        case .mouseUp:
            // 检查是否满足条件
            if dragEvents.count >= dragThreshold {
                return true
            }
        default:
            // 清空记录并记录按下事件
            dragEvents.removeAll()
        }
        return false
    }
}

// 键盘按键事件的组合
class KeyPressCombination: InputEventCombination {
    let identifier: String
    var onTrigger: (() -> Void)?

    private let keyCode: UInt16

    init(identifier: String = "KeyPress", keyCode: UInt16) {
        self.identifier = identifier
        self.keyCode = keyCode
    }

    func handleEvent(_ event: InputEvent) -> Bool {
        switch event {
        case let .keyDown(keyEvent):
            if keyEvent.keyCode == keyCode {
                return true
            }
        default:
            break
        }
        return false
    }
}

// 自定义输入事件处理组合
class CustomInputEventHandler: InputEventCombination {
    let identifier: String
    private let handler: (InputEvent) -> Bool
    var onTrigger: (() -> Void)?

    init(identifier: String = "CustomInputEvent", handler: @escaping (InputEvent) -> Bool) {
        self.identifier = identifier
        self.handler = handler
    }

    func handleEvent(_ event: InputEvent) -> Bool {
        handler(event)
    }
}
