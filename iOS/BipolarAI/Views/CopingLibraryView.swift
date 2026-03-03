//
//  CopingLibraryView.swift
//  BipolarAI
//
//  Created on 2026-03-04
//  Coping library view — dynamic fetch from GAS CrisisPlan_Source + fallback
//

import SwiftUI

/// コーピングの方向フィルタ
enum CopingDirection: String, CaseIterable {
    case all = "全て"
    case depression = "鬱方向"
    case mania = "躁方向"
}

/// コーピングアイテム
struct CopingItem: Identifiable, Codable {
    var id: String { "\(domain)_\(title)" }
    let domain: String
    let title: String
    let stageRange: String    // "-3〜-5" or "+2〜+4"
    let description: String
    let direction: CopingDirection

    enum CodingKeys: String, CodingKey {
        case domain, title, stageRange, description, directionRaw
    }

    init(domain: String, title: String, stageRange: String, description: String, direction: CopingDirection) {
        self.domain = domain
        self.title = title
        self.stageRange = stageRange
        self.description = description
        self.direction = direction
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        domain = try c.decode(String.self, forKey: .domain)
        title = try c.decode(String.self, forKey: .title)
        stageRange = try c.decode(String.self, forKey: .stageRange)
        description = try c.decode(String.self, forKey: .description)
        let raw = try c.decode(String.self, forKey: .directionRaw)
        direction = raw == "depression" ? .depression : (raw == "mania" ? .mania : .all)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(domain, forKey: .domain)
        try c.encode(title, forKey: .title)
        try c.encode(stageRange, forKey: .stageRange)
        try c.encode(description, forKey: .description)
        let raw = direction == .depression ? "depression" : (direction == .mania ? "mania" : "all")
        try c.encode(raw, forKey: .directionRaw)
    }
}

/// コーピングドメイン
struct CopingDomain: Identifiable {
    var id: String { name }
    let name: String
    let icon: String
    let color: Color
    var items: [CopingItem]
}

/// コーピング一覧画面（GAS API動的取得 + キャッシュ + フォールバック）
struct CopingLibraryView: View {
    @State private var filter: CopingDirection = .all
    @State private var domains: [CopingDomain] = CopingLibraryData.allDomains
    @State private var isLoading = false
    @State private var dataSource: String = "組み込み"

    var body: some View {
        NavigationView {
            List {
                // データソース表示
                Section {
                    HStack {
                        Text("データソース")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(dataSource)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }

                    // フィルタ
                    Picker("方向", selection: $filter) {
                        ForEach(CopingDirection.allCases, id: \.self) { direction in
                            Text(direction.rawValue).tag(direction)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // ドメイン別セクション
                ForEach(domains) { domain in
                    let filteredItems = domain.items.filter { item in
                        filter == .all || item.direction == filter
                    }

                    if !filteredItems.isEmpty {
                        Section {
                            ForEach(filteredItems) { item in
                                CopingRowView(item: item, domainColor: domain.color)
                            }
                        } header: {
                            HStack(spacing: 6) {
                                Image(systemName: domain.icon)
                                    .foregroundColor(domain.color)
                                Text(domain.name)
                            }
                        }
                    }
                }
            }
            .navigationTitle("対処法")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadCopingData()
            }
        }
    }

    /// GAS APIからCopingデータを取得（キャッシュ付き）
    private func loadCopingData() async {
        // キャッシュチェック（1日1回更新）
        let cacheKey = "copingLibraryCache"
        let cacheDateKey = "copingLibraryCacheDate"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let today = formatter.string(from: Date())

        if let cachedDate = UserDefaults.standard.string(forKey: cacheDateKey),
           cachedDate == today,
           let cachedData = UserDefaults.standard.data(forKey: cacheKey),
           let cachedItems = try? JSONDecoder().decode([CopingItem].self, from: cachedData) {
            domains = groupIntoDomains(cachedItems)
            dataSource = "キャッシュ"
            return
        }

        // APIから取得
        isLoading = true
        do {
            let rawData = try await GASService.shared.fetchCopingLibrary()
            let items = parseCrisisPlanData(rawData)
            if !items.isEmpty {
                domains = groupIntoDomains(items)
                dataSource = "CrisisPlan API"

                // キャッシュ保存
                if let encoded = try? JSONEncoder().encode(items) {
                    UserDefaults.standard.set(encoded, forKey: cacheKey)
                    UserDefaults.standard.set(today, forKey: cacheDateKey)
                }
            }
        } catch {
            print("⚠️ CopingLibrary API error: \(error). Using fallback data.")
            dataSource = "組み込み（API取得失敗）"
        }
        isLoading = false
    }

    /// CrisisPlan_Sourceシートデータをパース
    private func parseCrisisPlanData(_ data: [[String]]) -> [CopingItem] {
        guard data.count >= 2 else { return [] }

        let header = data[0]
        var itemCol = -1
        var stageCols: [(stage: Int, colIndex: Int)] = []

        for (c, h) in header.enumerated() {
            let trimmed = h.trimmingCharacters(in: .whitespaces)
            if trimmed == "項目" || trimmed == "item" || trimmed == "domain" {
                itemCol = c
            }
            if let stageNum = Int(trimmed), stageNum >= -5 && stageNum <= 5 {
                stageCols.append((stage: stageNum, colIndex: c))
            }
        }

        guard itemCol >= 0 else { return [] }

        var items: [CopingItem] = []

        for r in 1..<data.count {
            let row = data[r]
            guard row.count > itemCol else { continue }
            let domain = row[itemCol].trimmingCharacters(in: .whitespaces)
            guard !domain.isEmpty else { continue }

            for sc in stageCols {
                guard sc.colIndex < row.count else { continue }
                let text = row[sc.colIndex].trimmingCharacters(in: .whitespaces)
                guard !text.isEmpty && text != "undefined" && text != "" else { continue }

                let direction: CopingDirection = sc.stage < 0 ? .depression : (sc.stage > 0 ? .mania : .all)
                let stageRange = sc.stage < 0 ? "\(sc.stage)" : "+\(sc.stage)"

                items.append(CopingItem(
                    domain: domain,
                    title: text,
                    stageRange: stageRange,
                    description: "\(domain)ドメイン ステージ\(stageRange)の対処法",
                    direction: direction
                ))
            }
        }

        return items
    }

    /// アイテムをドメイン別にグルーピング
    private func groupIntoDomains(_ items: [CopingItem]) -> [CopingDomain] {
        let domainConfig: [(name: String, icon: String, color: Color)] = [
            ("sleep", "bed.double.fill", .indigo),
            ("睡眠", "bed.double.fill", .indigo),
            ("activity", "figure.walk", .green),
            ("活動", "figure.walk", .green),
            ("alcohol", "wineglass.fill", .pink),
            ("飲酒", "wineglass.fill", .pink),
            ("medication", "pills.fill", .blue),
            ("服薬", "pills.fill", .blue),
            ("mindfulness", "brain.head.profile", .purple),
            ("マインドフルネス", "brain.head.profile", .purple),
            ("mood", "heart.text.square", .red),
            ("気分・認知", "heart.text.square", .red),
        ]

        var grouped: [String: [CopingItem]] = [:]
        for item in items {
            let key = item.domain.lowercased()
            grouped[key, default: []].append(item)
        }

        var result: [CopingDomain] = []
        var usedKeys: Set<String> = []

        for config in domainConfig {
            let key = config.name.lowercased()
            if let groupItems = grouped[key], !usedKeys.contains(key) {
                result.append(CopingDomain(
                    name: config.name,
                    icon: config.icon,
                    color: config.color,
                    items: groupItems
                ))
                usedKeys.insert(key)
            }
        }

        // 未知のドメインも追加
        for (key, groupItems) in grouped {
            if !usedKeys.contains(key) {
                result.append(CopingDomain(
                    name: key,
                    icon: "questionmark.circle",
                    color: .gray,
                    items: groupItems
                ))
            }
        }

        return result
    }
}

/// コーピング行表示
struct CopingRowView: View {
    let item: CopingItem
    let domainColor: Color
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // タイトル行
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)

                        Text("ステージ: \(item.stageRange)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // 方向バッジ
                    Text(item.direction == .depression ? "鬱" : "躁")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.direction == .depression ? Color.blue : Color.red)
                        .cornerRadius(4)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            // 解説（展開時）
            if isExpanded {
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(domainColor.opacity(0.06))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - コーピングデータ（組み込みフォールバック）

struct CopingLibraryData {
    static let allDomains: [CopingDomain] = [
        CopingDomain(
            name: "睡眠",
            icon: "bed.double.fill",
            color: .indigo,
            items: [
                CopingItem(domain: "睡眠", title: "起床時間の固定", stageRange: "-3〜-5",
                           description: "鬱期は過眠傾向になりやすいため、まず起床時間を固定することで体内時計のリズムを整えます。",
                           direction: .depression),
                CopingItem(domain: "睡眠", title: "睡眠時間の制限", stageRange: "+2〜+4",
                           description: "躁期は睡眠時間が短くなりがちです。最低6時間の睡眠を確保するルールを設けましょう。",
                           direction: .mania),
            ]
        ),
        CopingDomain(
            name: "活動",
            icon: "figure.walk",
            color: .green,
            items: [
                CopingItem(domain: "活動", title: "散歩（15分〜）", stageRange: "-2〜-4",
                           description: "鬱期の活動低下に対し、短時間の散歩から始めることが効果的です。",
                           direction: .depression),
                CopingItem(domain: "活動", title: "活動量の制限", stageRange: "+2〜+4",
                           description: "躁期は活動量が過剰になりがちです。1日の予定を3つ以内に絞りましょう。",
                           direction: .mania),
            ]
        ),
        CopingDomain(
            name: "飲酒",
            icon: "wineglass.fill",
            color: .pink,
            items: [
                CopingItem(domain: "飲酒", title: "飲酒量の記録", stageRange: "-3〜+3",
                           description: "飲酒は気分の波を増幅させます。毎日の飲酒量を記録しましょう。",
                           direction: .depression),
            ]
        ),
        CopingDomain(
            name: "服薬",
            icon: "pills.fill",
            color: .blue,
            items: [
                CopingItem(domain: "服薬", title: "服薬アラームの設定", stageRange: "-5〜+5",
                           description: "気分の状態に関わらず、服薬の継続が最も重要です。",
                           direction: .depression),
            ]
        ),
        CopingDomain(
            name: "マインドフルネス",
            icon: "brain.head.profile",
            color: .purple,
            items: [
                CopingItem(domain: "マインドフルネス", title: "呼吸法（4-7-8法）", stageRange: "-2〜-4",
                           description: "4秒吸って、7秒止めて、8秒で吐く呼吸法です。",
                           direction: .depression),
                CopingItem(domain: "マインドフルネス", title: "グラウンディング", stageRange: "+2〜+4",
                           description: "5つの見えるもの、4つの触れるもの...で「今」に意識を戻す技法です。",
                           direction: .mania),
            ]
        ),
        CopingDomain(
            name: "気分・認知",
            icon: "heart.text.square",
            color: .red,
            items: [
                CopingItem(domain: "気分・認知", title: "感謝日記（3つ書く）", stageRange: "-1〜-3",
                           description: "今日あった良いことを3つ書くことで、認知のバランスを取り戻しましょう。",
                           direction: .depression),
            ]
        ),
    ]
}
