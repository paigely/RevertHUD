/*
 * RevertHUD
 * Copyright (c) 20XX github.com/paigely
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationShouldTerminateAfterLastWindowClosed(
		_ sender: NSApplication
	) -> Bool { false }
}

@main
struct RevertHUDApp: App {
	@Environment(\.colorScheme) private var theme
	@NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
	@State private var monitor = EventMonitor.shared
	
	init() {
		NSWindow.swizzle()
	}
	
	var body: some Scene {
		Window("hud", id: "hud") {
			HUDView()
				.environment(monitor)
		}
		.defaultLaunchBehavior(.suppressed)
		.restorationBehavior(.disabled)
		Window("accessibility-granted", id: "accessibility-granted") {
			PopoverView(dismiss: true) {
				Text("Permissions Granted")
					.foregroundStyle(.secondary)
					.font(.system(size: 16))
					.padding(15)
			} centerContent: {
				Image(systemName: "checkmark.circle")
					.resizable()
					.aspectRatio(contentMode: .fill)
					.fontWeight(.light)
					.frame(width: 62, height: 62)
					.foregroundStyle(.secondary)
			}
		}
		.defaultLaunchBehavior(.suppressed)
		.restorationBehavior(.disabled)
	}
}
