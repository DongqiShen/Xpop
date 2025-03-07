//
//  SettingManager.swift
//  Xpop
//
//  Created by Dongqi Shen on 2025/1/8.
//

import Combine
import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager() // 单例实例

    // 使用 @Published 支持 SwiftUI 实时更新
    @Published var chosenProviderId: String {
        didSet { UserDefaults.standard.set(chosenProviderId, forKey: Keys.chosenProviderId) }
    }

    @Published var chosenProviderName: String {
        didSet { UserDefaults.standard.set(chosenProviderName, forKey: Keys.chosenProviderName) }
    }

    @Published var chosenModels: [String] {
        didSet { UserDefaults.standard.set(chosenModels, forKey: Keys.chosenModels) }
    }

    @Published var chosenModel: String {
        didSet { UserDefaults.standard.set(chosenModel, forKey: Keys.chosenModel) }
    }

    @Published var chosenLanguage: String {
        didSet { UserDefaults.standard.set(chosenLanguage, forKey: Keys.chosenLanguage) }
    }

    @Published var enableForceCopy: Bool {
        didSet { UserDefaults.standard.set(enableForceCopy, forKey: Keys.enableForceCopy) }
    }

    private init() {
        // 从 UserDefaults 初始化设置值
        chosenProviderId = UserDefaults.standard.string(forKey: Keys.chosenProviderId) ?? ""
        chosenProviderName = UserDefaults.standard.string(forKey: Keys.chosenProviderName) ?? ""
        chosenModels = UserDefaults.standard.stringArray(forKey: Keys.chosenModels) ?? [""]
        chosenModel = UserDefaults.standard.string(forKey: Keys.chosenModel) ?? ""
        chosenLanguage = UserDefaults.standard.string(forKey: Keys.chosenLanguage) ?? "English"
        enableForceCopy = UserDefaults.standard.bool(forKey: Keys.enableForceCopy)
    }

    // 设置键名的管理
    private enum Keys {
        static let chosenProviderId = "chosenProviderId"
        static let chosenProviderName = "chosenProviderName"
        static let chosenModels = "chosenModels"
        static let chosenModel = "chosenModel"
        static let chosenLanguage = "chosenLanguage"
        static let selectedMode = "selectedMode"
        static let enableForceCopy = "enableForceCopy"
    }
}
