//
//  Icon.swift
//  Xpop
//
//  Created by Dongqi Shen on 2025/1/8.
//

import SwiftUI

struct CustomImage: View {
    let extName: String
    let iconString: String
    let size: CGFloat
    let cornerRadius: CGFloat = 8

    @Environment(\.colorScheme) private var colorScheme

    init(extName: String, iconString: String, size: CGFloat = 30) {
        self.extName = extName
        self.iconString = iconString
        self.size = size
    }

    private var parsedModifiers: [String: String] {
        let components = iconString.components(separatedBy: " ")
        var modifiers: [String: String] = [:]
        for component in components {
            if component.hasPrefix("symbol:") {
                modifiers["symbol"] = String(component.dropFirst("symbol:".count))
            } else if component.hasPrefix("iconify:") {
                // 处理 iconify 格式
                let iconifyValue = String(component.dropFirst("iconify:".count))
                modifiers["iconify"] = iconifyValue
            } else if component.contains("=") {
                let parts = component.components(separatedBy: "=")
                modifiers[parts[0]] = parts[1]
            } else {
                modifiers[component] = "true"
            }
        }
        return modifiers
    }

    private var iconText: String {
        let components = iconString.components(separatedBy: " ")
        let textComponents = components.filter { !$0.hasPrefix("symbol:") && !$0.contains("=") }
        return String(textComponents.last?.prefix(8) ?? "")
    }

    private var isSFSymbol: Bool {
        parsedModifiers["symbol"] != nil
    }

    private var sfSymbolName: String {
        parsedModifiers["symbol"] ?? ""
    }

    private var isPNGImage: Bool {
        iconString.contains(".png")
    }

    private var isSVGImage: Bool {
        parsedModifiers["iconify"] != nil
    }

    private var pngImageName: String {
        let components = iconString.components(separatedBy: " ")
        return components.first { $0.contains(".png") } ?? ""
    }

    private var svgImageName: String {
        parsedModifiers["iconify"] ?? ""
    }

    private var backgroundShape: some View {
        if parsedModifiers["circle"] == "true" {
            if parsedModifiers["filled"] == "true" {
                AnyView(Circle().fill(filledBackgroundColor))
            } else {
                AnyView(Circle().stroke(Color.primary, lineWidth: 2))
            }
        } else if parsedModifiers["square"] == "true" {
            if parsedModifiers["filled"] == "true" {
                AnyView(RoundedRectangle(cornerRadius: cornerRadius).fill(filledBackgroundColor))
            } else {
                AnyView(RoundedRectangle(cornerRadius: cornerRadius).stroke(Color.primary, lineWidth: 2))
            }
        } else {
            AnyView(RoundedRectangle(cornerRadius: cornerRadius).fill(Color.clear))
        }
    }

    private var filledBackgroundColor: Color {
        colorScheme == .light ? .white : .black
    }

    private var filledTextColor: Color {
        colorScheme == .light ? .black : .white
    }

    private var strikeLineColor: Color {
        colorScheme == .light ? (parsedModifiers["filled"] == "true" ? filledTextColor : Color.primary) : .white
    }

    private var strikeBorderColor: Color {
        colorScheme == .light ? .white : .black
    }

    private var iconContent: some View {
        if isPNGImage || isSVGImage {
            let imageName = isPNGImage ? pngImageName : svgImageName.replacingOccurrences(of: ":", with: "-")
            return AnyView(
                loadImage(imageName: imageName)
                    .renderingMode(.template) // 正确应用于 Image
                    .resizable()
                    .scaledToFit()
                    .frame(width: size - 5, height: size - 5)
                    .foregroundStyle(.primary) // 使用系统主色
            )
        } else if parsedModifiers["search"] == "true" {
            return AnyView(
                Image(systemName: "magnifyingglass")
                    .font(.system(size: size * 0.5, weight: .bold))
            )
        } else if isSFSymbol {
            return AnyView(
                Image(systemName: sfSymbolName)
                    .font(.system(size: size * 0.5, weight: .bold))
            )
        } else {
            return AnyView(
                Text(iconText)
                    .font(parsedModifiers["monospaced"] == "true" ?
                        .system(size: size * 0.5, weight: .bold, design: .monospaced) :
                        .system(size: size * 0.5, weight: .bold, design: .default))
            )
        }
    }

    private func loadImage(imageName: String) -> Image {
        // 假设 loadImageFromFileSystem 函数可以处理 PNG 和 SVG 图像
        return Image(nsImage: loadImageFromFileSystem(imageName: imageName))
    }

    private var strikeLine: some View {
        if parsedModifiers["strike"] == "true" {
            AnyView(
                ZStack {
                    DiagonalStrikeLine()
                        .stroke(strikeBorderColor, lineWidth: 4)
                    DiagonalStrikeLine()
                        .stroke(strikeLineColor, lineWidth: 2)
                }
                .frame(width: size * 0.8, height: size * 0.8)
            )
        } else {
            AnyView(EmptyView())
        }
    }

    private var scale: CGFloat {
        CGFloat((parsedModifiers["scale"] ?? "100").toDouble() ?? 100) / 100
    }

    private var rotation: Double {
        parsedModifiers["rotate"]?.toDouble() ?? 0
    }

    private var moveX: CGFloat {
        CGFloat(parsedModifiers["move-x"]?.toDouble() ?? 0)
    }

    private var moveY: CGFloat {
        CGFloat(parsedModifiers["move-y"]?.toDouble() ?? 0)
    }

    private var flipX: Bool {
        parsedModifiers["flip-x"] == "true"
    }

    private var flipY: Bool {
        parsedModifiers["flip-y"] == "true"
    }

    var body: some View {
        ZStack {
            backgroundShape
            iconContent
            strikeLine
        }
        .frame(width: size, height: parsedModifiers["preserve-aspect"] != nil ? nil : size)
        .aspectRatio(parsedModifiers["preserve-aspect"] != nil ? nil : 1, contentMode: .fit)
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .offset(x: moveX, y: moveY)
        .flipped(horizontal: flipX, vertical: flipY)
    }

    private func loadImageFromFileSystem(imageName: String) -> NSImage {
        // 获取应用程序名称
        guard let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String else {
            print("Failed to get application name from Bundle.")
            return NSImage(named: "default_image") ?? NSImage()
        }

        // 获取 Application Support 目录
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
        else {
            print("Failed to get Application Support directory.")
            return NSImage(named: "default_image") ?? NSImage()
        }

        // 构建完整的插件目录路径
        let extensionsDir = appSupportURL.appendingPathComponent("\(appName)/Extensions")

        guard let pluginDirName = ExtensionManager.shared.getExtensionDir(name: extName) else {
            print("Failed to get plugin directory name for: \(extName)")
            return NSImage(named: "default_image") ?? NSImage()
        }

        let pluginDir = extensionsDir.appendingPathComponent(pluginDirName)
        var imageURL = pluginDir.appendingPathComponent(imageName)

        print("Loading image from path: \(imageURL.path)")
        if isSVGImage {
            if FileManager.default.fileExists(atPath: imageURL.path) {
                // 如果本地存在图片，直接加载并返回
                if let image = NSImage(contentsOf: imageURL) {
                    image.isTemplate = true // 启用模板模式
                    return image
                } else {
                    print("Failed to load image from path: \(imageURL.path)")
                }
            } else {
                // 如果本地不存在图片，尝试下载
                if let downloadedImageURL = downloadIconifyIcon(svgImageName) {
                    // 下载成功后，加载图片并返回
                    if let image = NSImage(contentsOf: downloadedImageURL) {
                        image.isTemplate = true // 启用模板模式
                        return image
                    } else {
                        print("Failed to load downloaded image")
                    }
                } else {
                    print("Failed to download image")
                }
            }
        } else if let image = NSImage(contentsOf: imageURL) {
            image.isTemplate = true // 关键：启用模板模式
            return image
        } else {
            print("Failed to load image from path: \(imageURL.path)")
        }

        // 如果加载失败，返回一个默认图片
        return NSImage(named: "default_image") ?? NSImage()
    }

    /// 下载 Iconify 图标到指定文件夹
    /// - Parameter iconifyValue: 格式为 `<icon set prefix>:<icon name>`，例如 "mdi:home"
    /// - Returns: 下载的图标文件路径，如果下载失败则返回 nil
    private func downloadIconifyIcon(_ iconifyValue: String) -> URL? {
        // 解析 iconifyValue
        let components = iconifyValue.components(separatedBy: ":")
        guard components.count == 2 else {
            print("Invalid iconify value format: \(iconifyValue)")
            return nil
        }

        let iconSetPrefix = components[0]
        let iconName = components[1]

        // Iconify CDN URL
        let iconifyURLString = "https://api.iconify.design/\(iconSetPrefix)/\(iconName).svg"
        guard let iconifyURL = URL(string: iconifyURLString) else {
            print("Invalid URL: \(iconifyURLString)")
            return nil
        }

        // 获取 Application Support 目录
        guard let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String,
              let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("Failed to get Application Support directory.")
            return nil
        }

        // 构建完整的插件目录路径
        let extensionsDir = appSupportURL.appendingPathComponent("\(appName)/Extensions")

        guard let pluginDirName = ExtensionManager.shared.getExtensionDir(name: extName) else {
            print("Failed to get plugin directory name for: \(extName)")
            return nil
        }

        let pluginDir = extensionsDir.appendingPathComponent(pluginDirName)

        // 确保插件目录存在
        do {
            try FileManager.default.createDirectory(at: pluginDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create plugin directory: \(error)")
            return nil
        }

        // 图标文件路径
        let iconFileName = "\(iconSetPrefix)-\(iconName).svg"
        let iconFileURL = pluginDir.appendingPathComponent(iconFileName)

        // 使用信号量等待下载完成
        let semaphore = DispatchSemaphore(value: 0)
        var downloadedURL: URL?

        let task = URLSession.shared.dataTask(with: iconifyURL) { data, _, error in
            defer { semaphore.signal() }

            if let error = error {
                print("Failed to download icon: \(error)")
                return
            }

            guard let data = data else {
                print("No data returned.")
                return
            }

            // 将下载的数据保存到文件
            do {
                if FileManager.default.fileExists(atPath: iconFileURL.path) {
                    try FileManager.default.removeItem(at: iconFileURL)
                }
                try data.write(to: iconFileURL)
                print("Icon downloaded and saved to: \(iconFileURL.path)")
                downloadedURL = iconFileURL
            } catch {
                print("Failed to save downloaded icon: \(error)")
            }
        }

        task.resume()
        semaphore.wait()

        return downloadedURL
    }

}

extension String {
    func toDouble() -> Double? {
        Double(self)
    }
}

struct DiagonalStrikeLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

extension View {
    func flipped(horizontal: Bool, vertical: Bool) -> some View {
        scaleEffect(x: horizontal ? -1 : 1, y: vertical ? -1 : 1, anchor: .center)
    }
}
