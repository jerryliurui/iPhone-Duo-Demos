import SwiftUI

@main
struct FoldNotesApp: App {
    @State private var library = ReadingLibrary()
    var body: some Scene {
        WindowGroup {
            LibraryView(library: library)
                .tint(Palette.teal)
                .preferredColorScheme(.light)
        }
    }
}

enum Palette {
    static let paper = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let ink = Color(red: 0.10, green: 0.18, blue: 0.23)
    static let teal = Color(red: 0.08, green: 0.43, blue: 0.38)
    static let orange = Color(red: 0.82, green: 0.36, blue: 0.23)
}

struct Article: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let category: String
    let symbol: String
    let paragraphs: [String]
    var artwork: Int { Self.samples.firstIndex(where: { $0.id == id }) ?? 0 }
    static let samples: [Article] = [
        Article(id: "walk", title: "把城市读慢一点", subtitle: "一段没有目的地的午后散步", category: "城市观察", symbol: "building.2.crop.circle", paragraphs: [
            "离开熟悉的路线，城市会呈现另一种顺序。先注意树影，再注意转角的小店，最后才是地图上那个被收藏的目的地。",
            "我喜欢带一本很薄的笔记本。不是为了记录所有见闻，只写下值得停留的细节：窗台的一盆植物、旧招牌上的一行字、街口突然吹来的风。",
            "走到河边时，可以把今天的路线分成两段。一边回看刚才经过的街道，一边记下想留到下次的问题。阅读与记录，不必轮流发生。",
            "如果一条街让你愿意再走一遍，就已经足够。我们不一定需要更多目的地，有时只是需要更充裕的注意力。",
            "下次出门，选一个平时会直接经过的路口，慢下来看看。新的发现可能离生活很近。"
        ]),
        Article(id: "light", title: "留一束光在桌面", subtitle: "关于阅读角落的三个小决定", category: "生活片段", symbol: "sun.max", paragraphs: [
            "一个舒服的阅读角落不需要很多东西。一盏灯、一杯水，以及一张能把书展开的桌子，已经能让人安静一会儿。",
            "先调整光的位置，再调整自己的坐姿。让光落在纸面上，屏幕保持合适的亮度，不必用过亮的背景填满整个房间。",
            "把待办事项写在另一张纸上。阅读中冒出的想法有地方安放，就不必立刻中断正在读的段落。",
            "结束前只留一句笔记：今天哪句话值得再读？下次回来，这一句就是重新开始的入口。"
        ]),
        Article(id: "sea", title: "听见海岸的留白", subtitle: "在一段文字里停留片刻", category: "旅行随笔", symbol: "water.waves", paragraphs: [
            "潮水退下去以后，沙滩上会出现很多细小的纹路。站得远时，它们只是颜色；走近一点，才看见每一道纹路都有自己的方向。",
            "阅读也有这样的距离。先读完一段，知道它朝哪里走；再回到某一句，辨认那些容易被略过的细节。",
            "留白不是缺少内容。它给刚刚读到的东西一点时间，也让下一次出发变得更从容。"
        ]),
        Article(id: "garden", title: "屋顶上的小花园", subtitle: "一平方米也能种下四季", category: "生活片段", symbol: "leaf", paragraphs: ["在窗边留出一点空间，先种一盆容易照顾的植物。观察叶片的颜色，比急着寻找新工具更重要。", "每天浇水前先看一眼土壤。照顾植物也是练习等待，有些变化要过几天才看得见。", "这些文字用于演示内容阅读与评论布局，不是实际新闻报道。"]),
        Article(id: "library", title: "街角多了一间书店", subtitle: "为一次偶然的翻阅停下脚步", category: "城市观察", symbol: "books.vertical", paragraphs: ["街角的门窗被刷成了浅绿色。路过的人可以先翻两页书，再决定是否坐下来。", "书架并不高，光可以从窗边一直走到房间深处。一张长桌，让陌生人的阅读共享同一处安静。", "这是为适配Demo撰写的虚构短文，不对应真实商家或新闻事件。"]),
        Article(id: "design", title: "让工具退后一步", subtitle: "界面里的空间，应该留给什么", category: "设计手记", symbol: "square.stack", paragraphs: ["当页面上的按钮越来越多，先问问哪些操作是此刻必需的。把不常用的操作收进清楚的入口，内容才能有足够空间。", "一种布局是否合适，要在真实操作里判断。文字能否读完、输入会不会被挡住、退出后还能否回到刚才的位置，都值得亲手试一试。", "这里是原创演示文章。后续图文中的API结论以实际运行记录为准。"])
    ]
}

@Observable
final class ReadingLibrary {
    var adapted = true
    var favorites: Set<String>
    var notes: [String: String]
    var drafts: [String: String] = [:]
    var postedComments: [String: [ReaderComment]] = [:]
    var selected: Article.ID? = Article.samples.first?.id
    init() {
        favorites = Set(UserDefaults.standard.stringArray(forKey: "favorites") ?? ["walk"])
        if let data = UserDefaults.standard.data(forKey: "postedComments"), let saved = try? JSONDecoder().decode([String: [ReaderComment]].self, from: data) { postedComments = saved }
        drafts = UserDefaults.standard.dictionary(forKey: "commentDrafts") as? [String: String] ?? [:]
        notes = UserDefaults.standard.dictionary(forKey: "notes") as? [String: String] ?? [:]
    }
    func comments(for article: Article) -> [ReaderComment] {
        [ReaderComment(id: "c1", author: "读者 A", text: "喜欢这种慢下来的观察方式。", isMine: false),
         ReaderComment(id: "c2", author: "读者 B", text: "读到这里，也想把自己的想法记下来。", isMine: false),
         ReaderComment(id: "c3", author: "读者 C", text: "在不同的空间里，阅读也可以有不同节奏。", isMine: false)] + postedComments[article.id, default: []]
    }
    func draft(for article: Article) -> Binding<String> {
        Binding(get: { self.drafts[article.id, default: ""] }, set: {
            self.drafts[article.id] = $0
            UserDefaults.standard.set(self.drafts, forKey: "commentDrafts")
        })
    }
    func postComment(for article: Article) {
        let text = drafts[article.id, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        postedComments[article.id, default: []].append(ReaderComment(id: UUID().uuidString, author: "我", text: text, isMine: true))
        drafts[article.id] = ""
        UserDefaults.standard.set(try? JSONEncoder().encode(postedComments), forKey: "postedComments")
        UserDefaults.standard.set(drafts, forKey: "commentDrafts")
    }
    func toggleFavorite(_ article: Article) {
        if favorites.contains(article.id) { favorites.remove(article.id) }
        else { favorites.insert(article.id) }
        UserDefaults.standard.set(Array(favorites), forKey: "favorites")
    }
    func note(for article: Article) -> Binding<String> {
        Binding(get: { self.notes[article.id, default: ""] }, set: {
            self.notes[article.id] = $0
            UserDefaults.standard.set(self.notes, forKey: "notes")
        })
    }
}

struct PaperArtwork: View {
    var compact = false
    var bend: Double = 0
    var variant: Int = 0
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                (variant.isMultiple(of: 2) ? Palette.teal : Palette.orange).opacity(0.10)
                Circle().fill(Color(red: 0.95, green: 0.71, blue: 0.43))
                    .frame(width: proxy.size.height * 0.6)
                    .offset(x: proxy.size.width * 0.26, y: -proxy.size.height * 0.18)
                HStack(spacing: 4) {
                    ForEach(0..<7) { i in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(i.isMultiple(of: 2) ? Palette.teal : Palette.teal.opacity(0.65))
                            .frame(width: proxy.size.width / 11, height: proxy.size.height * (0.28 + Double((i * 3 + variant) % 5) * 0.075))
                            .rotationEffect(.degrees(bend * Double(i - 3) * 0.08), anchor: .bottom)
                    }
                }.frame(maxHeight: .infinity, alignment: .bottom).padding(.bottom, 20)
                VStack(alignment: .leading, spacing: 4) {
                    Text("FIELD NOTES").font(.caption2.monospaced().weight(.bold)).tracking(3)
                    if !compact { Text("在日常里\n发现新的视角").font(.title3.weight(.semibold)) }
                }.foregroundStyle(Palette.ink).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(20)
            }.clipShape(RoundedRectangle(cornerRadius: 20))
        }.frame(height: compact ? 100 : 190)
        .accessibilityLabel("城市几何插画")
    }
}

struct ReaderComment: Identifiable, Codable {
    let id: String
    let author: String
    let text: String
    let isMine: Bool
}
