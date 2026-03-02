/*
 * RevertHUD
 * Copyright (c) 20XX github.com/paigely
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import ObjectiveC

extension NSObject {
	static func exchange(method: String, in className: String, for newMethod: String) {
		guard let classRef = objc_getClass(className) as? AnyClass,
			  let original = class_getInstanceMethod(classRef, Selector((method))),
			  let replacement = class_getInstanceMethod(self, Selector((newMethod)))
		else {
			fatalError("Could not exchange method \(method) on class \(className).")
		}
		method_exchangeImplementations(original, replacement)
	}
}
