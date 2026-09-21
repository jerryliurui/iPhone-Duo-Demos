import SwiftUI
import Combine
import AVFoundation

@main struct FoldBeatApp: App { var body: some Scene { WindowGroup { BeatView() } } }

@Observable final class DrumEngine {
    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var sounds: [AVAudioPCMBuffer] = []
    var error: String?
    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode:.default, options:.mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            let format=AVAudioFormat(standardFormatWithSampleRate:44100, channels:1)!
            for kind in 0..<5 {
                let player=AVAudioPlayerNode(); engine.attach(player)
                try engine.connectNode(player,to:engine.mainMixerNode,format:format); players.append(player)
                let frames=AVAudioFrameCount(44100 * 0.24)
                let buffer=AVAudioPCMBuffer(pcmFormat:format,frameCapacity:frames)!
                buffer.frameLength=frames
                var phase=0.0
                for i in 0..<Int(frames) {
                    let t=Double(i)/44100
                    phase += 2 * .pi * (kind == 0 ? 48 + 100 * exp(-t*35) : kind == 3 ? 180 : 900) / 44100
                    let noise=Double.random(in:-1...1)
                    let sample: Double
                    switch kind {
                    case 0: sample=sin(phase)*exp(-t*22)
                    case 1: sample=(noise*0.75+sin(phase)*0.25)*exp(-t*30)
                    case 2: sample=noise*exp(-t*90)*0.45
                    case 3: sample=sin(phase)*exp(-t*24)
                    default: sample=sin(phase)*exp(-t*130)*0.35
                    }
                    buffer.floatChannelData![0][i]=Float(sample*0.65)
                }
                sounds.append(buffer)
            }
            try engine.start()
        } catch { self.error="音频暂不可用，请重新打开 App。" }
    }
    func hit(_ index: Int) {
        guard error == nil else { return }
        if !engine.isRunning { do { try engine.start() } catch { self.error="音频中断，请重新打开 App。"; return } }
        let player=players[index]; player.stop(); player.scheduleBuffer(sounds[index])
        do { try player.playAudio() } catch { self.error="播放失败，请重新打开 App。" }
    }
}

struct BeatView: View {
    @State private var audio=DrumEngine()
    @State private var adapted=true
    @State private var bpm=96.0
    @State private var running=false
    @State private var step=0
    @State private var hits=0
    @State private var last="准备好，敲一拍"
    @State private var nextBeat=0.0
    @Environment(\.scenePhase) private var scenePhase
    private let ticker=Timer.publish(every:0.02,on:.main,in:.common).autoconnect()
    private let mint=Color(red:0.70,green:0.92,blue:0.64)
    var body: some View {
        VStack(spacing:12) {
            HStack {
                Label("折叠鼓机",systemImage:"waveform").font(.headline)
                Spacer()
                Menu { Toggle("启用适配",isOn:$adapted) } label: { Image(systemName:"slider.horizontal.3").frame(width:44,height:44) }.accessibilityLabel("布局设置")
            }
            if adapted {
                ArrangementView { display } secondary: { pads }.arrangementViewStyle(.split)
            } else { VStack(spacing:12) { display; pads } }
            HStack {
                Text("BPM").font(.caption.bold()).foregroundStyle(mint)
                Text("\(Int(bpm))").monospacedDigit().font(.headline)
                Slider(value:$bpm,in:60...160,step:1).accessibilityLabel("速度")
                Button { running.toggle(); nextBeat=0; step = -1 } label: {
                    Image(systemName:running ? "stop.fill" : "play.fill").frame(width:48,height:48).background(mint,in:Circle()).foregroundStyle(.black)
                }.accessibilityLabel(running ? "停止节拍" : "开始节拍")
            }
            if let error=audio.error { Text(error).font(.caption).foregroundStyle(.orange) }
        }.padding(16).foregroundStyle(.white).background(Color(red:0.075,green:0.09,blue:0.085)).tint(mint).preferredColorScheme(.dark)
            .onReceive(ticker) { _ in
                let now=ProcessInfo.processInfo.systemUptime
                if running && now >= nextBeat { step=(step+1)%4; audio.hit(4); nextBeat=now+60/bpm }
            }.onChange(of:scenePhase) { _, phase in if phase != .active { running=false } }
    }
    private var display: some View {
        VStack(alignment:.leading,spacing:16) {
            HStack { Text("POCKET SESSION").font(.caption.weight(.semibold)).tracking(2); Spacer(); Text("\(hits) 次敲击").font(.caption.monospacedDigit()) }.foregroundStyle(mint)
            Spacer(minLength:0)
            HStack(alignment:.firstTextBaseline,spacing:8) {
                Text(String(format:"%02d",running ? step+1 : 1)).font(.system(size:96,weight:.light,design:.rounded)).monospacedDigit()
                Text("/ 04").font(.title2).foregroundStyle(.white.opacity(0.5))
                Spacer()
                Image(systemName:"waveform.path").font(.system(size:58,weight:.ultraLight)).foregroundStyle(mint).accessibilityHidden(true)
            }
            Text(last).font(.headline)
            HStack(spacing:8) { ForEach(0..<4) { i in Capsule().fill(running && step == i ? mint : .white.opacity(0.14)).frame(height:6) } }
            Spacer(minLength:0)
        }.padding(24).frame(maxWidth:.infinity,maxHeight:.infinity).background(.white.opacity(0.045),in:RoundedRectangle(cornerRadius:28))
    }
    private var pads: some View {
        LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:12) {
            ForEach(0..<4) { i in
                Button { audio.hit(i); hits += 1; last=["底鼓 · KICK","军鼓 · SNARE","踩镲 · HAT","通鼓 · TOM"][i] } label: {
                    VStack(alignment:.leading,spacing:12) {
                        HStack { Text(String(format:"%02d",i+1)).font(.caption.monospaced()); Spacer(); Image(systemName:["circle.inset.filled","line.3.horizontal","sparkle","circle.dotted"][i]) }
                        Spacer(minLength:8)
                        Text(["KICK","SNARE","HAT","TOM"][i]).font(.title3.weight(.bold))
                        Text(["底鼓","军鼓","踩镲","通鼓"][i]).font(.caption)
                    }.padding(20).frame(maxWidth:.infinity,minHeight:100).background(i == 0 ? mint : .white.opacity(0.10),in:RoundedRectangle(cornerRadius:24)).foregroundStyle(i == 0 ? .black : .white)
                }.buttonStyle(.plain)
            }
        }.frame(maxWidth:.infinity,maxHeight:.infinity)
    }
}
