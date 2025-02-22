//
//  WatchLayout.swift
//  Chinese Time
//
//  Created by Leo Liu on 5/11/23.
//

import SwiftUI
import Observation

@Observable final class WatchLayout: MetaWatchLayout {
    static var shared = WatchLayout()
    
    var textFont = UIFont.systemFont(ofSize: 14, weight: .regular)
    var centerFont = UIFont(name: "SourceHanSansKR-Heavy", size: 14)!
    var dualWatch = false
    
    private override init() {
        super.init()
    }
    
    override func encode(includeOffset: Bool = true, includeColor: Bool = true, includeConfig: Bool = true) -> String {
        var encoded = super.encode(includeOffset: includeOffset, includeColor: includeColor, includeConfig: includeConfig)
        encoded += "dualWatch: \(dualWatch)\n"
        return encoded
    }

    override func update(from values: [String: String]) {
        super.update(from: values)
        if let dual = values["dualWatch"]?.boolValue {
            dualWatch = dual
        }
    }
    
    var monochrome: Self {
        let emptyLayout = Self.init()
        emptyLayout.update(from: self.encode(includeColor: false))
        return emptyLayout
    }
    
    func binding<T>(_ keyPath: ReferenceWritableKeyPath<WatchLayout, T>) -> Binding<T> {
        return Binding(get: { self[keyPath: keyPath] }, set: { self[keyPath: keyPath] = $0 })
    }
}

@Observable final class WatchSetting {
    static let shared = WatchSetting()
    
    var size: CGSize = .zero
    var displayTime: Date? = nil
    
    private init() {}
}
