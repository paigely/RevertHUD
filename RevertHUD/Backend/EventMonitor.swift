/*
 * RevertHUD
 * Copyright (c) 20XX github.com/paigely
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Cocoa
import Observation
import SwiftUI

@Observable class EventMonitor {
	static let shared = EventMonitor()
	var event: Event?
	// workaround for stupid log spam
	private let openWindow: OpenWindowAction
	@ObservationIgnored @Environment(\.openWindow) static private var _openWindow
	@ObservationIgnored private var tap: CFMachPort?
	
	init() {
		self.openWindow = Self._openWindow
		start()
	}
	
	deinit {
		stop()
	}
	
	func start() {
		Task {
			if !AXIsProcessTrusted() {
				let name = Bundle.main.infoDictionary?["CFBundleName"] as! String
				let alert = NSAlert()
				alert.messageText = "No Permissions"
				alert.informativeText = "\(name) needs accessibility permissions. Click “Open Settings” and enable \(name)."
				alert.addButton(withTitle: "Exit")
				alert.addButton(withTitle: "Open Settings")
				
				await MainActor.run {
					if alert.runModal() == .alertSecondButtonReturn {
						_ = NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
					} else {
						_ = exit(1)
					}
				}
				
				while (!AXIsProcessTrusted()) {
					try await Task.sleep(for: .seconds(0.1))
				}
				
				openWindow(id: "accessibility-granted")
			}
			
			if let tap {
				if !CGEvent.tapIsEnabled(tap: tap) {
					CGEvent.tapEnable(tap: tap, enable: true)
				}
				return
			}
			
			let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
			self.tap = CGEvent.tapCreate(
				tap: .cghidEventTap,
				place: .headInsertEventTap,
				options: .defaultTap,
				eventsOfInterest: CGEventMask(1 << NSEvent.EventType.systemDefined.rawValue),
				callback: { _, _, event, userInfo in
					guard let userInfo else { return Unmanaged.passUnretained(event) }
					return Unmanaged<EventMonitor>
						.fromOpaque(userInfo)
						.takeUnretainedValue()
						.callback(event)
				},
				userInfo: selfPointer
			)
			
			if let tap {
				CGEvent.tapEnable(tap: tap, enable: true)
				await MainActor.run {
					RunLoop.current.add(tap, forMode: .default)
				}
			}
		}
	}
	
	func stop() {
		if let tap {
			CGEvent.tapEnable(tap: tap, enable: false)
			RunLoop.current.remove(tap, forMode: .default)
			self.tap = nil
		}
	}
	
	private func callback(_ event: CGEvent) -> Unmanaged<CGEvent>? {
		guard
			event.type.rawValue > 0,
			event.type.rawValue < 0x7fffffff,
			let nsEvent = NSEvent(cgEvent: event),
			nsEvent.subtype == .screenChanged
		else {
			return Unmanaged.passUnretained(event)
		}
		
		let data1 = nsEvent.data1
		let keyCode = Int32((data1 & 0xFFFF0000) >> 16)
		let keyFlags = UInt32(data1 & 0x0000FFFF)
		let isKeyDown = ((keyFlags & 0xFF00) >> 8) == 0xA
		
		let flags = event.flags
		let fractional = flags.contains(.maskShift) && flags.contains(.maskAlternate)
		
		if isKeyDown {
			let mappings: [Int32: (Event.Kind, Event.Change)] = [
				NX_KEYTYPE_SOUND_DOWN: (.volume, .decrease),
				NX_KEYTYPE_SOUND_UP: (.volume, .increase),
				NX_KEYTYPE_MUTE: (.volume, .toggle),
				NX_KEYTYPE_BRIGHTNESS_DOWN: (.brightness, .decrease),
				NX_KEYTYPE_BRIGHTNESS_UP: (.brightness, .increase)
			]
			if let (kind, change) = mappings[keyCode] {
				self.event = Event(kind: kind, change: change, fractional: fractional)
				openWindow(id: "hud")
				return nil
			}
		}
		
		return Unmanaged.passUnretained(event)
	}
	
	struct Event: Identifiable, Equatable {
		let kind: Kind
		let change: Change
		let fractional: Bool
		let id = UUID()
		static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.id == rhs.id
		}
		enum Kind {
			case volume, brightness
		}
		enum Change: UInt {
			case increase, decrease, toggle
		}
	}
}
