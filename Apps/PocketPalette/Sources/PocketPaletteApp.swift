import SwiftUI

@main struct PocketPaletteApp: App { var body: some Scene { WindowGroup { PaletteView() } } }
struct InkStroke { var points:[CGPoint]; var color:Color; var width:CGFloat }
struct PaletteView: View {
    @State private var adapted=true
    @State private var selected=0
    @State private var width=6.0
    @State private var strokes:[InkStroke]=[]
    @State private var current:InkStroke?
    @State private var cleared:[InkStroke]=[]
    private let ink=Color(red:0.16,green:0.20,blue:0.25)
    private let colors:[Color]=[Color(red:0.20,green:0.34,blue:0.64),Color(red:0.84,green:0.36,blue:0.28),Color(red:0.87,green:0.64,blue:0.21),Color(red:0.21,green:0.50,blue:0.40),Color(red:0.55,green:0.40,blue:0.66),Color(red:0.16,green:0.20,blue:0.25)]
    var body: some View {
        VStack(spacing:12) {
            HStack {
                Label("掌上调色台",systemImage:"paintpalette").font(.headline)
                Spacer()
                Menu { Toggle("启用适配",isOn:$adapted) } label: { Image(systemName:"slider.horizontal.3").frame(width:44,height:44) }.accessibilityLabel("布局设置")
            }
            if adapted {
                ArrangementView { canvas.padding(12) } secondary: { controls.padding(12) }.arrangementViewStyle(.split)
            } else { ZStack(alignment:.bottom) { canvas; controls.frame(maxHeight:220).padding(12) } }
            HStack { Text("随手画一点，颜色慢慢选。"); Spacer(); Text("\(strokes.count) 笔").monospacedDigit() }.font(.caption).foregroundStyle(ink.opacity(0.7))
        }.padding(16).background(Color(red:0.94,green:0.92,blue:0.88)).foregroundStyle(ink).tint(ink).preferredColorScheme(.light)
    }
    private var canvas: some View {
        GeometryReader { proxy in
            Canvas { context,size in
                for stroke in strokes + (current.map { [$0] } ?? []) {
                    guard let first=stroke.points.first else { continue }
                    var path=Path(); path.move(to:CGPoint(x:first.x*size.width,y:first.y*size.height))
                    if stroke.points.count == 1 { path.addLine(to:CGPoint(x:first.x*size.width+0.1,y:first.y*size.height+0.1)) }
                    for point in stroke.points.dropFirst() { path.addLine(to:CGPoint(x:point.x*size.width,y:point.y*size.height)) }
                    context.stroke(path,with:.color(stroke.color),style:StrokeStyle(lineWidth:stroke.width,lineCap:.round,lineJoin:.round))
                }
            }.background(Color(red:0.99,green:0.985,blue:0.965))
                .overlay(alignment:.topLeading) {
                    VStack(alignment:.leading,spacing:4) {
                        Text("SKETCHBOOK").font(.caption.weight(.semibold)).tracking(2)
                        if strokes.isEmpty && current == nil { Text("用手指画下第一笔").font(.subheadline) }
                    }.foregroundStyle(ink.opacity(0.5)).padding(24).allowsHitTesting(false)
                }
                .gesture(DragGesture(minimumDistance:0).onChanged { value in
                    let point=CGPoint(x:min(1,max(0,value.location.x/max(1,proxy.size.width))),y:min(1,max(0,value.location.y/max(1,proxy.size.height))))
                    if current == nil { current=InkStroke(points:[],color:colors[selected],width:width) }
                    current?.points.append(point)
                }.onEnded { _ in if let current { strokes.append(current) }; current=nil })
                .accessibilityLabel("画布，\(strokes.count) 笔，可用手指绘画")
        }.clipShape(RoundedRectangle(cornerRadius:28))
    }
    private var controls: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:20) {
                HStack { Text("今天的颜色").font(.title3.weight(.semibold)); Spacer(); Image(systemName:"scribble.variable").foregroundStyle(colors[selected]).font(.title2) }
                LazyVGrid(columns:[GridItem(.adaptive(minimum:48))],spacing:12) {
                    ForEach(0..<colors.count,id:\.self) { i in
                        Button { selected=i } label: {
                            Circle().fill(colors[i]).frame(width:44,height:44).overlay { if selected == i { Image(systemName:"checkmark").font(.headline).foregroundStyle(.white) } }.padding(4)
                        }.buttonStyle(.plain).accessibilityLabel(["蓝色","赭红","金黄","绿色","紫色","墨色"][i]).accessibilityAddTraits(selected == i ? .isSelected : [])
                    }
                }
                HStack { Text("笔触粗细"); Spacer(); Text("\(Int(width)) pt").monospacedDigit() }.font(.subheadline)
                Slider(value:$width,in:2...18,step:1).accessibilityLabel("笔触粗细")
                HStack(spacing:16) {
                    Button { if !strokes.isEmpty { strokes.removeLast() } else if !cleared.isEmpty { strokes=cleared; cleared=[] } } label: { Label("撤销",systemImage:"arrow.uturn.backward").frame(minHeight:44) }.disabled(strokes.isEmpty && cleared.isEmpty)
                    Spacer()
                    Button { cleared=strokes; strokes=[] } label: { Label("清空",systemImage:"trash").frame(minHeight:44) }.disabled(strokes.isEmpty)
                }.font(.subheadline.weight(.medium))
                Text("清空后可以撤销。折叠时保留笔迹，退出 App 后不保存。")
                    .font(.caption).foregroundStyle(ink.opacity(0.7))
            }.padding(24)
        }.background(Color(red:0.98,green:0.97,blue:0.94),in:RoundedRectangle(cornerRadius:28))
    }
}

