import SwiftUI

// Container width, not device identity, determines density.
enum WaterfallPolicy {
    static func columns(width: CGFloat, minimumWidth: CGFloat, adapted: Bool) -> Int {
        let available = max(1, Int((max(0, width) + 12) / (max(1, minimumWidth) + 12)))
        return min(adapted ? 4 : 2, available)
    }
}

// Small offline demo: measure every card. This is not a virtualized news feed.
struct WaterfallLayout: Layout {
    var columns: Int
    var spacing: CGFloat
    var rightToLeft = false

    private func frames(width: CGFloat, subviews: Subviews) -> [CGRect] {
        let count = max(1, columns)
        let columnWidth = max(1, (width - CGFloat(count - 1) * spacing) / CGFloat(count))
        var bottoms = Array(repeating: CGFloat.zero, count: count)
        return subviews.map { view in
            let column = bottoms.indices.min { bottoms[$0] < bottoms[$1] } ?? 0
            let height = view.sizeThatFits(.init(width: columnWidth, height: nil)).height
            let visualColumn = rightToLeft ? count - 1 - column : column
            let rect = CGRect(x: CGFloat(visualColumn) * (columnWidth + spacing),
                              y: bottoms[column], width: columnWidth, height: height)
            bottoms[column] = rect.maxY + spacing
            return rect
        }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        return CGSize(width: width, height: frames(width: width, subviews: subviews).map(\.maxY).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (view, rect) in zip(subviews, frames(width: bounds.width, subviews: subviews)) {
            view.place(at: CGPoint(x: bounds.minX + rect.minX, y: bounds.minY + rect.minY),
                       anchor: .topLeading, proposal: .init(width: rect.width, height: rect.height))
        }
    }
}

struct WaterfallCard: View {
    let article: Article
    let isFavorite: Bool
    private var index: Int { Article.waterfallSamples.firstIndex(where: { $0.id == article.id }) ?? 0 }
    private var ratio: CGFloat { [0.78, 1.35, 1.0, 0.9, 1.5, 0.72][index % 6] }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                (index.isMultiple(of: 2) ? Palette.teal : Palette.orange).opacity(0.13)
                GeometryReader { proxy in
                    Circle().fill(Color(red: 0.96, green: 0.73, blue: 0.44))
                        .frame(width: proxy.size.width * 0.68)
                        .offset(x: proxy.size.width * 0.42, y: -proxy.size.width * 0.2)
                    Image(systemName: article.symbol).resizable().scaledToFit()
                        .foregroundStyle(index.isMultiple(of: 2) ? Palette.teal : Palette.orange)
                        .frame(width: proxy.size.width * 0.46, height: proxy.size.height * 0.48)
                        .position(x: proxy.size.width * 0.48, y: proxy.size.height * 0.54)
                }
            }.aspectRatio(ratio, contentMode: .fit).clipped()
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .top) {
                    Text(article.category).font(.caption2.weight(.semibold)).foregroundStyle(Palette.teal)
                    Spacer(minLength: 2)
                    if isFavorite { Image(systemName: "bookmark.fill").foregroundStyle(Palette.orange) }
                }
                Text(article.title).font(.headline).foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(article.subtitle).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Label("折页编辑部", systemImage: "leaf").font(.caption2).foregroundStyle(.secondary)
            }.padding(12)
        }
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("waterfall.\(article.id)")
    }
}

extension Article {
    static let waterfallSamples = samples + [
        Article(id: "rain", title: "等雨停，也是一种散步", subtitle: "在屋檐下重新观察街道", category: "城市观察", symbol: "cloud.rain", paragraphs: ["雨把路人的脚步聚在屋檐下。借这一小段等待，看一看平时匆匆走过的街道。", "这是离线演示短文，不对应真实新闻。"]),
        Article(id: "cup", title: "一杯咖啡的空白时间", subtitle: "把屏幕放下十分钟", category: "生活片段", symbol: "cup.and.saucer", paragraphs: ["水烧开的声音，可以成为休息的提醒。今天先不安排更多事，给自己留十分钟。"]),
        Article(id: "train", title: "靠窗的位置", subtitle: "沿途的风景，和没读完的那一页", category: "旅行随笔", symbol: "tram", paragraphs: ["书页与窗外的风景交替出现，旅途也就有了自己的节奏。", "这是为适配演示撰写的虚构内容，不包含个人行程。"]),
        Article(id: "camera", title: "只拍一个颜色", subtitle: "给今天的观察设一道小题", category: "设计手记", symbol: "camera.aperture", paragraphs: ["试着只寻找一种颜色。限制少一点选择，却可能让人多发现一些细节。"]),
        Article(id: "night", title: "夜色里的一小段路", subtitle: "灯亮起来之后，熟悉的街道也变了", category: "城市观察", symbol: "moon.stars", paragraphs: ["店门陆续关上，窗里的光让道路有了新的轮廓。"]),
        Article(id: "music", title: "把一首歌听完", subtitle: "留一段没有下一步的时间", category: "生活片段", symbol: "headphones", paragraphs: ["不切换，也不急着收藏。让一首歌从头走到尾。"])
    ]
}
