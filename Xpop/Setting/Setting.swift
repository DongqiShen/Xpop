//
//  Setting.swift
//  Xpop
//
//  Created by Dongqi Shen on 2025/1/8.
//

import SwiftUI

struct SettingView: View {
    @EnvironmentObject var manager: ProviderManager // 自动获取注入的实例

    @State var chosenProviderId: String = UserDefaults.standard.string(forKey: "chosenProviderId") ?? ""
    @State var chosenProviderName: String = UserDefaults.standard.string(forKey: "chosenProviderName") ?? ""
    @State var chosenModels: [String] = UserDefaults.standard.stringArray(forKey: "chosenModels") ?? [""]
    @State var chosenModel: String = UserDefaults.standard.string(forKey: "chosenModel") ?? ""
    @State var enableForceCopy: Bool = UserDefaults.standard.bool(forKey: "enableForceCopy")
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject var settingManager = SettingsManager.shared

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.locale) var locale

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    let avaliableLanguage = languageManager.getAvailableLanguages()
                    SettingsPickerRow(
                        title: "Language",
                        options: avaliableLanguage,
                        chosenOption: $languageManager.selectedLanguage
                    )

                    NavigationLink(destination: ManageForbiddenAppView().environment(
                        \.locale,
                        languageManager.currentLocale
                    )) {
                        SettingsRow(title: "Forbidden Apps", detail: "")
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(Color(NSColor.labelColor))

                    SettingsToggleRow(title: "Enable Force Select Text", isOn: $enableForceCopy)
                } header: {
                    Text("General")
                }

                Section {
                    let providers: [String: String] = Dictionary(uniqueKeysWithValues: manager.providers.map { (
                        $0.id,
                        $0.name
                    ) })
                    SettingsModelProviderRow(
                        title: "Provider",
                        selections: providers,
                        selectedId: $chosenProviderId,
                        selectedProvider: $chosenProviderName,
                        selectedModels: $chosenModels,
                        selectedModel: $chosenModel
                    )
                    let models = manager.getProvider(by: chosenProviderId)?.supportedModels
                    SettingsPickerRow(title: "Model Name", options: models, chosenOption: $chosenModel)

                    NavigationLink(destination: ManageModelView().environment(
                        \.locale,
                        languageManager.currentLocale
                    )) {
                        SettingsRow(title: "Manage...", detail: "")
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(Color(NSColor.labelColor))
                } header: {
                    Text("Model")
                }

                Section {
                    NavigationLink(destination: ExtensionManagerView().environment(
                        \.locale,
                        languageManager.currentLocale
                    )) {
                        SettingsRow(title: "Extension...", detail: "")
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(Color(NSColor.labelColor))
                } header: {
                    Text("Extensions")
                }
            }
            .navigationTitle(Text("Settings")) // Use a predefined style)
            .formStyle(.grouped)
        }
        .environment(\.locale, languageManager.currentLocale) // 设置语言环境
        .onChange(of: chosenProviderId) {
            UserDefaults.standard.set(chosenProviderId, forKey: "chosenProviderId")
        }
        .onChange(of: chosenProviderName) {
            UserDefaults.standard.set(chosenProviderName, forKey: "chosenProviderName")
        }
        .onChange(of: chosenModels) {
            UserDefaults.standard.set(chosenModels, forKey: "chosenModels")
        }
        .onChange(of: chosenModel) {
            UserDefaults.standard.set(chosenModel, forKey: "chosenModel")
        }
        .onChange(of: enableForceCopy) {
            UserDefaults.standard.set(enableForceCopy, forKey: "enableForceCopy")
        }
        .onChange(of: languageManager.selectedLanguage) { newLanguage in
            languageManager.setLanguage(to: newLanguage)
        }
    }
}

struct SettingsRow: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    var isToggle: Bool = false

    @Environment(\.locale) var locale

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            Spacer()
            if detail != LocalizedStringKey("") {
                Text(detail)
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct SettingsToggleRow: View {
    let title: LocalizedStringKey
    @Binding var isOn: Bool

    @Environment(\.locale) var locale

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle())
                .labelsHidden()
        }
    }
}

struct SettingsModelProviderRow: View {
    let title: LocalizedStringKey
    @EnvironmentObject var manager: ProviderManager // 自动获取注入的实例
    var selections: [String: String]
    @Binding var selectedId: String
    @Binding var selectedProvider: String
    @Binding var selectedModels: [String]
    @Binding var selectedModel: String

    @Environment(\.locale) var locale

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            Spacer()
            // 下拉菜单
            Picker("", selection: $selectedId) {
                ForEach(Array(selections.keys), id: \.self) { key in
                    Text(selections[key]!).tag(key)
                }
            }
            .pickerStyle(MenuPickerStyle()) // 使用下拉菜单样式
            .frame(width: 150) // 调整宽度
            .onChange(of: selectedId) { newValue in
                // 当 selectedId 改变时更新 selectedProvider
                selectedProvider = selections[newValue] ?? ""
                selectedModels = manager.getProvider(by: newValue)?.supportedModels ?? [""]
                selectedModel = selectedModels[0]
            }
        }
    }
}

struct SettingsPickerRow: View {
    let title: LocalizedStringKey
    let options: [String]?
    @Binding var chosenOption: String

    @Environment(\.locale) var locale

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            Spacer()

            if let options = options, !options.isEmpty {
                Picker("", selection: $chosenOption) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 150)
            } else {
                Text("No options available")
                    .foregroundColor(.gray)
                    .frame(width: 150, alignment: .trailing)
            }
        }
    }
}

#Preview {
    SettingView()
}
