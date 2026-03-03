//
//  CopingLibraryView.swift
//  BipolarAI
//
//  Created on 2026-03-04
//  Coping library view with domain-based explanations
//

import SwiftUI

/// コーピングの方向フィルタ
enum CopingDirection: String, CaseIterable {
    case all = "全て"
    case depression = "鬱方向"
    case mania = "躁方向"
}

/// コーピングアイテム
struct CopingItem: Identifiable {
    let id = UUID()
    let title: String
    let stageRange: String    // "-3〜-5" or "+2〜+4"
    let description: String
    let direction: CopingDirection  // .depression or .mania
}

/// コーピングドメイン
struct CopingDomain: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let items: [CopingItem]
}

/// コーピング一覧画面
struct CopingLibraryView: View {
    @State private var filter: CopingDirection = .all
    @State private var expandedDomains: Set<String> = []

    private let domains: [CopingDomain] = CopingLibraryData.allDomains

    var body: some View {
        NavigationView {
            List {
                // フィルタ
                Section {
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
        }
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

// MARK: - コーピングデータ（組み込み）

struct CopingLibraryData {
    static let allDomains: [CopingDomain] = [
        // 睡眠
        CopingDomain(
            name: "睡眠",
            icon: "bed.double.fill",
            color: .indigo,
            items: [
                CopingItem(
                    title: "起床時間の固定",
                    stageRange: "-3〜-5",
                    description: "鬱期は過眠傾向になりやすいため、まず起床時間を固定することで体内時計のリズムを整えます。無理に早起きする必要はなく、毎日同じ時間に起きることが重要です。",
                    direction: .depression
                ),
                CopingItem(
                    title: "昼間入浴",
                    stageRange: "-2〜-4",
                    description: "鬱期に活動量が落ちている場合、昼間の入浴で体温を上げることで覚醒を促します。ぬるめのお湯に15分程度が目安です。",
                    direction: .depression
                ),
                CopingItem(
                    title: "サプリ/コーヒーで起床補助",
                    stageRange: "-2〜-4",
                    description: "起床時にカフェインやビタミンBを摂取することで、朝の覚醒を助けます。ただし午後のカフェインは睡眠に影響するため避けましょう。",
                    direction: .depression
                ),
                CopingItem(
                    title: "睡眠時間の制限",
                    stageRange: "+2〜+4",
                    description: "躁期は睡眠時間が短くなりがちです。最低6時間の睡眠を確保するルールを設け、就寝時間を固定しましょう。寝室の環境を暗くし、刺激を減らすことが重要です。",
                    direction: .mania
                ),
                CopingItem(
                    title: "就寝前のルーティン確立",
                    stageRange: "+1〜+3",
                    description: "躁傾向の時は興奮状態で眠れないことがあります。就寝1時間前からスマホを避け、読書や深呼吸などのリラックスルーティンを設けましょう。",
                    direction: .mania
                ),
            ]
        ),

        // 活動
        CopingDomain(
            name: "活動",
            icon: "figure.walk",
            color: .green,
            items: [
                CopingItem(
                    title: "散歩（15分〜）",
                    stageRange: "-2〜-4",
                    description: "鬱期の活動低下に対し、短時間の散歩から始めることが効果的です。朝の日光を浴びることでセロトニン分泌が促進されます。まずは15分、玄関の外に出ることだけを目標にしましょう。",
                    direction: .depression
                ),
                CopingItem(
                    title: "最低限の家事タスク",
                    stageRange: "-3〜-5",
                    description: "重度の鬱期には「シャワーを浴びる」「食器を1つ洗う」など、最小限のタスクを1つだけ設定します。達成することで自己効力感を維持できます。",
                    direction: .depression
                ),
                CopingItem(
                    title: "活動量の制限・予定の間引き",
                    stageRange: "+2〜+4",
                    description: "躁期は活動量が過剰になりがちです。1日の予定を3つ以内に絞り、休息時間を意識的に確保しましょう。「やりたい」と思ったことの半分に留めるルールが有効です。",
                    direction: .mania
                ),
                CopingItem(
                    title: "衝動的な判断の保留",
                    stageRange: "+3〜+5",
                    description: "躁期の高揚感で大きな決断（転職、高額購入、新規プロジェクト開始など）をしがちです。重要な判断は48時間以上保留し、信頼できる人に相談してから決めましょう。",
                    direction: .mania
                ),
            ]
        ),

        // 飲酒
        CopingDomain(
            name: "飲酒",
            icon: "wineglass.fill",
            color: .pink,
            items: [
                CopingItem(
                    title: "飲酒量の記録と意識化",
                    stageRange: "-3〜+3",
                    description: "飲酒は気分の波を増幅させます。毎日の飲酒量を記録することで自覚を促し、週の総量を把握できます。このアプリのHealthKit連携で自動記録されます。",
                    direction: .depression
                ),
                CopingItem(
                    title: "ノンアルコール代替",
                    stageRange: "-2〜+2",
                    description: "飲酒習慣がある場合、ノンアルコールビールやハーブティーに置き換えることで、飲酒の儀式的側面を維持しながら摂取量を減らせます。",
                    direction: .depression
                ),
                CopingItem(
                    title: "飲酒の上限設定",
                    stageRange: "+2〜+4",
                    description: "躁期は飲酒量が増える傾向があります。1日2杯以内のルールを事前に決めておき、それを超えたらアプリのDangerスコアに反映されます。",
                    direction: .mania
                ),
            ]
        ),

        // 服薬
        CopingDomain(
            name: "服薬",
            icon: "pills.fill",
            color: .blue,
            items: [
                CopingItem(
                    title: "服薬アラームの設定",
                    stageRange: "-5〜+5",
                    description: "気分の状態に関わらず、服薬の継続が最も重要です。朝と夕の服薬タイミングにアラームを設定し、このアプリで服薬記録を付けましょう。連続ミスはDangerスコアに影響します。",
                    direction: .depression
                ),
                CopingItem(
                    title: "主治医への状態報告",
                    stageRange: "-4〜-5",
                    description: "重度の鬱状態では薬の調整が必要な場合があります。NetStageが-4以下が3日以上続く場合は、このアプリの履歴を主治医に見せて相談しましょう。",
                    direction: .depression
                ),
                CopingItem(
                    title: "自己判断での減薬・断薬の防止",
                    stageRange: "+3〜+5",
                    description: "躁期は「もう薬は必要ない」と感じやすいですが、これは躁状態の典型的な認知です。必ず主治医と相談してから薬の変更を行ってください。",
                    direction: .mania
                ),
            ]
        ),

        // マインドフルネス
        CopingDomain(
            name: "マインドフルネス",
            icon: "brain.head.profile",
            color: .purple,
            items: [
                CopingItem(
                    title: "呼吸法（4-7-8法）",
                    stageRange: "-2〜-4",
                    description: "4秒吸って、7秒止めて、8秒で吐く呼吸法です。副交感神経を活性化させ、不安や焦燥感を緩和します。1日3回、各5分を目標にしましょう。HealthKitのマインドフルネスに記録されます。",
                    direction: .depression
                ),
                CopingItem(
                    title: "ボディスキャン瞑想",
                    stageRange: "-1〜-3",
                    description: "頭のてっぺんから足先まで、順番に体の感覚に注意を向ける瞑想法です。身体の緊張や不快感に気づき、リラックスを促します。10分〜15分が目安です。",
                    direction: .depression
                ),
                CopingItem(
                    title: "グラウンディング（5-4-3-2-1法）",
                    stageRange: "+2〜+4",
                    description: "躁状態での思考の加速を抑えるため、5つの見えるもの、4つの触れるもの、3つの聞こえるもの、2つの匂い、1つの味を順番に意識します。「今この瞬間」に意識を戻す技法です。",
                    direction: .mania
                ),
                CopingItem(
                    title: "歩行瞑想",
                    stageRange: "+1〜+3",
                    description: "躁傾向でじっとしていられない場合、歩行しながらの瞑想が効果的です。足の裏の感覚、歩くリズム、呼吸に集中しながらゆっくり歩きます。",
                    direction: .mania
                ),
            ]
        ),

        // 気分・認知
        CopingDomain(
            name: "気分・認知",
            icon: "heart.text.square",
            color: .red,
            items: [
                CopingItem(
                    title: "感謝日記（3つ書く）",
                    stageRange: "-1〜-3",
                    description: "鬱傾向の時はネガティブな思考が支配的になります。就寝前に今日あった良いことを3つ書くことで、認知のバランスを取り戻す練習になります。小さなことで構いません。",
                    direction: .depression
                ),
                CopingItem(
                    title: "認知の歪みチェック",
                    stageRange: "-2〜-4",
                    description: "「全か無か思考」「過度の一般化」「マイナス化思考」など、認知の歪みパターンに気づくことが第一歩です。ジャーナルに書いた内容を振り返り、歪みがないかチェックしてみましょう。",
                    direction: .depression
                ),
                CopingItem(
                    title: "主観と客観のズレ確認",
                    stageRange: "+2〜+4",
                    description: "このアプリのSubjStageとObjStageの差（Gap）が大きい場合、自己認識と客観データにズレがあります。Gapが2以上の場合は、自分の状態を過小/過大評価している可能性があります。",
                    direction: .mania
                ),
            ]
        ),
    ]
}
