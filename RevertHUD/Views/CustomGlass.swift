/*
 * RevertHUD
 * Copyright (c) 20XX github.com/paigely
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import SwiftUI

struct CustomGlass: NSViewRepresentable {
	var style: Self.Style = .appIcons
	var tintColor: NSColor? = nil
	var radius: Float = 100
	
	func makeNSView(context: Context) -> NSView {
#if canImport(PaperKit)
		if #available(macOS 26.0, *) {
			let effectView = NSGlassEffectView()
			effectView.setValue(NSNumber(value: self.style.rawValue), forKey: "_variant")
			effectView.tintColor = tintColor
			effectView.cornerRadius = CGFloat(radius)
			return effectView
		}
#endif
		let effectView = NSVisualEffectView()
		effectView.blendingMode = .behindWindow
		effectView.material = .sidebar
		effectView.state = .active
		effectView.wantsLayer = true
		effectView.layer?.cornerRadius = CGFloat(radius)
		return effectView
	}
	
	func updateNSView(_ nsView: NSView, context: Context) { }
	
	enum Style: Int {
		case regular
		case clear
		case dock
		case appIcons
		case widgets
		case text
		case avplayer
		case facetime
		case controlCenter
		case notificationCenter
		case monogram
		case bubbles
		case identity
		case focusBorder
		case focusPlatter
		case keyboard
		case sidebar
		case abuttedSidebar
		case inspector
		case control
		case loupe
		case slider
		case camera
		case cartouchePopover
	}
}
