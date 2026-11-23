//
//  ContentView.swift
//  Reiah
//
//  Created by roy on 2026/11/3.
//

import Foundation
import LocalAuthentication
import Photos
import SwiftUI
import UIKit

// MARK: - 主题色（自适应深色模式）

extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    /// 随系统深浅色切换的颜色
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor {
            $0.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light)
        })
    }

    /// 页面渐变底色
    static let themeBgTop = Color.adaptive(light: 0xF2F6FF, dark: 0x0D1424)
    static let themeBgBottom = Color.adaptive(light: 0xE1EAFF, dark: 0x060A14)

    /// 正文色
    static let themeInk = Color.adaptive(light: 0x0D1F3D, dark: 0xFFFFFF)

    /// 关于页星点色
    static let themeStar = Color.adaptive(light: 0x3D82E0, dark: 0xFFFFFF)

    /// 主题品牌蓝
    static let themeAccent = Color(red: 0.0, green: 0.42, blue: 0.86)

    /// 极光背景的九宫格渐变色
    static let aurora: [Color] = [
        Color.adaptive(light: 0xEDF3FF, dark: 0x101A2E),
        Color.adaptive(light: 0xE4EDFF, dark: 0x0C1526),
        Color.adaptive(light: 0xF0EEFF, dark: 0x131A31),
        Color.adaptive(light: 0xE2EBFF, dark: 0x0A1120),
        Color.adaptive(light: 0xF5F8FF, dark: 0x0E1728),
        Color.adaptive(light: 0xE7F0FF, dark: 0x151D34),
        Color.adaptive(light: 0xEDF2FF, dark: 0x080D1A),
        Color.adaptive(light: 0xDFE9FF, dark: 0x0C1322),
        Color.adaptive(light: 0xF2F6FF, dark: 0x0A101E)
    ]
}

// MARK: - 主页

struct ContentView: View {
    @Namespace private var zoom
    @State private var appeared = false
    @State private var landed = false

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()

                ScrollView {
                    VStack(spacing: 30) {
                        hero
                        featureButtons
                        aboutLink
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 44)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                appeared = true
                Task {
                    try? await Task.sleep(for: .seconds(0.85))
                    landed = true
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: landed)
        }
    }

    // MARK: 头部

    private var hero: some View {
        VStack(spacing: 18) {
            AppMark(size: 94)
                .scaleEffect(appeared ? 1 : 0.78)
                .reveal(appeared, delay: 0)

            VStack(spacing: 7) {
                Text("玄武查")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Color.themeInk)

                Text("海尔学校 · 信息查询工具")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
            }
            .reveal(appeared, delay: 0.07)
        }
    }

    // MARK: 功能按钮

    private var featureButtons: some View {
        GlassEffectContainer(spacing: 18) {
            VStack(spacing: 18) {
                card(
                    title: "查学号",
                    subtitle: "输入姓名查询学号信息",
                    systemImage: "person.text.rectangle",
                    accent: Color(red: 0.0, green: 0.42, blue: 0.86),
                    id: "stu"
                ) {
                    StudentIdLookupView()
                }
                .reveal(appeared, delay: 0.15)

                card(
                    title: "查档",
                    subtitle: "通过学号查询学生档案",
                    systemImage: "doc.text.magnifyingglass",
                    accent: Color(red: 0.35, green: 0.60, blue: 0.90),
                    id: "arch"
                ) {
                    ArchiveLookupView()
                }
                .reveal(appeared, delay: 0.23)

                card(
                    title: "加密钱包",
                    subtitle: "解析链上地址的多链资产",
                    systemImage: "wallet.bifold.fill",
                    accent: Color(red: 0.42, green: 0.32, blue: 0.85),
                    id: "wallet"
                ) {
                    WalletLookupView()
                }
                .reveal(appeared, delay: 0.31)
            }
        }
    }

    private func card<Destination: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        accent: Color,
        id: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
                .navigationTransition(.zoom(sourceID: id, in: zoom))
        } label: {
            FeatureCard(title: title, subtitle: subtitle, systemImage: systemImage, accent: accent)
        }
        .buttonStyle(PressableCardStyle())
        .matchedTransitionSource(id: id, in: zoom)
    }

    private var aboutLink: some View {
        NavigationLink {
            AboutView()
                .navigationTransition(.zoom(sourceID: "about", in: zoom))
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.semibold))
                    .symbolEffect(.pulse, options: .repeating.speed(0.4))

                Text("关于")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .glassEffect(.regular, in: .capsule)
        }
        .buttonStyle(PressableCardStyle())
        .matchedTransitionSource(id: "about", in: zoom)
        .reveal(appeared, delay: 0.39)
    }
}

// MARK: - 极光背景

private struct AuroraBackground: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    .init(0, 0), .init(0.5, 0), .init(1, 0),
                    .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
                    .init(0, 1), .init(0.5, 1), .init(1, 1)
                ],
                colors: Color.aurora
            )

            blob(Color(red: 0.0, green: 0.42, blue: 0.86), size: 340, blur: 110, opacity: 0.20)
                .offset(x: drift ? 150 : 90, y: drift ? -230 : -320)

            blob(Color(red: 0.35, green: 0.72, blue: 1.0), size: 300, blur: 120, opacity: 0.17)
                .offset(x: drift ? -140 : -80, y: drift ? 250 : 330)

            blob(Color(red: 0.42, green: 0.45, blue: 0.95), size: 260, blur: 130, opacity: 0.13)
                .offset(x: drift ? 40 : -30, y: drift ? 60 : -10)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 16).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func blob(_ color: Color, size: CGFloat, blur: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(color.opacity(opacity))
            .frame(width: size, height: size)
            .blur(radius: blur)
    }
}

// MARK: - App 图标

private struct AppMark: View {
    let size: CGFloat

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
    }

    var body: some View {
        // TimelineView 驱动：光在整个图标表面缓慢流动。
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            // 两层光斑各自沿不同方向缓慢漂移，叠加后形成"光在表面游走"的效果。
            let x1 = sin(t * 0.45) * size * 0.6
            let y1 = cos(t * 0.38) * size * 0.6
            let x2 = cos(t * 0.55) * size * 0.6
            let y2 = sin(t * 0.5) * size * 0.6

            ZStack {
                // 底色
                shape
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.0, green: 0.24, blue: 0.55), Color(red: 0.0, green: 0.42, blue: 0.86)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // 顶部内高光（静态玻璃感）
                shape
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.28), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )

                // 流动光层 1：大面积柔光，从左上漂向右下
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.55), .white.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.7
                        )
                    )
                    .frame(width: size * 1.2, height: size * 1.2)
                    .offset(x: x1, y: y1)
                    .blur(radius: 6)
                    .blendMode(.plusLighter)
                    .mask(shape)

                // 流动光层 2：较亮的小光斑，反向漂移
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.7), .white.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.45
                        )
                    )
                    .frame(width: size * 0.9, height: size * 0.9)
                    .offset(x: x2, y: y2)
                    .blur(radius: 4)
                    .blendMode(.plusLighter)
                    .mask(shape)

                // 图标
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: size * 0.46, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
            }
            .frame(width: size, height: size)
            .clipShape(shape)
            .shadow(color: Color(red: 0.0, green: 0.3, blue: 0.7).opacity(0.36), radius: 24, y: 14)
        }
    }
}

// MARK: - 功能卡片

private struct FeatureCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accent, accent.opacity(0.78)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                    .shadow(color: accent.opacity(0.32), radius: 12, y: 6)

                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.themeInk)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 26))
    }
}

// MARK: - 动效辅助

private extension View {
    /// 入场动画：淡入 + 上浮，支持按 delay 错峰。
    func reveal(_ appeared: Bool, delay: Double) -> some View {
        opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .animation(.spring(response: 0.9, dampingFraction: 0.86).delay(delay), value: appeared)
    }
}

private struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .brightness(configuration.isPressed ? 0.03 : 0)
            .animation(.spring(response: 0.32, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

// MARK: - 查学号

struct StudentRecord: Codable, Identifiable, Hashable {
    let name: String
    let studentId: String

    var id: String { studentId }
}

/// 本地学生名单（姓名 → 学号），数据来自 Students.json。
enum StudentDirectory {
    static let all: [StudentRecord] = load()

    static func search(name: String) -> [StudentRecord] {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return [] }

        let exact = all.filter { $0.name == key }
        if !exact.isEmpty { return exact }

        return all.filter { $0.name.contains(key) }
    }

    private static func load() -> [StudentRecord] {
        guard
            let url = Bundle.main.url(forResource: "Students", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let records = try? JSONDecoder().decode([StudentRecord].self, from: data)
        else {
            return []
        }
        return records
    }
}

struct StudentIdLookupView: View {
    @State private var name: String = ""
    @State private var matches: [StudentRecord] = []
    @State private var searched = false
    @FocusState private var focused: Bool

    private let accentBlue = Color(red: 0.0, green: 0.42, blue: 0.86)

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                inputCard(
                    title: "姓名",
                    placeholder: "请输入学生姓名",
                    systemImage: "person.fill",
                    text: $name,
                    focused: $focused
                )

                queryButton(title: "查询学号", isLoading: false, action: { search() })
                    .disabled(!canSubmit)

                if searched {
                    if matches.isEmpty {
                        emptyCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        ForEach(matches) { record in
                            StudentResultCard(record: record)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity))
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(backgroundGradient.ignoresSafeArea())
        .navigationTitle("查学号")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: matches)
        .scrollDismissesKeyboard(.interactively)
    }

    private var emptyCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)

            Text("未找到该学生")
                .font(.headline)

            Text("请检查姓名是否正确，目前仅收录 H2025 开头的学号。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 16, y: 8)
    }

    private func search() {
        focused = false
        matches = StudentDirectory.search(name: name)
        searched = true
    }
}

/// 单条查询结果：姓名 + 学号（可长按复制）。
private struct StudentResultCard: View {
    let record: StudentRecord

    @State private var copied = false

    private let accentBlue = Color(red: 0.0, green: 0.42, blue: 0.86)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(red: 0.13, green: 0.6, blue: 0.36))
                    .symbolEffect(.bounce)

                Text(record.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.themeInk)

                Spacer()

                Button {
                    UIPasteboard.general.string = record.studentId
                    copied = true
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        copied = false
                    }
                } label: {
                    Label(copied ? "已复制" : "复制", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(accentBlue)
                }
                .buttonStyle(.plain)
            }

            Divider()

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("学号")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .leading)

                Text(record.studentId)
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .foregroundStyle(accentBlue)
                    .textSelection(.enabled)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 16, y: 8)
    }
}

// MARK: - 查档

struct ArchiveLookupView: View {
    @State private var studentId: String = ""
    @State private var resultText: String = ""
    @State private var httpStatus: Int?
    @State private var isLoading: Bool = false
    @State private var profile: ArchiveProfile?
    @State private var isRenderingSnapshot = false
    @State private var previewImage: UIImage?
    @State private var showPreview = false
    @State private var saveAlertMessage = ""
    @State private var showSaveAlert = false
    @FocusState private var focused: Bool

    private let accentBlue = Color(red: 0.0, green: 0.42, blue: 0.86)

    private var canSubmit: Bool {
        !isLoading && !studentId.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                inputCard(
                    title: "学号",
                    placeholder: "请输入学号",
                    systemImage: "number",
                    text: $studentId,
                    focused: $focused
                )

                queryButton(title: "查询档案", isLoading: isLoading, action: { fetch() })
                    .disabled(!canSubmit)

                if let profile {
                    ArchiveProfileView(profile: profile, rawText: resultText)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity))

                    snapshotButton
                        .transition(.opacity)
                } else if !resultText.isEmpty {
                    ResultCard(resultText: resultText, httpStatus: httpStatus)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity))
                }
            }
            .padding(20)
        }
        .background(backgroundGradient.ignoresSafeArea())
        .navigationTitle("查档")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: resultText)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isLoading)
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showPreview) { snapshotPreview }
        .alert("提示", isPresented: $showSaveAlert) {
            Button("好", role: .cancel) {}
        } message: {
            Text(saveAlertMessage)
        }
    }

    // 档案截图按钮
    private var snapshotButton: some View {
        Button {
            Task { await makeSnapshot() }
        } label: {
            HStack(spacing: 8) {
                if isRenderingSnapshot {
                    ProgressView()
                        .tint(accentBlue)
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                }

                Text(isRenderingSnapshot ? "生成中…" : "预览并保存档案截图")
            }
            .font(.headline)
            .foregroundStyle(accentBlue)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(accentBlue.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(PressedButtonStyle())
        .disabled(isRenderingSnapshot)
    }

    private var snapshotPreview: some View {
        NavigationStack {
            ScrollView {
                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .padding(16)
                }
            }
            .background(Color(.secondarySystemBackground))
            .navigationTitle("档案截图预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("完成") { showPreview = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存到相册") { Task { await saveSnapshot() } }
                }
            }
        }
    }

    private func fetch() {
        focused = false
        Task {
            // 查询前先做 Face ID 验证。
            guard await BiometricGate.confirm(reason: "验证身份后查询学籍档案") else {
                profile = nil
                httpStatus = nil
                resultText = "Face ID 验证未通过，已取消查询。"
                return
            }

            await performRequest()
        }
    }

    /// 把档案渲染成一张图片，并弹出预览。
    private func makeSnapshot() async {
        guard let profile else { return }

        isRenderingSnapshot = true
        defer { isRenderingSnapshot = false }

        let photo = await ArchiveSnapshotRenderer.loadPhoto(profile.photoURL)

        guard let image = ArchiveSnapshotRenderer.render(profile: profile, photo: photo) else {
            saveAlertMessage = "截图生成失败，请重试"
            showSaveAlert = true
            return
        }

        previewImage = image
        showPreview = true
    }

    private func saveSnapshot() async {
        guard let previewImage else { return }

        do {
            try await ArchiveSnapshotRenderer.saveToPhotoLibrary(previewImage)
            saveAlertMessage = "已保存到相册"
        } catch {
            saveAlertMessage = "保存失败：\(error.localizedDescription)"
        }

        showSaveAlert = true
    }

    private func performRequest() async {
        isLoading = true
        profile = nil
        defer { isLoading = false }

        let account = studentId.trimmingCharacters(in: .whitespaces)
        guard !account.isEmpty else { return }

        do {
            // 1. 先取登录会话（token + userId）；本地已有则直接复用，不再发登录请求。
            var session: LoginSession
            if let cached = SessionStore.session(for: account) {
                session = cached
            } else {
                session = try await login(for: account)
            }

            // 2. 用登录返回的 userId 查档。
            var archiveResult = try await requestArchive(userId: session.userId, token: session.token)

            // 3. 只有服务端明确拒绝当前 token 时才重新登录一次，再查一次。
            if archiveResult.tokenExpired {
                session = try await login(for: account)
                archiveResult = try await requestArchive(userId: session.userId, token: session.token)
            }

            // 4. 重新登录后仍失败，则直接返回请求报错信息。
            guard archiveResult.isSuccess else {
                throw ArchiveRequestError.response(
                    statusCode: archiveResult.statusCode,
                    body: archiveResult.body
                )
            }

            httpStatus = archiveResult.statusCode
            resultText = archiveResult.body
            profile = ArchiveProfile.parse(from: Data(archiveResult.body.utf8))
        } catch {
            profile = nil
            httpStatus = (error as? ArchiveRequestError)?.statusCode
            resultText = "请求失败：\(error.localizedDescription)"
        }
    }

    /// 调用 /login，解析出 token 与 userId，并按账号缓存到本地。
    private func login(for account: String) async throws -> LoginSession {
        var request = URLRequest(url: URL(string: "https://portal.haierschool.cn/v/login")!)
        request.httpMethod = "POST"
        request.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("3", forHTTPHeaderField: "sysType")
        request.setValue("false", forHTTPHeaderField: "isToken")
        request.timeoutInterval = 60

        let body: [String: String] = [
            "username": account,
            "password": "HS123456",
            "sysType": "3"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode

            guard (200..<300).contains(statusCode ?? -1), let session = SessionStore.session(from: data) else {
                let responseBody = String(data: data, encoding: .utf8) ?? "<无法解析响应>"
                throw ArchiveRequestError.response(statusCode: statusCode, body: responseBody)
            }

            SessionStore.save(session: session, for: account)
            return session
        } catch let error as ArchiveRequestError {
            throw error
        } catch {
            throw ArchiveRequestError.message(error.localizedDescription)
        }
    }

    private func requestArchive(userId: String, token: String) async throws -> ArchiveResult {
        var components = URLComponents(string: "https://portal.haierschool.cn/v/stuArchives/getStudentArchive")!
        components.queryItems = [URLQueryItem(name: "userId", value: userId)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("3", forHTTPHeaderField: "sysType")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            let body = String(data: data, encoding: .utf8) ?? "<无法解析响应>"
            return ArchiveResult(
                statusCode: statusCode,
                body: body,
                tokenExpired: statusCode == 401 || statusCode == 403 || SessionStore.responseIndicatesExpired(data)
            )
        } catch {
            throw ArchiveRequestError.message(error.localizedDescription)
        }
    }
}

private struct ArchiveResult {
    let statusCode: Int?
    let body: String
    let tokenExpired: Bool

    var isSuccess: Bool {
        guard let statusCode else { return false }
        return (200..<300).contains(statusCode)
    }
}

private enum ArchiveRequestError: LocalizedError {
    case response(statusCode: Int?, body: String)
    case message(String)

    var statusCode: Int? {
        if case let .response(statusCode, _) = self { return statusCode }
        return nil
    }

    var errorDescription: String? {
        switch self {
        case let .response(statusCode, body):
            return "HTTP \(statusCode.map(String.init) ?? "未知")\n\(body)"
        case let .message(message):
            return message
        }
    }
}

/// 登录结果：查档所需的 token 与 userId（均来自 /login 响应）。
private struct LoginSession: Codable {
    let token: String
    let userId: String
}

/// 按账号缓存登录会话，避免每次查档都重新登录。
private enum SessionStore {
    private static let prefix = "xuanwu.session."

    static func session(for account: String) -> LoginSession? {
        guard
            let data = UserDefaults.standard.data(forKey: prefix + account),
            let session = try? JSONDecoder().decode(LoginSession.self, from: data)
        else {
            return nil
        }
        return session
    }

    static func save(session: LoginSession, for account: String) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        UserDefaults.standard.set(data, forKey: prefix + account)
    }

    /// 从 /login 响应中解析 token 与 userId。
    static func session(from data: Data) -> LoginSession? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            let dictionary = object as? [String: Any],
            let token = findToken(in: dictionary),
            let userId = findUserId(in: dictionary)
        else {
            return nil
        }

        return LoginSession(token: token, userId: userId)
    }

    static func responseIndicatesExpired(_ data: Data) -> Bool {
        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            let dictionary = object as? [String: Any]
        else {
            return false
        }

        let code = dictionary["code"] as? Int ?? Int(dictionary["code"] as? String ?? "")
        if code == 401 || code == 403 { return true }

        let message = (dictionary["msg"] as? String ?? dictionary["message"] as? String ?? "").lowercased()
        return message.contains("token") && (message.contains("invalid") || message.contains("expired"))
    }

    private static func findToken(in dictionary: [String: Any]) -> String? {
        for key in ["token", "access_token", "accessToken"] {
            if let token = dictionary[key] as? String, !token.isEmpty {
                return token
            }
        }

        for value in dictionary.values {
            if let nested = value as? [String: Any], let token = findToken(in: nested) {
                return token
            }
        }
        return nil
    }

    private static func findUserId(in dictionary: [String: Any]) -> String? {
        for key in ["userId", "userid", "user_id"] {
            if let string = dictionary[key] as? String, !string.isEmpty {
                return string
            }
            if let number = dictionary[key] as? NSNumber {
                return number.stringValue
            }
        }

        for key in ["data", "user", "userInfo"] {
            if let nested = dictionary[key] as? [String: Any], let userId = findUserId(in: nested) {
                return userId
            }
        }
        return nil
    }
}

// MARK: - 共享子视图

private var backgroundGradient: some View {
    LinearGradient(
        colors: [.themeBgTop, .themeBgBottom],
        startPoint: .top,
        endPoint: .bottom
    )
}

private func inputCard(
    title: String,
    placeholder: String,
    systemImage: String,
    text: Binding<String>,
    focused: FocusState<Bool>.Binding,
    monospaced: Bool = false
) -> some View {
    VStack(alignment: .leading, spacing: 10) {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)

        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(focused.wrappedValue ? Color(red: 0.0, green: 0.42, blue: 0.86) : .secondary)
                .frame(width: 20)

            TextField(placeholder, text: text)
                .font(monospaced ? .system(.body, design: .monospaced) : .body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .focused(focused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    focused.wrappedValue ? Color(red: 0.0, green: 0.42, blue: 0.86).opacity(0.55) : .clear,
                    lineWidth: 1.5
                )
        )
        .animation(.easeInOut(duration: 0.2), value: focused.wrappedValue)
    }
    .padding(18)
    .background(
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.regularMaterial)
    )
    .overlay(
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .strokeBorder(.white.opacity(0.5), lineWidth: 0.5)
    )
    .shadow(color: Color.black.opacity(0.06), radius: 16, y: 8)
}

private func queryButton(title: String, isLoading: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .tint(.white)
            }

            Text(isLoading ? "查询中…" : title)
        }
        .font(.headline)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(
            LinearGradient(
                colors: [Color(red: 0.0, green: 0.24, blue: 0.55), Color(red: 0.0, green: 0.42, blue: 0.86)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
        )
        .shadow(color: Color(red: 0.0, green: 0.3, blue: 0.7).opacity(0.3), radius: 16, y: 8)
        .opacity(isLoading ? 0.85 : 1)
    }
    .buttonStyle(PressedButtonStyle())
}

private struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

private struct ResultCard: View {
    let resultText: String
    let httpStatus: Int?

    private var statusSymbol: String {
        guard let httpStatus else { return "exclamationmark.triangle.fill" }
        return (200..<300).contains(httpStatus) ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    private var statusColor: Color {
        guard let httpStatus else { return .red }
        return (200..<300).contains(httpStatus) ? .green : .orange
    }

    private var statusTitle: String {
        guard let httpStatus else { return "请求失败" }
        return (200..<300).contains(httpStatus) ? "查询成功" : "服务端返回错误"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: statusSymbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(statusColor)

                Text(statusTitle)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                if let httpStatus {
                    Text("HTTP \(httpStatus)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(.tertiarySystemFill), in: Capsule())
                }
            }

            Divider()

            Text(resultText)
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(statusColor.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 18, y: 10)
    }
}

// MARK: - 学籍档案

struct ArchiveProfile {
    let photoURL: URL?
    let name: String
    let subtitle: String
    let tags: [String]
    let sections: [ArchiveSection]
}

struct ArchiveSection: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let rows: [ArchiveRow]
}

struct ArchiveRow: Identifiable {
    let id = UUID()
    let label: String
    let value: String
}

extension ArchiveProfile {
    /// 把 /stuArchives/getStudentArchive 的 JSON 整理成档案结构。
    static func parse(from data: Data) -> ArchiveProfile? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            let root = object as? [String: Any]
        else {
            return nil
        }

        let dict = (root["data"] as? [String: Any]) ?? root
        guard !dict.isEmpty else { return nil }

        func text(_ key: String) -> String? {
            if let value = dict[key] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
            if let value = dict[key] as? NSNumber, !(value is Bool) {
                return value.stringValue
            }
            return nil
        }

        func mapped(_ key: String, _ table: [String: String]) -> String? {
            guard let raw = text(key) else { return nil }
            return table[raw] ?? raw
        }

        func row(_ label: String, _ value: String?) -> ArchiveRow? {
            guard let value else { return nil }
            return ArchiveRow(label: label, value: value)
        }

        func rows(_ items: [ArchiveRow?]) -> [ArchiveRow] {
            items.compactMap { $0 }
        }

        let sex = mapped("stuSex", ["0": "男", "1": "女"])

        let sections = [
            ArchiveSection(title: "基本信息", systemImage: "person.text.rectangle", rows: rows([
                row("姓名", text("stuName")),
                row("性别", sex),
                row("出生日期", text("stuBirthday")),
                row("民族", text("stuNation")),
                row("籍贯", text("stuNativePlace")),
                row("出生地", text("stuBirthplace")),
                row("政治面貌", text("stuPoliticCountenance")),
                row("健康状况", text("stuHealthStatus")),
                row("宗教", text("stuReligion")),
                row("身高", text("stuHeight").map { "\($0) cm" }),
                row("体重", text("stuWeight").map { "\($0) kg" }),
                row("独生子女", mapped("stuIsOnlyChild", ["1": "是", "0": "否"])),
                row("身份证号", text("stuIdCard")),
                row("特长", text("stuSpecialSkill"))
            ])),
            ArchiveSection(title: "学籍信息", systemImage: "graduationcap.fill", rows: rows([
                row("学年", text("xn")),
                row("学号", text("xh") ?? text("stuSchoolRollCode")),
                row("班级", text("stuClassName")),
                row("学籍状态", text("stuBelongSchoolRollStatus")),
                row("在校状态", mapped("stuInSchoolStatus", ["1": "在读"])),
                row("入学时间", text("stuInSchoolStudyTime")),
                row("在校天数", text("joinDays").map { "\($0) 天" }),
                row("班主任", text("teacherName")),
                row("意向班级", text("intentionClassName"))
            ])),
            ArchiveSection(title: "学业成绩", systemImage: "chart.bar.fill", rows: rows([
                row("总分", text("zf")),
                row("语文", text("chineseScore")),
                row("数学", text("mathScore")),
                row("英语", text("englishScore"))
            ])),
            ArchiveSection(title: "联系方式", systemImage: "phone.fill", rows: rows([
                row("手机", text("stuPhone")),
                row("邮箱", text("stuEmail")),
                row("通讯地址", text("stuCommunicationAddr")),
                row("现住址", text("stuNowLiveAddr") ?? text("stuLiveAddr")),
                row("户籍地址", text("stuHouseholdRegistration"))
            ])),
            ArchiveSection(title: "家长一", systemImage: "person.2.fill", rows: rows([
                row("姓名", text("parent1Name")),
                row("关系", text("parent1Relation")),
                row("联系电话", text("parent1Phone")),
                row("邮箱", text("parent1Email")),
                row("学历", text("parent1DegreeEducation")),
                row("工作单位", text("parent1WorkPlace")),
                row("职务", text("parent1JobPost"))
            ])),
            ArchiveSection(title: "家长二", systemImage: "person.2.fill", rows: rows([
                row("姓名", text("parent2Name")),
                row("关系", text("parent2Relation")),
                row("联系电话", text("parent2Phone")),
                row("邮箱", text("parent2Email")),
                row("学历", text("parent2DegreeEducation")),
                row("工作单位", text("parent2WorkPlace")),
                row("职务", text("parent2JobPost"))
            ])),
            ArchiveSection(title: "时间信息", systemImage: "clock.fill", rows: rows([
                row("更新时间", text("updateTime")),
                row("创建时间", text("createTime"))
            ]))
        ].filter { !$0.rows.isEmpty }

        guard !sections.isEmpty else { return nil }

        var tags: [String] = []
        if let className = text("stuClassName") { tags.append(className) }
        if let status = text("stuBelongSchoolRollStatus") { tags.append(status) }

        return ArchiveProfile(
            photoURL: text("zplj").flatMap(URL.init(string:)),
            name: text("stuName") ?? "未知学生",
            subtitle: [text("xh") ?? text("stuSchoolRollCode"), text("xn").map { "\($0) 学年" }]
                .compactMap { $0 }
                .joined(separator: " · "),
            tags: tags,
            sections: sections
        )
    }
}

private struct ArchiveProfileView: View {
    let profile: ArchiveProfile
    let rawText: String

    @State private var showRaw = false

    private let accent = Color(red: 0.0, green: 0.42, blue: 0.86)

    var body: some View {
        VStack(spacing: 16) {
            header

            ForEach(profile.sections) { section in
                sectionCard(section)
            }

            rawToggle
        }
    }

    // 顶部：照片 + 姓名 + 班级标签
    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            photo

            VStack(alignment: .leading, spacing: 10) {
                Text(profile.name)
                    .font(.title2.bold())
                    .foregroundStyle(Color.themeInk)

                Text(profile.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !profile.tags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(profile.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(accent.opacity(0.12), in: Capsule())
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(cardBackground)
    }

    private var photo: some View {
        Group {
            if let url = profile.photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().scaledToFill()
                    case .failure:
                        photoPlaceholder
                    default:
                        ZStack {
                            Color(.tertiarySystemFill)
                            ProgressView()
                        }
                    }
                }
            } else {
                photoPlaceholder
            }
        }
        .frame(width: 92, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.6), lineWidth: 0.5)
        )
    }

    private var photoPlaceholder: some View {
        ZStack {
            Color(.tertiarySystemFill)
            Image(systemName: "person.crop.rectangle")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
        }
    }

    private func sectionCard(_ section: ArchiveSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent)

                Text(section.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themeInk)

                Spacer()
            }

            VStack(spacing: 0) {
                ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Divider()
                    }
                    rowView(item)
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private func rowView(_ item: ArchiveRow) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(item.label)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(width: 92, alignment: .leading)

            Text(item.value)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 9)
    }

    private var rawToggle: some View {
        DisclosureGroup(isExpanded: $showRaw) {
            Text(rawText)
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
        } label: {
            Label("原始数据", systemImage: "curlybraces")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(0.5), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 16, y: 8)
    }
}

// MARK: - Face ID 验证

enum BiometricGate {
    /// Face ID 优先；不可用时回退到设备密码。
    static func confirm(reason: String) async -> Bool {
        let context = LAContext()

        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            do {
                return try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: reason
                )
            } catch {
                return false
            }
        }

        // 没有可用的 Face ID / Touch ID 时，退回设备密码验证。
        let fallback = LAContext()
        var fallbackError: NSError?
        guard fallback.canEvaluatePolicy(.deviceOwnerAuthentication, error: &fallbackError) else {
            // 设备完全没有可用的身份验证方式，放行以免功能不可用。
            return true
        }

        do {
            return try await fallback.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}

// MARK: - 档案截图

enum SnapshotError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "没有相册写入权限，请在系统设置中开启后重试"
        }
    }
}

@MainActor
enum ArchiveSnapshotRenderer {
    /// 先同步下载照片，保证截图里能带上照片。
    static func loadPhoto(_ url: URL?) async -> UIImage? {
        guard let url else { return nil }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return UIImage(data: data)
    }

    static func render(profile: ArchiveProfile, photo: UIImage?) -> UIImage? {
        let content = ArchiveSnapshotView(profile: profile, photo: photo)
            .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        return renderer.uiImage
    }

    static func saveToPhotoLibrary(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw SnapshotError.permissionDenied
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}

/// 用于生成截图的静态档案视图（纯色背景，避免离屏渲染材质失效）。
private struct ArchiveSnapshotView: View {
    let profile: ArchiveProfile
    let photo: UIImage?

    private let accent = Color(red: 0.0, green: 0.42, blue: 0.86)
    private let ink = Color(red: 0.05, green: 0.12, blue: 0.24)
    private let muted = Color(red: 0.45, green: 0.5, blue: 0.58)

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            ForEach(profile.sections) { section in
                block(section)
            }

            footer
        }
        .padding(22)
        .frame(width: 380, alignment: .leading)
        .background(Color.white)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Group {
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Color(red: 0.93, green: 0.95, blue: 0.98)
                        Image(systemName: "person.crop.rectangle")
                            .font(.system(size: 26))
                            .foregroundStyle(Color(red: 0.6, green: 0.65, blue: 0.72))
                    }
                }
            }
            .frame(width: 84, height: 108)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(profile.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(ink)

                Text(profile.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(muted)

                if !profile.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(profile.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(accent.opacity(0.12), in: Capsule())
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            Color(red: 0.96, green: 0.98, blue: 1.0),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private func block(_ section: ArchiveSection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accent)

                Text(section.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ink)
            }

            VStack(spacing: 0) {
                ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Rectangle()
                            .fill(Color(red: 0.90, green: 0.92, blue: 0.95))
                            .frame(height: 0.5)
                    }

                    HStack(alignment: .top, spacing: 10) {
                        Text(item.label)
                            .font(.system(size: 12))
                            .foregroundStyle(muted)
                            .frame(width: 84, alignment: .leading)

                        Text(item.value)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 7)
                }
            }
        }
        .padding(14)
        .background(
            Color(red: 0.985, green: 0.99, blue: 1.0),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(red: 0.90, green: 0.92, blue: 0.95), lineWidth: 1)
        )
    }

    private var footer: some View {
        HStack {
            Text("玄武查 · 学籍档案")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(muted)

            Spacer()

            Text(Self.timestamp)
                .font(.system(size: 11))
                .foregroundStyle(Color(red: 0.6, green: 0.65, blue: 0.72))
        }
    }

    private static var timestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: Date())
    }
}

// MARK: - 加密钱包解析

/// 支持解析的 EVM 链。RPC 走 publicnode（国内访问较快），价格用链上 Chainlink 预言机。
enum WalletChain: String, CaseIterable, Identifiable {
    case ethereum, bsc, polygon, arbitrum, optimism, base

    var id: String { rawValue }

    var name: String {
        switch self {
        case .ethereum: return "以太坊"
        case .bsc: return "BNB Chain"
        case .polygon: return "Polygon"
        case .arbitrum: return "Arbitrum"
        case .optimism: return "Optimism"
        case .base: return "Base"
        }
    }

    var symbol: String {
        switch self {
        case .ethereum, .arbitrum, .optimism, .base: return "ETH"
        case .bsc: return "BNB"
        case .polygon: return "POL"
        }
    }

    var rpcURL: URL {
        switch self {
        case .ethereum:
            return URL(string: "https://ethereum-rpc.publicnode.com")!
        case .bsc:
            return URL(string: "https://bsc-rpc.publicnode.com")!
        case .polygon:
            return URL(string: "https://polygon-bor-rpc.publicnode.com")!
        case .arbitrum:
            return URL(string: "https://arbitrum-one-rpc.publicnode.com")!
        case .optimism:
            return URL(string: "https://optimism-rpc.publicnode.com")!
        case .base:
            return URL(string: "https://base-rpc.publicnode.com")!
        }
    }

    /// Chainlink 原生代币 / USD 价格源（8 位小数）。
    var priceFeed: String {
        switch self {
        case .ethereum: return "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419"
        case .bsc: return "0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE"
        case .polygon: return "0xAB594600376Ec9fD91F8e885dADF0CE036862dE0"
        case .arbitrum: return "0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612"
        case .optimism: return "0x13e3Ee699D1909E989722E753853AE30b17e08c5"
        case .base: return "0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70"
        }
    }

    var color: Color {
        switch self {
        case .ethereum: return Color(red: 0.38, green: 0.49, blue: 0.92)
        case .bsc: return Color(red: 0.95, green: 0.73, blue: 0.18)
        case .polygon: return Color(red: 0.51, green: 0.28, blue: 0.90)
        case .arbitrum: return Color(red: 0.16, green: 0.63, blue: 0.94)
        case .optimism: return Color(red: 1.00, green: 0.02, blue: 0.13)
        case .base: return Color(red: 0.00, green: 0.32, blue: 1.00)
        }
    }
}

/// 地址类型
enum WalletAddressKind {
    case eoa
    case eip7702
    case contract

    var label: String {
        switch self {
        case .eoa: return "普通账户"
        case .eip7702: return "委托账户 (EIP-7702)"
        case .contract: return "智能合约"
        }
    }

    var symbol: String {
        switch self {
        case .eoa: return "person.fill"
        case .eip7702: return "arrow.triangle.branch"
        case .contract: return "shippingbox.fill"
        }
    }
}

struct WalletChainAsset: Identifiable {
    let chain: WalletChain
    let balance: Decimal
    let price: Decimal?
    let txCount: Int
    let kind: WalletAddressKind

    var id: String { chain.id }
    var usdValue: Decimal? { price.map { $0 * balance } }
    var isEmpty: Bool { balance == 0 && txCount == 0 }
}

struct WalletReport {
    let address: String
    let assets: [WalletChainAsset]
    let failedChains: [String]

    var totalUSD: Decimal {
        assets.compactMap(\.usdValue).reduce(0, +)
    }

    var hasPrice: Bool {
        assets.contains { $0.price != nil }
    }
}

enum WalletError: LocalizedError {
    case invalidAddress
    case allChainsFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidAddress:
            return "地址格式不正确，请输入 0x 开头的 42 位 EVM 地址。"
        case let .allChainsFailed(detail):
            return "所有链均查询失败：\(detail)"
        }
    }
}

/// 链上解析服务：批量 JSON-RPC 请求。
enum WalletService {
    /// 校验并规范化地址格式（仅格式校验，不做 EIP-55 校验和）。
    static func normalize(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let address = trimmed.hasPrefix("0x") || trimmed.hasPrefix("0X")
            ? String(trimmed.dropFirst(2))
            : trimmed

        guard address.count == 40,
              address.allSatisfy({ $0.isHexDigit }) else { return nil }

        return "0x" + address.lowercased()
    }

    static func analyze(_ input: String) async throws -> WalletReport {
        guard let address = normalize(input) else { throw WalletError.invalidAddress }

        var assets: [WalletChainAsset] = []
        var failures: [String] = []

        await withTaskGroup(of: Result<WalletChainAsset, Error>.self) { group in
            for chain in WalletChain.allCases {
                group.addTask { await fetch(chain: chain, address: address) }
            }

            for await result in group {
                switch result {
                case let .success(asset):
                    assets.append(asset)
                case let .failure(error):
                    failures.append(error.localizedDescription)
                }
            }
        }

        if assets.isEmpty {
            throw WalletError.allChainsFailed(failures.first ?? "网络错误")
        }

        // 按 USD 价值降序，无余额的排最后
        assets.sort { lhs, rhs in
            if lhs.isEmpty != rhs.isEmpty { return !lhs.isEmpty }
            return (lhs.usdValue ?? 0) > (rhs.usdValue ?? 0)
        }

        return WalletReport(address: address, assets: assets, failedChains: failures)
    }

    private static func fetch(chain: WalletChain, address: String) async -> Result<WalletChainAsset, Error> {
        let requests: [[String: Any]] = [
            ["jsonrpc": "2.0", "id": 1, "method": "eth_getBalance", "params": [address, "latest"]],
            ["jsonrpc": "2.0", "id": 2, "method": "eth_getTransactionCount", "params": [address, "latest"]],
            ["jsonrpc": "2.0", "id": 3, "method": "eth_getCode", "params": [address, "latest"]],
            ["jsonrpc": "2.0", "id": 4, "method": "eth_call",
             "params": [["to": chain.priceFeed, "data": "0xfeaf968c"], "latest"]]
        ]

        do {
            let responses = try await batch(chain.rpcURL, requests)

            let balanceHex = responses[1] as? String ?? "0x0"
            let txHex = responses[2] as? String ?? "0x0"
            let codeHex = responses[3] as? String ?? "0x"
            let priceHex = responses[4] as? String

            let balance = (hexToDecimal(balanceHex) ?? 0) / pow(Decimal(10), 18)
            let txCount = NSDecimalNumber(decimal: hexToDecimal(txHex) ?? 0).intValue
            let price = priceHex.flatMap { chainlinkAnswer($0) }

            return .success(WalletChainAsset(
                chain: chain,
                balance: balance,
                price: price,
                txCount: txCount,
                kind: addressKind(code: codeHex)
            ))
        } catch {
            return .failure(error)
        }
    }

    /// 单个 POST 发送多条 JSON-RPC 请求，按 id 排序返回结果。
    private static func batch(_ url: URL, _ requests: [[String: Any]]) async throws -> [Int: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        request.httpBody = try JSONSerialization.data(withJSONObject: requests)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }

        guard let list = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }

        var results: [Int: Any] = [:]
        for item in list {
            guard let id = item["id"] as? Int else { continue }
            if let error = item["error"] as? [String: Any] {
                throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: error["message"] ?? "RPC error"])
            }
            results[id] = item["result"] as Any
        }
        return results
    }

    /// 从 latestRoundData() 返回里取出 answer 字段（第 2 个字），除以 1e8。
    private static func chainlinkAnswer(_ result: String) -> Decimal? {
        var hex = result
        guard hex.hasPrefix("0x") else { return nil }
        hex = String(hex.dropFirst(2))
        guard hex.count >= 128 else { return nil }

        let answerStart = hex.index(hex.startIndex, offsetBy: 64)
        let answerEnd = hex.index(answerStart, offsetBy: 64)
        guard let raw = hexToDecimal(String(hex[answerStart..<answerEnd])) else { return nil }

        return raw / pow(Decimal(10), 8)
    }

    private static func addressKind(code: String) -> WalletAddressKind {
        let normalized = code.lowercased()
        if normalized == "0x" || normalized.isEmpty { return .eoa }
        if normalized.hasPrefix("0xef0100") { return .eip7702 }
        return .contract
    }

    /// 十六进制字符串转 Decimal（支持超长 uint256）。
    static func hexToDecimal(_ hex: String) -> Decimal? {
        var text = hex
        if text.hasPrefix("0x") || text.hasPrefix("0X") { text = String(text.dropFirst(2)) }
        guard !text.isEmpty else { return 0 }

        var result = Decimal(0)
        for character in text.lowercased() {
            guard let digit = character.hexDigitValue else { return nil }
            result = result * 16 + Decimal(digit)
        }
        return result
    }
}

struct WalletLookupView: View {
    @State private var address: String = ""
    @State private var report: WalletReport?
    @State private var tronReport: TronReport?
    @State private var errorText: String?
    @State private var isLoading = false
    @FocusState private var focused: Bool

    private let accentBlue = Color(red: 0.0, green: 0.42, blue: 0.86)

    private var canSubmit: Bool {
        !isLoading && !address.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                inputCard(
                    title: "钱包地址",
                    placeholder: "0x... 或 T...",
                    systemImage: "bitcoinsign.circle.fill",
                    text: $address,
                    focused: $focused,
                    monospaced: true
                )

                queryButton(title: "解析", isLoading: isLoading, action: { analyze() })
                    .disabled(!canSubmit)

                if let tronReport {
                    TronSummaryCard(report: tronReport)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity))

                    ForEach(tronReport.holdings) { holding in
                        TronTokenCard(holding: holding)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity))
                    }

                    if tronReport.hiddenTokenCount > 0 {
                        Text("另有 \(tronReport.hiddenTokenCount) 个代币未显示（无行情或余额过小）")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else if let report {
                    WalletSummaryCard(report: report)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity))

                    ForEach(report.assets.filter { !$0.isEmpty }) { asset in
                        WalletAssetCard(asset: asset)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity))
                    }

                    if !report.failedChains.isEmpty {
                        Text("部分链查询失败：\(report.failedChains.joined(separator: "、"))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else if let errorText {
                    WalletErrorCard(message: errorText)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity))
                }
            }
            .padding(20)
        }
        .background(backgroundGradient.ignoresSafeArea())
        .navigationTitle("加密钱包")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: report?.address)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: tronReport?.address)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: errorText)
        .scrollDismissesKeyboard(.interactively)
    }

    private func analyze() {
        focused = false
        isLoading = true
        errorText = nil
        report = nil
        tronReport = nil

        let input = address.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            defer { isLoading = false }
            do {
                if TronService.normalize(input) != nil {
                    tronReport = try await TronService.analyze(input)
                } else {
                    report = try await WalletService.analyze(input)
                }
            } catch {
                errorText = error.localizedDescription
            }
        }
    }
}

/// 总览卡片
private struct WalletSummaryCard: View {
    let report: WalletReport

    private let accentBlue = Color(red: 0.0, green: 0.42, blue: 0.86)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.42, green: 0.32, blue: 0.85), accentBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "wallet.bifold.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("总资产估值")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if report.hasPrice {
                        Text(WalletFormat.usd(report.totalUSD))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.themeInk)
                            .contentTransition(.numericText())
                    } else {
                        Text("暂无价格")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                Button {
                    UIPasteboard.general.string = report.address
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.footnote)
                        .foregroundStyle(accentBlue)
                }
                .buttonStyle(.plain)
            }

            Divider()

            HStack(spacing: 8) {
                Image(systemName: "number")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(report.address)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            HStack(spacing: 6) {
                statChip("\(report.assets.count) 条链", systemImage: "link")
                statChip("\(report.assets.filter { !$0.isEmpty }.count) 有资产", systemImage: "circle.fill")
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 16, y: 8)
    }

    private func statChip(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 8))
            Text(text)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color(.tertiarySystemFill)))
    }
}

/// 单条链资产卡片
private struct WalletAssetCard: View {
    let asset: WalletChainAsset

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(asset.chain.color.opacity(0.16))
                        .frame(width: 40, height: 40)

                    Image(systemName: "hexagon.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(asset.chain.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(asset.chain.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themeInk)

                    HStack(spacing: 5) {
                        Image(systemName: asset.kind.symbol)
                            .font(.system(size: 9))
                        Text(asset.kind.label)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(WalletFormat.amount(asset.balance)) \(asset.chain.symbol)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themeInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let usd = asset.usdValue {
                        Text(WalletFormat.usd(usd))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            HStack {
                row("交易数（nonce）", "\(asset.txCount)")
                Spacer()
                if let price = asset.price {
                    row("\(asset.chain.symbol) 价格", WalletFormat.usd(price))
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, y: 7)
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.themeInk)
        }
    }
}

private struct WalletErrorCard: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color(red: 0.85, green: 0.45, blue: 0.1))
                .symbolEffect(.bounce)

            VStack(alignment: .leading, spacing: 4) {
                Text("解析失败")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themeInk)

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, y: 7)
    }
}

private enum WalletFormat {
    static func amount(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
        return formatter.string(from: value as NSDecimalNumber) ?? "0"
    }

    static func usd(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = value < 1 ? 4 : 2
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }

    static func date(_ value: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: value)
    }
}

// MARK: - Tron 链支持

enum TronError: LocalizedError {
    case invalidAddress
    case accountNotFound
    case network(String)

    var errorDescription: String? {
        switch self {
        case .invalidAddress:
            return "地址格式不正确，请输入 T 开头的 34 位 Tron 地址。"
        case .accountNotFound:
            return "该地址在 Tron 链上不存在或尚未激活。"
        case let .network(detail):
            return "Tron 查询失败：\(detail)"
        }
    }
}

/// 单个 TRC20 代币持仓
struct TronHolding: Identifiable {
    let id: String
    let symbol: String
    let name: String
    let amount: Decimal
    /// 该代币估值的 TRX 计价（无行情时为 nil，同时用于排序）
    let valueTRX: Decimal?
    /// 单价（美元），无行情时为 nil
    let unitPriceUSD: Decimal?
    /// 估值（美元），无行情时为 nil
    let usdValue: Decimal?

    var shortContract: String { id.count > 12 ? "\(id.prefix(6))…\(id.suffix(6))" : id }
}

struct TronReport {
    let address: String
    let trxBalance: Decimal
    let trxPriceUSD: Decimal?
    let createdAt: Date?
    let transactionCount: Int?
    let tag: String?
    let holdings: [TronHolding]
    let hiddenTokenCount: Int

    var hasPrice: Bool { trxPriceUSD != nil }

    var totalUSD: Decimal {
        (trxPriceUSD.map { $0 * trxBalance } ?? 0)
            + holdings.compactMap(\.usdValue).reduce(0, +)
    }

    var totalTRX: Decimal {
        trxBalance + holdings.compactMap(\.valueTRX).reduce(0, +)
    }
}

private struct TronTokenEntry {
    let contract: String
    let symbol: String
    let name: String
    let amount: Decimal
    let unitPriceTRX: Decimal?
}

private struct TronAccountSnapshot {
    let balance: Decimal
    let createdAt: Date?
    let transactionCount: Int?
    let tag: String?
    let tokens: [TronTokenEntry]
    /// 从账户内稳定币的 tokenPriceInTrx 推导出的 TRX/USD 价（无需额外请求）
    let derivedTrxPriceUSD: Decimal?
}

/// Tron 链解析：TronScan 账户接口一次性返回 TRX 余额与全部 TRC20 行情，
/// 再用链上 SunSwap V2 池子推算的 TRX/USD 价格换算成美元估值。
enum TronService {
    private static let accountURL = "https://apilist.tronscanapi.com/api/account"
    private static let contractURL = "https://api.trongrid.io/wallet/triggerconstantcontract"
    private static let sunswapFactory = "TKWJdrQkqHisa1X8HUdHEfREvTzw4pMAaY"
    private static let usdtContract = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"
    private static let wtrxContract = "TNUC9Qb1rRpS5CbWLmNMxXBjyFoydXjWFR"
    /// 锚定美元的稳定币合约，用于从账户响应直接推导 TRX/USD 价（无需额外请求）。
    private static let usdStablecoins: Set<String> = [
        "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t", // USDT
        "TEkxiTehnzSmSe2XqrBj4w32RUN966rdz8", // USDC (new)
        "TQn9Y2khEsLJW1ChVWFMSMeRDow5KcbLSE", // USDC (old)
        "TPYmMKvqkvSxdSfwJJWa2rqX8vY1R8rAqG", // USDD
        "TMwFHYXLJaRUPeW7eSAXhx1fQyK9C3PMd3", // USDJ
        "TUpMhErZL2fhh4VQMd2SGQZ29EV8JunQ3"  // TUSD
    ]
    /// 最多展示的代币数量，避免热门地址上百个 dust 刷屏。
    private static let maxHoldingCount = 12

    private static let base58Alphabet = Array("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")

    /// 校验 Tron 地址格式（T 开头、34 位、Base58 字符集）。
    static func normalize(_ input: String) -> String? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count == 34, text.hasPrefix("T"),
              text.allSatisfy({ base58Alphabet.contains($0) }) else { return nil }
        return text
    }

    static func analyze(_ input: String) async throws -> TronReport {
        guard let address = normalize(input), hexAddress(address) != nil else {
            throw TronError.invalidAddress
        }

        let snapshot = try await fetchAccount(address)
        // 优先用账户内稳定币推导出的 TRX/USD 价（零额外请求），没有稳定币时才走 SunSwap 链上报价。
        let trxPrice: Decimal?
        if let derived = snapshot.derivedTrxPriceUSD {
            trxPrice = derived
        } else {
            trxPrice = await trxPriceUSD()
        }

        var holdings: [TronHolding] = []
        for token in snapshot.tokens {
            let valueTRX = token.unitPriceTRX.map { $0 * token.amount }
            holdings.append(
                TronHolding(
                    id: token.contract,
                    symbol: token.symbol,
                    name: token.name,
                    amount: token.amount,
                    valueTRX: valueTRX,
                    unitPriceUSD: token.unitPriceTRX.flatMap { unit in trxPrice.map { unit * $0 } },
                    usdValue: valueTRX.flatMap { value in trxPrice.map { value * $0 } }
                )
            )
        }

        // 有行情的按估值降序；一个都没有时退化为按余额数量排序。
        let priced = holdings.filter { ($0.valueTRX ?? 0) > 0 }
            .sorted { ($0.valueTRX ?? 0) > ($1.valueTRX ?? 0) }
        let fallback = holdings.sorted { $0.amount > $1.amount }
        let visible = Array((priced.isEmpty ? fallback : priced).prefix(maxHoldingCount))

        return TronReport(
            address: address,
            trxBalance: snapshot.balance,
            trxPriceUSD: trxPrice,
            createdAt: snapshot.createdAt,
            transactionCount: snapshot.transactionCount,
            tag: snapshot.tag,
            holdings: visible,
            hiddenTokenCount: max(0, holdings.count - visible.count)
        )
    }

    // MARK: 账户数据

    private static func fetchAccount(_ address: String) async throws -> TronAccountSnapshot {
        guard var components = URLComponents(string: accountURL) else {
            throw TronError.network("接口地址无效")
        }
        components.queryItems = [URLQueryItem(name: "address", value: address)]
        guard let url = components.url else { throw TronError.network("接口地址无效") }

        let object = try await getJSON(url)
        guard let balanceRaw = decimal(from: object["balance"]) else {
            throw TronError.accountNotFound
        }

        let createdAt = (object["date_created"] as? NSNumber)
            .flatMap { $0.doubleValue > 0 ? Date(timeIntervalSince1970: $0.doubleValue / 1000) : nil }
        let transactionCount = (object["totalTransactionCount"] as? NSNumber).map(\.intValue)
        let tag = (object["addressTag"] as? String).flatMap { $0.isEmpty ? nil : $0 }

        let tokens: [TronTokenEntry] = ((object["trc20token_balances"] as? [[String: Any]]) ?? [])
            .compactMap { entry in
                guard let contract = entry["tokenId"] as? String,
                      let raw = decimal(from: entry["balance"]), raw > 0 else { return nil }

                let decimals = (entry["tokenDecimal"] as? NSNumber)?.intValue ?? 6
                let symbol = (entry["tokenAbbr"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                let name = (entry["tokenName"] as? String).flatMap { $0.isEmpty ? nil : $0 }

                return TronTokenEntry(
                    contract: contract,
                    symbol: symbol ?? "未知代币",
                    name: name ?? symbol ?? "未知代币",
                    amount: raw / scale(decimals),
                    unitPriceTRX: decimal(from: entry["tokenPriceInTrx"])
                )
            }

        // 从账户内稳定币的 tokenPriceInTrx 推导 TRX/USD：
        // 稳定币 ≈ $1，故 TRX/USD = 1 / tokenPriceInTrx。多个稳定币取平均更稳健。
        let stablecoinPrices = tokens.compactMap { token -> Decimal? in
            guard usdStablecoins.contains(token.contract),
                  let priceTRX = token.unitPriceTRX, priceTRX > 0 else { return nil }
            return 1 / priceTRX
        }
        let derivedTrxPriceUSD: Decimal? = stablecoinPrices.isEmpty ? nil :
            stablecoinPrices.reduce(0, +) / Decimal(stablecoinPrices.count)

        return TronAccountSnapshot(
            balance: balanceRaw / scale(6),
            createdAt: createdAt,
            transactionCount: transactionCount,
            tag: tag,
            tokens: tokens,
            derivedTrxPriceUSD: derivedTrxPriceUSD
        )
    }

    // MARK: TRX 美元价（SunSwap V2 的 WTRX/USDT 池）

    private static func trxPriceUSD() async -> Decimal? {
        // TronGrid 限 3 rps，偶发 429；最多重试 2 次，每次间隔 1 秒。
        for attempt in 0..<3 {
            if let price = await sunswapTrxPrice() { return price }
            if attempt < 2 { try? await Task.sleep(for: .seconds(1)) }
        }
        return nil
    }

    private static func sunswapTrxPrice() async -> Decimal? {
        guard let usdtHex = hexAddress(usdtContract),
              let wtrxHex = hexAddress(wtrxContract),
              let factoryHex = hexAddress(sunswapFactory) else { return nil }

        let args = String(repeating: "0", count: 24) + String(wtrxHex.dropFirst(2))
            + String(repeating: "0", count: 24) + String(usdtHex.dropFirst(2))

        guard let output = await constantCall(contract: factoryHex, data: "0xe6a43905" + args),
              output.count >= 64 else { return nil }

        let pair = "41" + String(output.suffix(40))
        guard pair != "41" + String(repeating: "0", count: 40),
              let reserves = await reserves(pairHex: pair) else { return nil }

        // Uniswap/SunSwap 交易对按地址大小排序 token0 / token1
        let wtrxFirst = wtrxHex < usdtHex
        let wtrxReserve = wtrxFirst ? reserves.0 : reserves.1
        let usdtReserve = wtrxFirst ? reserves.1 : reserves.0
        guard wtrxReserve > 0 else { return nil }

        return (usdtReserve / scale(6)) / (wtrxReserve / scale(6))
    }

    private static func reserves(pairHex: String) async -> (Decimal, Decimal)? {
        guard let output = await constantCall(contract: pairHex, data: "0x0902f1ac"),
              output.count >= 128 else { return nil }

        let start = output.startIndex
        let first = String(output[start..<output.index(start, offsetBy: 64)])
        let second = String(output[output.index(start, offsetBy: 64)..<output.index(start, offsetBy: 128)])

        guard let r0 = WalletService.hexToDecimal(first),
              let r1 = WalletService.hexToDecimal(second) else { return nil }
        return (r0, r1)
    }

    // MARK: 网络与编解码

    private static func constantCall(contract: String, data: String) async -> String? {
        guard let url = URL(string: contractURL) else { return nil }

        let body: [String: Any] = [
            "owner_address": "41" + String(repeating: "00", count: 20),
            "contract_address": contract,
            "data": data,
            "visible": false
        ]

        guard let object = try? await postJSON(url, body: body),
              let results = object["constant_result"] as? [String],
              let first = results.first, !first.isEmpty else { return nil }
        return first
    }

    private static func getJSON(_ url: URL) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        return try await perform(request)
    }

    private static func postJSON(_ url: URL, body: [String: Any]) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await perform(request)
    }

    private static func perform(_ request: URLRequest) async throws -> [String: Any] {
        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw TronError.network("HTTP \(http.statusCode)")
        }

        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TronError.network("响应格式异常")
        }
        return object
    }

    /// JSON 数值统一转 Decimal，避免 Double 的二进制误差。
    private static func decimal(from value: Any?) -> Decimal? {
        if let text = value as? String { return Decimal(string: text) }
        if let number = value as? NSNumber {
            return Decimal(string: String(describing: number.doubleValue)) ?? number.decimalValue
        }
        return nil
    }

    private static func scale(_ decimals: Int) -> Decimal {
        pow(Decimal(10), min(max(decimals, 0), 30))
    }

    /// Base58Check 地址转 21 字节十六进制（含 41 前缀）。
    private static func hexAddress(_ address: String) -> String? {
        var bytes: [UInt8] = [0]

        for character in address {
            guard let index = base58Alphabet.firstIndex(of: character) else { return nil }
            var carry = index
            var position = bytes.count - 1

            while position >= 0 {
                let value = Int(bytes[position]) * 58 + carry
                bytes[position] = UInt8(value & 0xFF)
                carry = value >> 8
                position -= 1
            }

            while carry > 0 {
                bytes.insert(UInt8(carry & 0xFF), at: 0)
                carry >>= 8
            }
        }

        let hex = bytes.map { String(format: "%02x", $0) }.joined()
        guard hex.count >= 42 else { return nil }
        return String(hex.prefix(42))
    }
}

private struct TronSummaryCard: View {
    let report: TronReport

    private let tronRed = Color(red: 0.85, green: 0.22, blue: 0.22)
    private let accentBlue = Color(red: 0.0, green: 0.42, blue: 0.86)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.36, blue: 0.36), tronRed],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("总资产估值")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if report.hasPrice {
                        Text(WalletFormat.usd(report.totalUSD))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.themeInk)
                            .contentTransition(.numericText())
                    } else {
                        Text("\(WalletFormat.amount(report.totalTRX)) TRX")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                Button {
                    UIPasteboard.general.string = report.address
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.footnote)
                        .foregroundStyle(accentBlue)
                }
                .buttonStyle(.plain)
            }

            Divider()

            HStack(spacing: 8) {
                Image(systemName: "number")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(report.address)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            VStack(spacing: 10) {
                infoRow("TRX 余额", "\(WalletFormat.amount(report.trxBalance)) TRX")

                if let price = report.trxPriceUSD {
                    infoRow("TRX 价格", WalletFormat.usd(price))
                }
                if let created = report.createdAt {
                    infoRow("开户时间", WalletFormat.date(created))
                }
                if let count = report.transactionCount {
                    infoRow("交易总数", WalletFormat.amount(Decimal(count)))
                }
            }

            HStack(spacing: 6) {
                statChip("TRON", systemImage: "bolt.fill")
                statChip("\(report.holdings.count + report.hiddenTokenCount) 个代币", systemImage: "circle.fill")
                if let tag = report.tag {
                    statChip(tag, systemImage: "tag.fill")
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 16, y: 8)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.themeInk)
        }
    }

    private func statChip(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 8))
            Text(text)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color(.tertiarySystemFill)))
    }
}

private struct TronTokenCard: View {
    let holding: TronHolding

    private let tronRed = Color(red: 0.85, green: 0.22, blue: 0.22)

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(tronRed.opacity(0.14))
                        .frame(width: 40, height: 40)

                    Image(systemName: "hexagon.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tronRed)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(holding.symbol)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themeInk)

                    Text(holding.shortContract)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(WalletFormat.amount(holding.amount)) \(holding.symbol)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themeInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let usd = holding.usdValue {
                        Text(WalletFormat.usd(usd))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let trx = holding.valueTRX {
                        Text("\(WalletFormat.amount(trx)) TRX")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            HStack {
                row("单价", holding.unitPriceUSD.map(WalletFormat.usd) ?? "暂无行情")
                Spacer(minLength: 8)
                row("代币名称", holding.name)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, y: 7)
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.themeInk)
        }
    }
}

// MARK: - 关于页

private struct AboutView: View {
    @State private var appeared = false

    private let accent = Color(red: 0.0, green: 0.42, blue: 0.86)
    private let cyan = Color(red: 0.35, green: 0.72, blue: 1.0)

    var body: some View {
        // 用 TimelineView 逐帧驱动，动画连续无跳变。
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                LinearGradient(colors: [.themeBgTop, .themeBgBottom], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                StarField(time: t)

                VStack(spacing: 30) {
                    emblem(t: t)
                    wordmark(t: t)
                }
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.94)
                .animation(.spring(response: 0.9, dampingFraction: 0.85), value: appeared)
            }
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { appeared = true }
    }

    // MARK: 徽标

    private func emblem(t: Double) -> some View {
        let breathe = 0.5 + 0.5 * sin(t * 0.72)
        let float = sin(t * 1.04) * 7
        let spin = t * 24

        return ZStack {
            // 呼吸光晕
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accent.opacity(0.5), accent.opacity(0)],
                        center: .center,
                        startRadius: 8,
                        endRadius: 150
                    )
                )
                .frame(width: 280, height: 280)
                .scaleEffect(0.9 + 0.14 * breathe)
                .opacity(0.55 + 0.4 * breathe)

            // 向外扩散的涟漪
            ForEach(0..<2, id: \.self) { index in
                let phase = (t * 0.45 + Double(index) * 0.5).truncatingRemainder(dividingBy: 1)
                Circle()
                    .stroke(accent.opacity(0.4 * (1 - phase)), lineWidth: 1.5)
                    .frame(width: 118, height: 118)
                    .scaleEffect(1 + 1.15 * phase)
            }

            // 旋转光环
            Circle()
                .trim(from: 0.12, to: 0.88)
                .stroke(
                    AngularGradient(colors: [accent, cyan, accent.opacity(0.04), accent], center: .center),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 132, height: 132)
                .rotationEffect(.degrees(spin))

            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.0, green: 0.24, blue: 0.55), accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 98, height: 98)
                    .shadow(color: accent.opacity(0.45), radius: 26, y: 12)

                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .fill(
                        LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .top, endPoint: .center)
                    )
                    .frame(width: 98, height: 98)

                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 45, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(1 + 0.035 * breathe)
            .offset(y: float)
        }
        .frame(height: 300)
    }

    // MARK: 标题

    private func wordmark(t: Double) -> some View {
        // 三角波 0 → 1 → 0，让高光来回扫动
        let cycle = (t * 0.32).truncatingRemainder(dividingBy: 1)
        let sweep = cycle < 0.5 ? cycle * 2 : (1 - cycle) * 2
        let font = Font.system(size: 36, weight: .bold)

        return VStack(spacing: 12) {
            Text("玄武查")
                .font(font)
                .foregroundStyle(
                    LinearGradient(colors: [accent, cyan, accent], startPoint: .leading, endPoint: .trailing)
                )
                .overlay {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.8), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.34)
                        .offset(x: -geo.size.width * 0.34 + sweep * geo.size.width * 1.34)
                    }
                    .mask(Text("玄武查").font(font))
                }

            Text("2026 powered by roy")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .tracking(1.6)

            Text("海尔学校 · 信息查询工具")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
    }
}

/// 背景星点：逐帧驱动，明灭更顺滑。
private struct StarField: View {
    let time: Double

    private let stars: [(x: CGFloat, y: CGFloat, size: CGFloat, phase: Double, speed: Double)] = [
        (0.12, 0.18, 3.0, 0.0, 1.1), (0.82, 0.12, 2.0, 1.7, 1.5),
        (0.30, 0.08, 2.5, 0.9, 1.3), (0.68, 0.22, 2.0, 2.4, 1.0),
        (0.08, 0.42, 2.0, 3.1, 1.6), (0.92, 0.52, 3.0, 0.5, 1.2),
        (0.22, 0.70, 2.5, 1.3, 0.9), (0.78, 0.78, 2.0, 2.8, 1.4),
        (0.45, 0.86, 3.0, 4.0, 1.1), (0.60, 0.60, 2.0, 0.2, 1.7),
        (0.15, 0.92, 2.0, 2.0, 1.2), (0.88, 0.34, 2.5, 3.6, 1.0)
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(stars.indices, id: \.self) { index in
                let star = stars[index]
                let twinkle = 0.5 + 0.5 * sin(time * star.speed + star.phase)
                Circle()
                    .fill(Color.themeStar)
                    .frame(width: star.size, height: star.size)
                    .blur(radius: 0.5)
                    .opacity(0.15 + 0.75 * twinkle)
                    .position(x: geo.size.width * star.x, y: geo.size.height * star.y)
            }
        }
        .allowsHitTesting(false)
    }
}


#Preview {
    ContentView()
}
