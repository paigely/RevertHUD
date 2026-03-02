/*
 * RevertHUD
 * Copyright (c) 20XX github.com/paigely
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import SwiftUI
import CoreAudio
import IOKit
import IOKit.graphics
import AudioToolbox

/// Helper class to get and set volume/brightness
/// This can't be observed directly, EventMonitor should
/// be used in combination with this.
class SystemUtilities {
	static let shared = SystemUtilities()
	
	/// If a set or get failed, this is set to true
	/// If the next set or get on anything succeeds, this is set to false
	var failed: Bool = false
	
	init() {
		
	}
	
	// MARK: - Function wrappers
	
	/// The current volume of the system
	var volume: Double {
		set {
			failed = !setVolume(newValue)
		}
		get {
			getVolume()
		}
	}
	
	/// The current muted state of the system
	var muted: Bool {
		set {
			failed = !setMuted(newValue)
		}
		get {
			getMuted()
		}
	}
	
	/// The current brightness of the screen that the window is on
	var brightness: Double {
		set {
			failed = !setBrightness(newValue)
		}
		get {
			getBrightness()
		}
	}
}

// MARK: - Helpers
extension SystemUtilities {
	private static func audioID() -> AudioDeviceID {
		var address = AudioObjectPropertyAddress(
			mSelector: kAudioHardwarePropertyDefaultOutputDevice,
			mScope: kAudioObjectPropertyScopeGlobal,
			mElement: kAudioObjectPropertyElementMain
		)
		var size = UInt32(MemoryLayout<AudioDeviceID>.size)
		var deviceID = kAudioObjectUnknown
		AudioObjectGetPropertyData(
			AudioObjectID(kAudioObjectSystemObject),
			&address,
			0,
			nil,
			&size,
			&deviceID
		)
		return deviceID
	}
	
	private static func displayID() -> CGDirectDisplayID {
		let screen = NSApplication.shared.windows.first { $0.contentView is NSHostingView<HUDView> }?.screen ?? NSScreen.main
		return (screen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) ?? CGMainDisplayID()
	}
}

// MARK: - IOKit fallbacks
extension SystemUtilities {
	private static func brightnessIOKit() -> Float {
		var brightness: Float = 1.0
		var iterator = io_iterator_t()
		let result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"), &iterator)
		
		if result == kIOReturnSuccess {
			var service: io_object_t = IOIteratorNext(iterator)
			while service != 0 {
				IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &brightness)
				IOObjectRelease(service)
				service = IOIteratorNext(iterator)
			}
		}
		
		return brightness
	}
}

// MARK: - Volume
extension SystemUtilities {
	private func getVolume() -> Double {
		var volume: Float = 0
		var size = UInt32(MemoryLayout<Float>.size)
		let device = Self.audioID()
		var address = AudioObjectPropertyAddress(
			mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
			mScope: kAudioDevicePropertyScopeOutput,
			mElement: kAudioObjectPropertyElementMain
		)
		AudioObjectGetPropertyData(device, &address, 0, nil, &size, &volume)
		return Double(volume)
	}
	
	private func setVolume(_ volume: Double) -> Bool {
		let device = Self.audioID()
		var volumeToSet = min(max(Float(volume), 0), 1)
		var address = AudioObjectPropertyAddress(
			mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
			mScope: kAudioDevicePropertyScopeOutput,
			mElement: kAudioObjectPropertyElementMain
		)
		var isSettable: DarwinBoolean = true
		let status = AudioObjectIsPropertySettable(device, &address, &isSettable)
		if status != noErr || !isSettable.boolValue { return false }
		let setStatus = AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<Float>.size), &volumeToSet)
		return setStatus == noErr
	}
	
	// MARK: - Mute
	private func getMuted() -> Bool {
		let device = Self.audioID()
		var isMuted: UInt32 = 0
		var size = UInt32(MemoryLayout<UInt32>.size)
		var address = AudioObjectPropertyAddress(
			mSelector: kAudioDevicePropertyMute,
			mScope: kAudioDevicePropertyScopeOutput,
			mElement: kAudioObjectPropertyElementMain
		)
		AudioObjectGetPropertyData(device, &address, 0, nil, &size, &isMuted)
		return isMuted != 0
	}
	
	private func setMuted(_ muted: Bool) -> Bool {
		let device = Self.audioID()
		var value: UInt32 = muted ? 1 : 0
		var address = AudioObjectPropertyAddress(
			mSelector: kAudioDevicePropertyMute,
			mScope: kAudioDevicePropertyScopeOutput,
			mElement: kAudioObjectPropertyElementMain
		)
		let status = AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<UInt32>.size), &value)
		return status == noErr
	}
	
	// MARK: - Brightness
	private func getBrightness() -> Double {
		var brightness: Float = 0
		if let funcPtr = unsafeBitCast(dlsym(UnsafeMutableRawPointer(bitPattern: -2), "DisplayServicesGetBrightness"), to: (@convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> CGError)?.self) {
			_ = funcPtr(Self.displayID(), &brightness)
			return Double(brightness)
		}
		return Double(Self.brightnessIOKit())
	}
	
	private func setBrightness(_ brightness: Double) -> Bool {
		let clamped = min(max(Float(brightness), 0), 1)
		if let funcPtr = unsafeBitCast(dlsym(UnsafeMutableRawPointer(bitPattern: -2), "DisplayServicesSetBrightness"), to: (@convention(c) (CGDirectDisplayID, Float) -> CGError)?.self) {
			let result = funcPtr(Self.displayID(), clamped)
			return result.rawValue == 0
		}
		var iterator = io_iterator_t()
		let result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"), &iterator)
		if result != kIOReturnSuccess { return false }
		let service: io_object_t = IOIteratorNext(iterator)
		while service != 0 {
			IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, clamped)
			IOObjectRelease(service)
			break
		}
		return true
	}
}
