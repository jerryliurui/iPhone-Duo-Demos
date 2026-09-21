import SwiftUI

struct LibraryView: View {
    @Bindable var library: ReadingLibrary
    @State private var search = ""
    @State private var waterfall = false
    @ScaledMetric(relativeTo: .body) private var minimumCardWidth = 155
    @Environment(\.layoutDirection) private var layoutDirection
    @State private var favoritesOnly = false
    @State private var showLab = false
    @State private var feedAnchor: String?
    private var articles: [Article] {
        (waterfall ? Article.waterfallSamples : Article.samples).filter {
            (!favoritesOnly || library.favorites.contains($0.id)) &&
            (search.isEmpty || ($0.title + $0.subtitle + $0.category).localizedCaseInsensitiveContains(search))
        }
    }
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let columns = library.adapted && proxy.size.width >= 680 ? 2 : 1
                let waterfallColumns = WaterfallPolicy.columns(width: max(0, proxy.size.width - 40), minimumWidth: minimumCardWidth, adapted: library.adapted)
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("读一点，世界大一点。")
                            .font(.largeTitle.bold()).foregroundStyle(Palette.ink)
                        Text(waterfall ? "不同的内容，不必有相同的高度。" : "城市 · 设计 · 生活里的新发现")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Picker("内容呈现", selection: $waterfall) {
                            Text("精选").tag(false)
                            Text("瀑布流").tag(true)
                        }.pickerStyle(.segmented).padding(.top, 12)
                            .accessibilityIdentifier("feedPresentation")
                        HStack(spacing: 8) {
                            Text(waterfall ? "\(waterfallColumns) 列瀑布流" : "今日精选").foregroundStyle(.white).padding(.horizontal, 14).padding(.vertical, 7).background(Palette.teal, in: Capsule())
                            Text(library.adapted ? "适配实现 · 本地演示" : "基础实现 · 本地演示").foregroundStyle(.secondary)
                        }.font(.caption).padding(.top, 12)
                    }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
                    if waterfall {
                        WaterfallLayout(columns: waterfallColumns, spacing: 12, rightToLeft: layoutDirection == .rightToLeft) {
                            ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                                NavigationLink(value: article) {
                                    WaterfallCard(article: article, isFavorite: library.favorites.contains(article.id))
                                }.buttonStyle(.plain).id(article.id)
                                    .accessibilitySortPriority(Double(articles.count - index))
                            }
                        }.scrollTargetLayout().padding(.horizontal, 20).padding(.bottom, 24)
                    } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 18, alignment: .top), count: columns), spacing: 18) {
                        ForEach(articles) { article in
                            NavigationLink(value: article) {
                                FeedCard(article: article, isFavorite: library.favorites.contains(article.id))
                            }.buttonStyle(.plain).id(article.id)
                        }
                    }.scrollTargetLayout().padding(.horizontal, 20).padding(.bottom, 24)
                    }
                    if articles.isEmpty {
                        ContentUnavailableView("没有找到内容", systemImage: "magnifyingglass", description: Text("试试其他关键词，或查看全部文章。"))
                    }
                    Text("演示文章与评论均为虚构内容")
                        .font(.caption2).foregroundStyle(.secondary).padding(.bottom, 24)
                }
                .scrollPosition(id: $feedAnchor, anchor: .top)
                .background(Palette.paper)
            }
            .navigationTitle("折页")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "搜索文章或分类")
            .navigationDestination(for: Article.self) { ReaderView(article: $0, library: library) }
            .toolbar {
                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        Toggle("启用适配", isOn: $library.adapted)
                        Text(waterfall ? "基础实现：固定两列，大字号保留可读性回退" : "基础实现：单列内容流、固定双区域布局")
                        Text(waterfall ? "适配实现：按可用宽度排列，最多四列" : "适配实现：随可用空间排列、使用 arrangement")
                    } label: { Label(library.adapted ? "适配实现" : "基础实现", systemImage: "arrow.left.arrow.right") }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { favoritesOnly.toggle() } label: {
                        Label(favoritesOnly ? "全部文章" : "仅看收藏", systemImage: favoritesOnly ? "square.grid.2x2" : "bookmark")
                    }.accessibilityIdentifier("favoritesFilter")
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button { showLab = true } label: { Label("布局观察", systemImage: "viewfinder") }
                        .accessibilityIdentifier("openLab")
                }
            }
        }
        .fullScreenCover(isPresented: $showLab) { RegionLabView() }
    }
}

struct FeedCard: View {
    let article: Article
    let isFavorite: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            PaperArtwork(compact: true, variant: article.artwork)
            HStack {
                Text(article.category).font(.caption.weight(.semibold)).foregroundStyle(Palette.teal)
                Spacer()
                if isFavorite { Image(systemName: "bookmark.fill").foregroundStyle(Palette.orange) }
            }
            Text(article.title).font(.title3.bold()).foregroundStyle(Palette.ink)
            Text(article.subtitle).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
            HStack {
                Label("折页编辑部", systemImage: "leaf")
                Spacer()
                Label("3", systemImage: "bubble.right")
            }.font(.caption2).foregroundStyle(.secondary)
        }.padding(16).background(.white, in: RoundedRectangle(cornerRadius: 24))
    }
}

enum ReadingMode: String, CaseIterable, Identifiable {
    case read = "阅读", notes = "正文与讨论", controls = "阅读控制"
    var id: Self { self }
}

struct ReaderView: View {
    let article: Article
    @Bindable var library: ReadingLibrary
    @State private var mode: ReadingMode = .read
    @State private var textSize: Double = 18
    @State private var horizontalOnly = false
    @State private var paragraphAnchor: Int?
    @State private var showLab = false
    @State private var showInfo = false
    @State private var showNoteSheet = false
    @State private var showCommentsSheet = false

    var body: some View {
        Group {
            switch mode {
            case .read: articleBody
            case .notes:
                if !library.adapted {
                    HStack(spacing: 0) {
                        articleBody.frame(maxWidth: .infinity)
                        CommentPanel(article: article, library: library).frame(maxWidth: .infinity)
                    }
                } else if horizontalOnly {
                    pairedContent.arrangementViewStyle(.split.axes(.horizontal))
                } else { pairedContent.arrangementViewStyle(.split) }
            case .controls:
                if !library.adapted {
                    ZStack(alignment: .bottom) {
                        articleBody
                        ReadingControls(textSize: $textSize, baseline: true)
                    }
                } else {
                ArrangementView {
                    ReadingControls(textSize: $textSize)
                        .overlayArrangementEdge(.bottom)
                } secondary: {
                    articleBody
                }.arrangementViewStyle(.overlay)
                }
            }
        }
        .background(Palette.paper)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                Text(library.adapted ? "适配实现" : "基础实现")
                Text("·")
                Text(mode.rawValue)
                Spacer()
                Text("虚构演示内容")
            }.font(.caption2).foregroundStyle(.secondary)
                .padding(.horizontal, 16).padding(.vertical, 6)
                .background(Palette.paper)
        }
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { library.toggleFavorite(article) } label: {
                    Label(library.favorites.contains(article.id) ? "取消收藏" : "收藏", systemImage: library.favorites.contains(article.id) ? "bookmark.fill" : "bookmark")
                }.accessibilityIdentifier("toggleFavorite")
            }.visibilityPriority(.high)
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Toggle("启用适配", isOn: $library.adapted)
                    Divider()
                    Picker("阅读方式", selection: $mode) {
                        ForEach(ReadingMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    if mode == .notes { Toggle("仅允许水平排列", isOn: $horizontalOnly) }
                } label: { Label("阅读方式", systemImage: "rectangle.split.2x1") }
                .accessibilityIdentifier("readingMode")
            }.visibilityPriority(.high)
            ToolbarItem(placement: .primaryAction) {
                Button { showNoteSheet = true } label: { Label("随手记", systemImage: "square.and.pencil") }
                    .accessibilityIdentifier("openNote")
            }
            ToolbarItem(placement: .primaryAction) {
                Button { showCommentsSheet = true } label: { Label("评论", systemImage: "bubble.right") }
                    .badge(library.comments(for: article).count)
                    .accessibilityIdentifier("openComments")
            }.visibilityPriority(.high)
            ToolbarItem(placement: .secondaryAction) {
                ShareLink(item: article.title + "\n" + article.paragraphs.joined(separator: "\n\n")) {
                    Label("分享文章", systemImage: "square.and.arrow.up")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button { showLab = true } label: { Label("布局观察", systemImage: "viewfinder") }
            }
            ToolbarOverflowMenu {
                Button { showInfo = true } label: { Label("关于演示内容", systemImage: "info.circle") }
            }
        }
        .fullScreenCover(isPresented: $showLab) { RegionLabView() }
        .sheet(isPresented: $showCommentsSheet) {
            NavigationStack {
                CommentPanel(article: article, library: library)
                    .navigationTitle("讨论")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showCommentsSheet = false } } }
            }
        }
        .sheet(isPresented: $showNoteSheet) {
            NavigationStack {
                NotePanel(text: library.note(for: article), title: article.title)
                    .navigationTitle("随手记")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showNoteSheet = false } } }
            }
        }
        .alert("关于折页", isPresented: $showInfo) {
            Button("知道了", role: .cancel) {}
        } message: { Text("用于 Duo 适配实验的离线阅读 Demo。文章为原创演示内容，笔记与收藏保存在本机。") }
        .id(article.id)
    }
    private var pairedContent: some View {
        ArrangementView { articleBody } secondary: {
            CommentPanel(article: article, library: library)
        }
    }
    private var articleBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Text(article.category.uppercased()).font(.caption.weight(.bold)).tracking(2)
                    Spacer()
                    Text("原创演示文章").font(.caption2.monospaced())
                }.foregroundStyle(Palette.teal)
                Text(article.title).font(.largeTitle.bold()).foregroundStyle(Palette.ink)
                Text(article.subtitle).font(.subheadline).foregroundStyle(.secondary)
                PaperArtwork(variant: article.artwork)
                ForEach(Array(article.paragraphs.enumerated()), id: \.offset) { index, paragraph in
                    Text(paragraph).font(.system(size: textSize, design: .serif))
                        .lineSpacing(9).foregroundStyle(Palette.ink)
                        .id(index)
                }
                Divider()
                Label("把此刻的想法，留在随手记里。", systemImage: "pencil.line")
                    .font(.subheadline).foregroundStyle(Palette.teal)
            }.scrollTargetLayout().padding(24).frame(maxWidth: 660).frame(maxWidth: .infinity)
        }.scrollPosition(id: $paragraphAnchor, anchor: .top).background(Palette.paper)
    }
}

struct NotePanel: View {
    @Binding var text: String
    let title: String
    @Environment(\.splitArrangementAxis) private var axis
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("随手记", systemImage: "pencil.and.list.clipboard").font(.headline)
                Spacer()
                Text("本机保存").font(.caption2).foregroundStyle(.secondary)
            }
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            ZStack(alignment: .topLeading) {
                if text.isEmpty { Text("哪一句，让你停了一下？\n写下你的想法……").foregroundStyle(.tertiary).padding(.top, 8).padding(.leading, 5).allowsHitTesting(false) }
                TextEditor(text: $text).scrollContentBackground(.hidden)
                    .accessibilityIdentifier("noteEditor")
            }.font(.body).frame(minHeight: 100)
            Text("\(text.count) 字").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
        }
        .padding(22).background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 22)).padding(12)
    }
}

struct ReadingControls: View {
    @Binding var textSize: Double
    var baseline = false
    @Environment(\.overlayArrangementZIndex) private var zIndex
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("阅读设置", systemImage: "textformat.size").font(.headline)
            HStack {
                Text("字号")
                Slider(value: $textSize, in: 15...26, step: 1).accessibilityLabel("阅读字号")
                Text("\(Int(textSize))").monospacedDigit()
            }
            if !baseline && zIndex <= 0 {
                Divider()
                Text("找到舒服的阅读节奏").font(.title3.bold())
                Text("调整到适合你的字号。这里的设置会持续作用于同一篇文章。").font(.subheadline).foregroundStyle(.secondary)
            }
        }.padding(20)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: baseline || zIndex > 0 ? 360 : .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        .padding(16)
    }
}
