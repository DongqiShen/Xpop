//
//  ExtensionManager.swift
//  Xpop
//
//  Created by Dongqi Shen on 2025/1/17.
//

import Foundation
import SwiftUI
import Yams

class ExtensionManager: ObservableObject {
    // MARK: - Shared Instance

    static let shared = ExtensionManager()
    private let logger = Logger.shared

    // MARK: - Properties

    @Published var extensions: [String: Extension] = [:]
    @Published var extensionList: [ExtensionItem] = []

    // MARK: - UserDefaults Key

    private let extensionListKey = "extensionList"

    init() {
        loadExtensions()
        loadBuildinExtensions()
        loadExtensionList()
        // 保存到 UserDefaults
        saveExtensionList()
    }

    func loadBuildinExtensions() {
//        UserDefaults.standard.removeObject(forKey: "extensionList")
        // 搜索插件
        let searchExtension = Extension(
            name: "Search",
            icon: "symbol:magnifyingglass",
            url: "https://www.google.com/search?q={xpop text}"
        )

        let searchExtensionItem = ExtensionItem(
            name: "_XPOP_BUILDIN_SEARCH",
            isEnabled: true
        )

        // 翻译插件
        let translateExtension = Extension(
            name: "Translate",
            icon: "symbol:translate",
            builtinType: "_buildin"
        )
        let translateExtensionItem = ExtensionItem(
            name: "_XPOP_BUILDIN_TRANSLATE",
            isEnabled: true
        )

        // Copy
        let copyExtension = Extension(
            name: "Copy",
//            icon: "symbol:document.on.document",
            builtinType: "_buildin"
        )
        let copyExtensionItem = ExtensionItem(
            name: "_XPOP_BUILDIN_COPY",
            isEnabled: true
        )

        // Cut
        let cutExtension = Extension(
            name: "Cut",
//            icon: "symbol:scissors",
            builtinType: "_buildin"
        )
        let cutExtensionItem = ExtensionItem(
            name: "_XPOP_BUILDIN_CUT",
            isEnabled: true
        )

        // Paste
        let pasteExtension = Extension(
            name: "Paste",
//            icon: "symbol:document.on.clipboard",
            builtinType: "_buildin"
        )
        let pasteExtensionItem = ExtensionItem(
            name: "_XPOP_BUILDIN_PASTE",
            isEnabled: true
        )

        // 检查并添加搜索插件
        if !extensionList.contains(where: { $0.name == searchExtensionItem.name }) {
            extensionList.append(searchExtensionItem)
        }
        if extensions[searchExtensionItem.name] == nil {
            extensions[searchExtensionItem.name] = searchExtension
        }

        // 检查并添加翻译插件
        if !extensionList.contains(where: { $0.name == translateExtensionItem.name }) {
            extensionList.append(translateExtensionItem)
        }
        if extensions[translateExtensionItem.name] == nil {
            extensions[translateExtensionItem.name] = translateExtension
        }

        // 检查并添加copy插件
        if !extensionList.contains(where: { $0.name == copyExtensionItem.name }) {
            extensionList.append(copyExtensionItem)
        }
        if extensions[copyExtensionItem.name] == nil {
            extensions[copyExtensionItem.name] = copyExtension
        }

        // 检查并添加cut插件
        if !extensionList.contains(where: { $0.name == cutExtensionItem.name }) {
            extensionList.append(cutExtensionItem)
        }
        if extensions[cutExtensionItem.name] == nil {
            extensions[cutExtensionItem.name] = cutExtension
        }

        // 检查并添加paste插件
        if !extensionList.contains(where: { $0.name == pasteExtensionItem.name }) {
            extensionList.append(pasteExtensionItem)
        }
        if extensions[pasteExtensionItem.name] == nil {
            extensions[pasteExtensionItem.name] = pasteExtension
        }
    }

    // MARK: - Load Extensions

    func loadExtensions() {
        let extensionsDirectory = getExtensionsDirectory()
        // 检查目录是否存在
        guard FileManager.default.fileExists(atPath: extensionsDirectory.path) else {
            logger.log("Extensions directory does not exist.", type: .error)
            return
        }

        // 获取所有插件文件夹
        do {
            let pluginFolders = try FileManager.default.contentsOfDirectory(atPath: extensionsDirectory.path)
            for folder in pluginFolders where folder.hasSuffix(".xpopext") {
                    let pluginDirectory = extensionsDirectory.appendingPathComponent(folder)
                    let configFilePath = pluginDirectory.appendingPathComponent("Config.yaml")
                    // 检查配置文件是否存在
                    if FileManager.default.fileExists(atPath: configFilePath.path) {
                        do {
                            let yamlString = try String(contentsOf: configFilePath, encoding: .utf8)
                            let extensionInstance = try ExtensionManager.fromYAML(yamlString)
                            extensions[folder] = extensionInstance
                        } catch {
                            logger.log(
                                "Failed to load extension from %{public}@: %{public}@:",
                                folder,
                                error.localizedDescription,
                                type: .error
                            )
                        }
                }
            }
        } catch {
            logger.log("Failed to load extensions: %{public}@", error.localizedDescription, type: .error)
        }
    }

    // MARK: - Load Extension List

    func loadExtensionList() {
        if let savedData = UserDefaults.standard.data(forKey: extensionListKey) {
            // 如果 UserDefaults 中有保存的数据，则解码并加载
            let decoder = JSONDecoder()
            if let decodedList = try? decoder.decode([ExtensionItem].self, from: savedData) {
                extensionList = decodedList
            }
        }

        // 找到 extensions 中存在但 extensionList 中不存在的插件
        let newExtensions = extensions
            .filter { key, _ in
                !self.extensionList.contains { $0.name == key }
            }
            .map { key, ext in
                ExtensionItem(name: key, isEnabled: ext.isEnabled)
            }

        // 将新插件添加到 extensionList 的末尾
        extensionList.append(contentsOf: newExtensions)
    }

    // MARK: - Save Extension List to UserDefaults

    private func saveExtensionList() {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(extensionList) {
            UserDefaults.standard.set(encodedData, forKey: extensionListKey)
        }
    }

    // MARK: - Update Extension State

    func updateExtensionState(extName: String, isEnabled: Bool) {
        if let ext = extensions[extName] {
            ext.isEnabled = isEnabled
            extensions[extName] = ext
        }
        if let index = extensionList.firstIndex(where: { $0.name == extName }) {
            extensionList[index].isEnabled = isEnabled
        }
        saveExtensionList()
    }

    func moveExtensions(from source: IndexSet, to destination: Int) {
        withAnimation {
            extensionList.move(fromOffsets: source, toOffset: destination)
            saveExtensionList()
        }
    }

    // MARK: - Delete Extension

    func deleteExtension(extensionName: String) {
        // 1. 从 extensions 字典中移除插件
        extensions.removeValue(forKey: extensionName)

        // 2. 从 extensionList 数组中移除插件
        if let index = extensionList.firstIndex(where: { $0.name == extensionName }) {
            extensionList.remove(at: index)
        }

        // 3. 保存更新后的 extensionList 到 UserDefaults
        saveExtensionList()

        // 4. 从文件系统中删除插件目录
        let extensionsDirectory = getExtensionsDirectory()
        let pluginDirectory = extensionsDirectory.appendingPathComponent(extensionName)

        // 检查插件目录是否存在
        guard FileManager.default.fileExists(atPath: pluginDirectory.path) else {
            logger.log("Plugin directory %{public}@ does not exist.", extensionName, type: .info)
            return
        }

        // 删除插件目录
        do {
            try FileManager.default.removeItem(at: pluginDirectory)
            logger.log("Deleted plugin directory at: %{public}@", pluginDirectory.path, type: .info)
        } catch {
            logger.log(
                "Failed to delete plugin directory %{public}@: %{public}@",
                extensionName,
                error.localizedDescription,
                type: .error
            )
        }
    }

    func getExtensionByName(name: String) -> Extension {
        extensions[name]!
    }

    func getExtensionDir(name: String) -> String? {
        for (key, extensionValue) in extensions where extensionValue.name == name {
                return key
        }
        return nil // 如果没找到，返回 nil
    }

    // MARK: - 获取 Extensions 目录

    private func getExtensionsDirectory() -> URL {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let extensionsDirectory = appSupportURL
            .appendingPathComponent("Xpop")
            .appendingPathComponent("Extensions")

        // 检查目录是否存在，如果不存在则创建
        if !FileManager.default.fileExists(atPath: extensionsDirectory.path) {
            do {
                try FileManager.default.createDirectory(
                    at: extensionsDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                logger.log(
                    "Failed to create Extensions directory: %{public}@",
                    error.localizedDescription,
                    type: .error
                )
            }
        }

        return extensionsDirectory
    }

    // MARK: - 检查字符串是否以 #popclip 或 # popclip 开头

    static func isExtensionString(_ yamlString: String) -> Bool {
        yamlString.starts(with: "#popclip") || yamlString.starts(with: "# popclip") || yamlString
            .starts(with: "#xpop") || yamlString.starts(with: "# xpop")
    }

    // MARK: - 从 YAML 字符串解析扩展
    static func fromYAML(_ yamlString: String) throws -> Extension {
        guard isExtensionString(yamlString) else {
            throw Extension.ExtensionError.invalidHeader
        }

        // 解析 YAML 字符串
        let yamlDict: [String: Any]
        do {
            if let parsedDict = try Yams.load(yaml: yamlString) as? [String: Any] {
                yamlDict = parsedDict
            } else {
                throw Extension.ExtensionError.invalidYAML("Parsed YAML is not a dictionary.")
            }
        } catch {
            // 捕获 Yams 的原始错误并返回
            throw Extension.ExtensionError.invalidYAML("YAML parsing failed: \(error)")
        }

        // 验证必填字段
        guard yamlDict["name"] is String else {
            throw Extension.ExtensionError.missingRequiredField("name")
        }

        // 解析 options 字段
        var options: [Option]?
        if let optionsArray = yamlDict["options"] as? [[String: Any]] {
            options = try optionsArray.map { optionDict in
                guard let type = optionDict["type"] as? String,
                      let label = optionDict["label"] as? String else {
                    throw Extension.ExtensionError.missingRequiredField("type or label in options")
                }
                return Option(
                    identifier: optionDict["identifier"] as! String, type: type,
                    label: label,
                    description: optionDict["description"] as? String,
                    defaultValue: optionDict["defaultValue"] as? String,
                    values: optionDict["values"] as? [String],
                    valueLabels: optionDict["valueLabels"] as? [String]
                )
            }
        }

        // 创建 Extension 对象
        let xpopExtension = Extension(
            name: yamlDict["name"] as? String,
            icon: yamlDict["icon"] as? String,
            identifier: yamlDict["identifier"] as? String,
            description: yamlDict["description"] as? String,
            macosVersion: yamlDict["macos version"] as? String,
            popclipVersion: yamlDict["popclip version"] as? Int,
            entitlements: yamlDict["entitlements"] as? [String],
            action: yamlDict["action"] as? [String: String],
            url: yamlDict["url"] as? String,
            keyCombo: yamlDict["key combo"] as? String,
            keyCombos: yamlDict["key combos"] as? [String],
            shortcutName: yamlDict["shortcut name"] as? String,
            serviceName: yamlDict["service name"] as? String,
            shellScript: yamlDict["shell script"] as? String,
            shellScriptFile: yamlDict["shell script file"] as? String,
            interpreter: yamlDict["interpreter"] as? String,
            options: options
        )
        return xpopExtension
    }

    // MARK: - 生成随机字符串

    private func generateRandomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in letters.randomElement()! })
    }

    // MARK: - 安装插件

    func install(ext: Extension) throws -> String {
        let extensionsDirectory = getExtensionsDirectory()

        // 如果目录不存在，则创建
        if !FileManager.default.fileExists(atPath: extensionsDirectory.path) {
            try FileManager.default.createDirectory(
                at: extensionsDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        // 生成插件文件夹名称
        guard let name = ext.name else {
            throw Extension.ExtensionError.missingRequiredField("name")
        }
        let sanitizedName = name.replacingOccurrences(of: " ", with: "-")
        let randomSuffix = generateRandomString(length: 8)
        let folderName = "\(sanitizedName).\(randomSuffix).xpopext"
        let pluginDirectory = extensionsDirectory.appendingPathComponent(folderName)

        // 检查是否存在同名插件
        let existingPluginDirectories = try FileManager.default.contentsOfDirectory(atPath: extensionsDirectory.path)
        for existingDirectory in existingPluginDirectories {
            if existingDirectory.hasPrefix("\(sanitizedName)."), existingDirectory.hasSuffix(".xpopext") {
                // 删除已存在的同名插件
                removeExtension(foldName: existingDirectory)
                let existingPluginDirectory = extensionsDirectory.appendingPathComponent(existingDirectory)
                try FileManager.default.removeItem(at: existingPluginDirectory)
                logger.log("Removed existing plugin at: %{public}@", existingPluginDirectory.path, type: .info)
            }
        }

        // 创建插件文件夹
        try FileManager.default.createDirectory(at: pluginDirectory, withIntermediateDirectories: true, attributes: nil)
        // 将插件信息转换为 YAML 字符串
        let yamlString = try ext.toYAML()
        // 写入 Config.yaml 文件
        let configFilePath = pluginDirectory.appendingPathComponent("Config.yaml")
        try yamlString.write(to: configFilePath, atomically: true, encoding: .utf8)
        // 重新加载插件
        loadExtensions()
        loadExtensionList()
        return folderName // 返回文件的目录
    }

    func install(url: URL) throws {
        let extensionsDirectory = getExtensionsDirectory()
        // 如果目录不存在，则创建
        if !FileManager.default.fileExists(atPath: extensionsDirectory.path) {
            try FileManager.default.createDirectory(
                at: extensionsDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        let fileName = url.lastPathComponent // 获取完整文件名（包括扩展名）
        let name = url.deletingPathExtension().lastPathComponent // 去掉扩展名
        let pluginDirectory = extensionsDirectory.appendingPathComponent(fileName)

        // 检查是否存在同名插件
        let existingPluginDirectories = try FileManager.default.contentsOfDirectory(atPath: extensionsDirectory.path)
        for existingDirectory in existingPluginDirectories {
            if existingDirectory.hasPrefix(name), existingDirectory.hasSuffix(".xpopext") {
                // 删除已存在的同名插件
                removeExtension(foldName: existingDirectory)
                let existingPluginDirectory = extensionsDirectory.appendingPathComponent(existingDirectory)
                try FileManager.default.removeItem(at: existingPluginDirectory)
                logger.log("Removed existing plugin at: %{public}@", existingPluginDirectory.path, type: .info)
            }
        }
        do {
            let fileManager = FileManager.default
            let destinationURL = extensionsDirectory.appendingPathComponent(url.lastPathComponent) // 构建完整的目标路径

            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            try fileManager.copyItem(at: url, to: destinationURL)
        } catch {
            print(url)
            print(extensionsDirectory)
            print(error.localizedDescription)
        }

        let configFilePath = pluginDirectory.appendingPathComponent("Config.yaml")
        let yamlString = try String(contentsOf: configFilePath, encoding: .utf8)
        let extensionInstance = try ExtensionManager.fromYAML(yamlString)
        extensions[fileName] = extensionInstance
        extensionList.append(ExtensionItem(name: fileName, isEnabled: extensionInstance.isEnabled))

        // 重新加载插件
        loadExtensions()
        loadExtensionList()
        saveExtensionList()
    }

    func removeExtension(foldName: String) {
        extensions.removeValue(forKey: foldName)
        extensionList = extensionList.filter { $0.name != foldName }
        saveExtensionList()
    }

    // MARK: - 卸载插件

    func uninstall(extension: Extension) throws {
        let extensionsDirectory = getExtensionsDirectory()

        // 检查目录是否存在
        guard FileManager.default.fileExists(atPath: extensionsDirectory.path) else {
            throw Extension.ExtensionError.fileWriteFailed("Extensions directory does not exist.")
        }

        // 获取插件名称并生成插件目录名称
        guard let name = `extension`.name else {
            throw Extension.ExtensionError.missingRequiredField("name")
        }
        let sanitizedName = name.replacingOccurrences(of: " ", with: "-")

        // 查找匹配的插件目录
        let existingPluginDirectories = try FileManager.default.contentsOfDirectory(atPath: extensionsDirectory.path)
        for existingDirectory in existingPluginDirectories {
            if existingDirectory.hasPrefix("\(sanitizedName)."), existingDirectory.hasSuffix(".xpopext") {
                // 找到匹配的插件目录
                let pluginDirectory = extensionsDirectory.appendingPathComponent(existingDirectory)

                // 删除插件目录
                try FileManager.default.removeItem(at: pluginDirectory)

                logger.log("Uninstalled plugin at: %{public}", pluginDirectory.path, type: .info)

                // 重新加载插件
                loadExtensions()
                return
            }
        }

        // 如果没有找到匹配的插件目录
        throw Extension.ExtensionError.fileWriteFailed("Extension with name '\(name)' not found.")
    }
}

enum BuiltInAction {
    static let actions: [String: () -> Void] = [
        "Translate": {
            Task { @MainActor in
                let winManager = AppDelegate.shared
                winManager.hideWindow_new()

                var selectedText: String?
                selectedText = winManager.selectedText
                winManager.panelManager.showPanel(query: selectedText!)
            }
        },
        "Copy": {
            Task {
                let kbManager = KeyboardManager.shared
                let winManager = AppDelegate.shared
                await winManager.hideWindow_new()
                kbManager.simulateKeyPress(from: "command c")
            }
        },
        "Cut": {
            Task {
                let kbManager = KeyboardManager.shared
                let winManager = AppDelegate.shared
                await winManager.hideWindow_new()
                kbManager.simulateKeyPress(from: "command x")
            }
        },
        "Paste": {
            Task {
                let kbManager = KeyboardManager.shared
                let winManager = AppDelegate.shared
                await winManager.hideWindow_new()
                kbManager.simulateKeyPress(from: "command v")
            }
        },
    ]
}

class ShellScriptExecutor {
    static let shared = ShellScriptExecutor() // 单例实例
    private let fileManager = FileManager.default

    private init() {} // 防止外部初始化

    // MARK: - 运行 Shell 脚本

    func runShellScript(script: String?, scriptFile: String?, extensionName: String?) async throws -> String {
        // 获取软件名称
        guard let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String else {
            throw ShellScriptError.appNameNotFound
        }

        // 检查插件名称
        guard let extensionName = extensionName else {
            throw ShellScriptError.extensionNameMissing
        }

        // 获取 Application Support 目录
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let extensionsDirectory = appSupportURL
            .appendingPathComponent(appName)
            .appendingPathComponent("Extensions")
            .appendingPathComponent(extensionName)

        // 切换到插件目录
        let currentDirectory = fileManager.currentDirectoryPath
        defer {
            fileManager.changeCurrentDirectoryPath(currentDirectory)
        }

        let directoryChangeSuccess = fileManager.changeCurrentDirectoryPath(extensionsDirectory.path)
        if !directoryChangeSuccess {
            throw ShellScriptError.directoryChangeFailed(
                path: extensionsDirectory.path,
                error: NSError(
                    domain: "FileManagerError",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to change directory"]
                )
            )
        }

        // 读取脚本内容
        let scriptContent: String
        if let script = script {
            scriptContent = script
        } else if let scriptFile = scriptFile {
            let scriptURL = extensionsDirectory.appendingPathComponent(scriptFile)
            do {
                scriptContent = try String(contentsOf: scriptURL, encoding: .utf8)
            } catch {
                throw ShellScriptError.scriptFileReadFailed(path: scriptURL.path, error: error)
            }
        } else {
            throw ShellScriptError.scriptNotFound
        }

        // 执行脚本
        return try await executeShellScript(script: scriptContent)
    }

    // MARK: - 执行 Shell 脚本

    private func executeShellScript(script: String) async throws -> String {
        let process = Process()
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", script]

        // 设置输出管道
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        // 启动进程
        process.launch()

        // 等待进程结束
        process.waitUntilExit()

        // 读取输出
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: outputData, encoding: .utf8) else {
            throw ShellScriptError.outputDecodingFailed
        }

        // 检查执行结果
        if process.terminationStatus != 0 {
            throw ShellScriptError.scriptExecutionFailed(exitCode: process.terminationStatus, output: output)
        }

        return output
    }
}

enum ShellScriptError: Error {
    case appNameNotFound
    case extensionNameMissing
    case directoryChangeFailed(path: String, error: Error)
    case scriptFileReadFailed(path: String, error: Error)
    case scriptNotFound
    case outputDecodingFailed
    case scriptExecutionFailed(exitCode: Int32, output: String)
}
