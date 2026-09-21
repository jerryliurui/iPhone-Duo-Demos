import SwiftUI
import Combine

@main struct DuelClockApp: App {
    var body: some Scene { WindowGroup { ClockView() } }
}


struct ClockView: View {
    @State private var clock = MatchClock()
    @State private var adapted = true
    @State private var opposing = true
    @State private var resetPrompt = false
    @Environment(\.scenePhase) private var scenePhase
    private let pulse = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    private let ink = Color(red: 0.10, green: 0.16, blue: 0.18)
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label("对弈钟", systemImage: "timer").font(.headline)
                Spacer()
                Menu {
                    Toggle("启用适配", isOn: $adapted)
                    Toggle("面对面", isOn: $opposing)
                } label: { Image(systemName: "slider.horizontal.3").frame(width:44,height:44) }
                .accessibilityLabel("布局设置")
            }
            if adapted {
                ArrangementView { player(0) } secondary: { player(1) }
                    .arrangementViewStyle(.split)
            } else {
                VStack(spacing:12) { player(0); player(1) }
            }
            HStack(spacing: 16) {
                Button { resetPrompt = true } label: { Label("重置",systemImage:"arrow.counterclockwise").frame(minHeight:44) }
                Spacer()
                Text("3 分钟 · 无加秒").font(.caption).foregroundStyle(ink.opacity(0.7))
                Spacer()
                Button { clock.active == nil ? clock.resume() : clock.pause() } label: {
                    Label(clock.active == nil ? "继续" : "暂停",systemImage:clock.active == nil ? "play.fill" : "pause.fill").frame(minHeight:44)
                }.disabled(clock.expired != nil || !clock.started)
            }.font(.subheadline.weight(.semibold))
        }.padding(16).background(Color(red:0.94,green:0.94,blue:0.90)).foregroundStyle(ink)
            .tint(ink).preferredColorScheme(.light)
            .onReceive(pulse) { _ in clock.update() }
            .onChange(of: scenePhase) { _, phase in if phase != .active { clock.pause() } }
            .confirmationDialog("重置这局对弈？", isPresented: $resetPrompt, titleVisibility:.visible) {
                Button("重新开始",role:.destructive) { clock.reset() }
            }
    }
    private func player(_ side: Int) -> some View {
        Button { clock.press(side) } label: {
            VStack(spacing: 10) {
                HStack {
                    Label(side == 0 ? "白方" : "黑方",systemImage:side == 0 ? "circle" : "circle.fill")
                    Spacer()
                    Text("\(clock.moves[side]) 手").monospacedDigit()
                }.font(.subheadline.weight(.medium))
                Spacer(minLength:0)
                Text(time(clock.remaining[side]))
                    .font(.system(size:100,weight:.medium,design:.rounded)).monospacedDigit().minimumScaleFactor(0.4).lineLimit(1)
                Text(status(side)).font(.subheadline.weight(.semibold))
                Spacer(minLength:0)
                HStack(spacing:4) {
                    ForEach(0..<12) { tick in Capsule().fill((Double(tick)/12 < clock.remaining[side]/180 ? ink : ink.opacity(0.12))).frame(height:4) }
                }.accessibilityHidden(true)
            }.padding(24).rotationEffect(.degrees(adapted && opposing && side == 0 ? 180 : 0))
                .frame(maxWidth:.infinity,maxHeight:.infinity)
                .background(side == 0 ? Color(red:0.89,green:0.72,blue:0.41) : Color(red:0.68,green:0.79,blue:0.73),in:RoundedRectangle(cornerRadius:28))
                .overlay { RoundedRectangle(cornerRadius:28).strokeBorder(ink.opacity(clock.active == side ? 0.9 : 0),lineWidth:3) }
        }.buttonStyle(.plain).accessibilityLabel("\(side == 0 ? "白方" : "黑方")，\(time(clock.remaining[side]))，\(status(side))")
    }
    private func time(_ seconds: Double) -> String { let value=Int(ceil(seconds)); return String(format:"%02d:%02d",value/60,value%60) }
    private func status(_ side: Int) -> String {
        if let expired=clock.expired { return expired == side ? "时间到" : "本局结束" }
        if !clock.started { return "轻触，先行" }
        return clock.active == side ? "你的回合 · 轻触交棒" : clock.active == nil ? "已暂停" : "等待对方"
    }
}
