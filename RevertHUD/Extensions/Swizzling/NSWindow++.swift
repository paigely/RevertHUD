/*
 * RevertHUD
 * Copyright (c) 20XX github.com/paigely
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import AppKit

extension NSWindow {
	@objc func ___false() -> Bool { false }
	@objc func ___true() -> Bool { true }
	@objc func ___noop() {}
	@objc func ___collectionBehavior() -> NSWindow.CollectionBehavior {[
		.canJoinAllSpaces,
		.ignoresCycle,
		.stationary,
		.auxiliary
	]}
	static func swizzle() {
		Self.exchange(
			method: "canBecomeKeyWindow",
			in: "NSWindow",
			for: "___false"
		)
		Self.exchange(
			method: "canBecomeMainWindow",
			in: "NSWindow",
			for: "___false"
		)
		Self.exchange(
			method: "makeKeyWindow",
			in: "NSWindow",
			for: "___noop"
		)
		Self.exchange(
			method: "_hasActiveAppearance",
			in: "NSWindow",
			for: "___true"
		)
		Self.exchange(
			method: "collectionBehavior",
			in: "NSWindow",
			for: "___collectionBehavior"
		)
	}
}
