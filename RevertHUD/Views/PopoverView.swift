/*
 * RevertHUD
 * Copyright (c) 20XX github.com/paigely
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import SwiftUI

struct PopoverView<LowerContent: View, CenterContent: View>: View {
	@Environment(\.colorScheme) private var theme
	@Environment(\.dismissWindow) private var dismissWindow
	let dismiss: Bool
	@ViewBuilder let lowerContent: () -> LowerContent
	@ViewBuilder let centerContent: () -> CenterContent
	var body: some View {
		VStack {
			Spacer()
			lowerContent()
		}
		.onAppear {
			if dismiss {
				Task {
					try await Task.sleep(for: .seconds(1.25))
					dismissWindow()
				}
			}
		}
		.overlay(alignment: .center) {
			centerContent()
		}
		.frame(width: 200, height: 200)
		.background(
			CustomGlass(style: theme == .dark ? .text : .regular, radius: 22)
		)
		.allowsHitTesting(false)
		.onAppear {
			for window in NSApplication.shared.windows {
				window.isOpaque = false
				window.titlebarAppearsTransparent = true
				window.backgroundColor = .clear
				window.hasShadow = false
				window.animationBehavior = .documentWindow
				window.level = .init(rawValue: Int(CGShieldingWindowLevel()))
				window.styleMask = [.fullSizeContentView, .borderless]
				window.ignoresMouseEvents = true
				for button in [NSWindow.ButtonType.closeButton, .zoomButton, .miniaturizeButton] {
					window.standardWindowButton(button)?.isEnabled = false
					window.standardWindowButton(button)?.isHidden = true
				}
				if let screen = NSScreen.screens.first(where: {
					$0.frame.contains(NSEvent.mouseLocation)
				}) ?? NSScreen.main {
					window.setFrame(.init(
						x: screen.frame.midX - 100,
						y: screen.frame.minY + 150,
						width: 200,
						height: 200
					), display: true)
				}
			}
		}
	}
}
