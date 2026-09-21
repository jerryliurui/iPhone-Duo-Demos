import SwiftUI

struct CommentPanel: View {
    let article: Article
    @Bindable var library: ReadingLibrary
    @FocusState private var composing: Bool
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("一起讨论", systemImage: "bubble.left.and.bubble.right").font(.headline)
                Spacer()
                Text("\(library.comments(for: article).count)").monospacedDigit().foregroundStyle(.secondary)
            }.padding(18)
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(library.comments(for: article)) { comment in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: comment.isMine ? "person.crop.circle.fill" : "person.crop.circle")
                                .font(.title2).foregroundStyle(Palette.teal)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(comment.author).font(.caption.bold()).foregroundStyle(Palette.teal)
                                Text(comment.text).font(.subheadline).foregroundStyle(Palette.ink)
                            }
                        }
                    }
                    Text("虚构评论 · 发送仅保存在本机")
                        .font(.caption2).foregroundStyle(.secondary)
                }.padding(18)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("写下你的看法…", text: library.draft(for: article), axis: .vertical)
                    .lineLimit(2...5).focused($composing).accessibilityIdentifier("commentDraft")
                HStack {
                    Text("草稿自动保存").font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Button("发送") { library.postComment(for: article); composing = false }
                        .buttonStyle(.borderedProminent)
                        .disabled(library.drafts[article.id, default: ""].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("sendComment")
                }
            }.padding(14).background(.regularMaterial)
        }
        .background(.white).clipShape(RoundedRectangle(cornerRadius: 22)).padding(12)
    }
}
