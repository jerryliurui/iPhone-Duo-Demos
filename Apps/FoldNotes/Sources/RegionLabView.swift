import SwiftUI

struct RegionLabView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var includeInactive = false
    @State private var showOcclusion = false
    @State private var rtl = false
    @State private var hinge: DeviceHinge?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let divisions = proxy.reservedRegions(kind: .division, options: includeInactive ? .includeInactive : [])
                let occlusions = proxy.reservedRegions(kind: .occlusion, options: includeInactive ? .includeInactive : [])
                let regions = showOcclusion ? occlusions : divisions
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("让看不见的区域，变得可观察。")
                            .font(.title2.bold()).foregroundStyle(Palette.ink)
                        Text("边框直接来自当前视图的系统查询结果；没有返回区域时，不画替代框。")
                            .font(.subheadline).foregroundStyle(.secondary)
                        // Everything a layout can actually read about the current posture, in one place.
                        VStack(alignment: .leading, spacing: 6) {
                            Text("环境识别").font(.headline)
                            Text("内容区 \(Int(proxy.size.width)) × \(Int(proxy.size.height)) pt · \(proxy.size.width > proxy.size.height ? "横向" : "纵向")")
                            Text("sizeClass  横 \(className(horizontalSizeClass))  ·  竖 \(className(verticalSizeClass))")
                            Text("hinge  \(hinge.map { "\(statusName($0))  \(Int($0.angle.degrees.rounded()))°" } ?? "无数据")")
                            Text("division  active \(proxy.reservedRegions(kind: .division).count)  ·  含 inactive \(proxy.reservedRegions(kind: .division, options: .includeInactive).count)")
                        }
                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                        .accessibilityElement(children: .combine)
                        Picker("区域类型", selection: $showOcclusion) {
                            Text("division").tag(false)
                            Text("occlusion").tag(true)
                        }.pickerStyle(.segmented)
                        Toggle("包含 inactive 区域", isOn: $includeInactive)
                        Toggle("RTL 布局", isOn: $rtl)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("当前内容区 \(Int(proxy.size.width)) × \(Int(proxy.size.height)) pt").font(.headline)
                            Text("默认查询：\(proxy.reservedRegions(kind: showOcclusion ? .occlusion : .division).count)  ·  includeInactive：\(proxy.reservedRegions(kind: showOcclusion ? .occlusion : .division, options: .includeInactive).count)")
                            ForEach(regions) { region in
                                Text("\(region.isActive ? "active" : "inactive")  x:\(Int(region.frame.minX)) y:\(Int(region.frame.minY))\n宽:\(Int(region.frame.width)) 高:\(Int(region.frame.height)) pt")
                                    .font(.caption.monospaced())
                            }
                            if regions.isEmpty { Text("当前查询没有返回区域").foregroundStyle(.secondary) }
                        }.font(.caption).padding(16).frame(maxWidth: .infinity, alignment: .leading)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16))
                        Text("铰链是交互输入").font(.headline)
                        if let hinge {
                            Text("\(hinge.angle.degrees, specifier: "%.1f")° · \(statusName(hinge))")
                                .font(.headline.monospacedDigit())
                        } else { Text("当前视图没有可用的铰链数据").foregroundStyle(.secondary) }
                        PaperArtwork(bend: artworkBend)
                            .animation(.easeOut(duration: 0.12), value: artworkBend)
                        Text("角度只改变上方插画，不决定正文布局。半展开时响应最明显，闭合与完全展开时平滑复位。")
                            .font(.footnote).foregroundStyle(.secondary)
                    }.padding(22)
                }
                .overlay(alignment: .topLeading) {
                    ForEach(regions) { region in
                        Rectangle().fill((showOcclusion ? Palette.orange : Palette.teal).opacity(0.13))
                            .border(showOcclusion ? Palette.orange : Palette.teal, width: 2)
                            .frame(width: max(region.frame.width, 1), height: max(region.frame.height, 1))
                            .position(x: region.frame.midX, y: region.frame.midY)
                    }
                    .allowsHitTesting(false)
                }
            }
            .background(Palette.paper)
            .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight)
            .onHingeChange { _, context in hinge = context.hinge }
            .navigationTitle("布局观察")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
        }
    }
    // Both endpoints have zero bend and zero slope. Never feed the raw opening
    // angle into the artwork: nearly 180 degrees must approach the fully-open pose.
    private var artworkBend: Double {
        guard let hinge, hinge.status == .partiallyOpen else { return 0 }
        let degrees = hinge.angle.degrees
        guard degrees.isFinite else { return 0 }
        let progress = min(max(degrees / 180, 0), 1)
        let response = sin(progress * .pi)
        return 120 * response * response
    }

    private func className(_ sizeClass: UserInterfaceSizeClass?) -> String {
        switch sizeClass {
        case .compact: return "compact"
        case .regular: return "regular"
        default: return "unknown"
        }
    }

    private func statusName(_ hinge: DeviceHinge) -> String {
        if hinge.status == .partiallyOpen { return "partiallyOpen" }
        if hinge.status == .fullyOpen { return "fullyOpen" }
        if hinge.status == .closed { return "closed" }
        return "unknown"
    }
}
