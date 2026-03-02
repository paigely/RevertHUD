/*
 * RevertHUD
 * Copyright (c) 20XX github.com/paigely
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import SwiftUI
import AudioToolbox.AudioServices

struct HUDView: View {
	@Environment(EventMonitor.self) var monitor
	
	@Environment(\.colorScheme) private var theme
	@Environment(\.dismissWindow) private var dismissWindow
	
	@State private var value: Double = SystemUtilities.shared.volume
	@State private var dismissTask: Task<Void, Error>?
	
	var icon: Image {
		switch monitor.event?.kind {
		case .brightness:
			if SystemUtilities.shared.failed {
				return Image(systemName: "sun.max.trianglebadge.exclamationmark")
			} else if value < 0.33 {
				return Image(systemName: "sun.min.fill")
			} else {
				return Image(systemName: "sun.max.fill")
			}
		default:
			if SystemUtilities.shared.failed {
				return Image(systemName: "speaker.trianglebadge.exclamationmark")
			}
			if value == 0 || SystemUtilities.shared.muted {
				return Image(.speaker0)
			} else if value < 0.33 {
				return Image(.speaker1)
			} else if value < 0.66 {
				return Image(.speaker2)
			} else {
				return Image(.speaker3)
			}
		}
	}
	
	var body: some View {
		PopoverView(dismiss: false) {
			Spacer()
			GeometryReader { geo in
				ZStack(alignment: .leading) {
					CustomGlass(style: .regular)
						.frame(height: 10)
						.opacity(theme == .dark ? 1 : 0.25)
					Capsule(style: .continuous)
						.fill(.white.opacity(theme == .dark ? 0.75 : 1))
						.frame(width: geo.size.width * value, height: 10)
						.animation(.spring.speed(3), value: value)
				}
			}
			.frame(maxWidth: .infinity)
			.frame(height: 10)
			.padding(15)
		} centerContent: {
			icon
				.resizable()
				.aspectRatio(contentMode: .fill)
				.fontWeight(.heavy)
				.frame(width: 62, height: 62)
				.foregroundStyle(.white.opacity(theme == .dark ? 0.75 : 1))
		}
		.task(id: monitor.event, handleEvent)
	}
	
	func handleEvent() {
		dismissTask?.cancel()
		dismissTask = Task {
			try await Task.sleep(for: .seconds(1.25))
			dismissWindow()
		}
		
		guard let event = monitor.event else { return }
		
		let amount = 0.0625 / (event.fractional ? 5 : 1)
		if event.kind == .volume {
			switch event.change {
			case .increase:
				SystemUtilities.shared.muted = false
				SystemUtilities.shared.volume += amount
			case .decrease:
				SystemUtilities.shared.muted = false
				SystemUtilities.shared.volume -= amount
			case .toggle:
				SystemUtilities.shared.muted.toggle()
			}
			value = SystemUtilities.shared.muted ? 0 : SystemUtilities.shared.volume
			if NSEvent.modifierFlags.contains(.shift) && !NSEvent.modifierFlags.contains(.option) {
				AudioServicesPlaySystemSound(3)
			}
		} else if event.kind == .brightness {
			switch event.change {
			case .increase:
				SystemUtilities.shared.brightness += amount
			case .decrease:
				SystemUtilities.shared.brightness -= amount
			default:
				break
			}
			value = SystemUtilities.shared.brightness
		}
	}
}
