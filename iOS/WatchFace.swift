//
//  watchFace.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/19/21.
//

import UIKit

class WatchFaceView: UIView {
    private static let majorUpdateInterval: CGFloat = 3600
    private static let minorUpdateInterval: CGFloat = majorUpdateInterval / 12
    private static let updateInterval: CGFloat = 14.4
    static let frameOffset: CGFloat = 5
    static var currentInstance: WatchFaceView?

    let watchLayout = WatchLayout.shared
    var displayTime: Date? = nil
    var timezone: TimeZone = Calendar.current.timeZone
    var phase: StartingPhase = StartingPhase(zeroRing: 0, firstRing: 0, secondRing: 0, thirdRing: 0, fourthRing: 0)
    var timer: Timer?
    
    var location: CGPoint? {
        LocationManager.shared.location ?? watchLayout.location
    }

    private var chineseCalendar = ChineseCalendar(time: Date(), timezone: TimeZone.current, location: nil)
    
    var graphicArtifects = GraphicArtifects()
    private var keyStates = KeyStates()
    
    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        Self.currentInstance = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        Self.currentInstance = self
    }
    
    func setAutoRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: Self.updateInterval, repeats: true) { _ in
            self.drawView(forceRefresh: false)
        }
    }
    
    var isDark: Bool {
        self.traitCollection.userInterfaceStyle == .dark
    }
    
    func update() {
        let time = displayTime ?? Date()
        chineseCalendar.update(time: time, timezone: timezone, location: location)
    }
    
    func drawView(forceRefresh: Bool) {
        layer.sublayers = []
        if forceRefresh {
            let _ = WatchConnectivityManager.shared.sendLayout(watchLayout.encode(includeOffset: false))
            graphicArtifects = GraphicArtifects()
        }
        update()
        setNeedsDisplay()
    }
    
    func updateSize(with frame: CGRect) {
        self.frame = frame
        drawView(forceRefresh: true)
    }
    
    override func draw(_ rawRect: CGRect) {
        let dirtyRect = rawRect.insetBy(dx: Self.frameOffset, dy: Self.frameOffset)
        self.layer.update(dirtyRect: dirtyRect, isDark: isDark, watchLayout: watchLayout, chineseCalendar: chineseCalendar, graphicArtifects: graphicArtifects, keyStates: keyStates, phase: phase)
    }
}
