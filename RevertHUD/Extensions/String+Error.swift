/*
 * RevertHUD
 * Copyright (c) 20XX github.com/paigely
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Foundation

extension String: @retroactive Error {}
extension String: @retroactive LocalizedError {
	public var errorDescription: String? { return self }
}
