//
//  ReplayGain.swift
//  AmperfyKit
//
//  Created by caioniehues on 19.11.26.
//  Copyright (c) 2026 caioniehues. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

// MARK: - ReplayGainSourceMode

/// Which ReplayGain value the player applies, like foobar2000's "source mode".
public enum ReplayGainSourceMode: Int, Codable, Sendable, CaseIterable {
  /// Track gain: every track plays at the same loudness.
  case track = 0
  /// Album gain: keeps the loudness differences within an album, as mastered.
  case album = 1
  /// Album gain while the queue plays in order, track gain while shuffling.
  case auto = 2

  public static let defaultValue: ReplayGainSourceMode = .track

  public var description: String {
    switch self {
    case .track: return "Track"
    case .album: return "Album"
    case .auto: return "Auto"
    }
  }
}

// MARK: - ReplayGainValues

/// The ReplayGain tags of one playable.
/// Gains are in dB, peaks are linear sample peaks (1.0 = full scale).
/// Amperfy stores a missing tag as 0, so a gain of 0 together with a peak of 0 means "no tag".
public struct ReplayGainValues: Equatable, Sendable {
  public var trackGain: Float
  public var trackPeak: Float
  public var albumGain: Float
  public var albumPeak: Float

  public init(trackGain: Float = 0, trackPeak: Float = 0, albumGain: Float = 0, albumPeak: Float = 0) {
    self.trackGain = trackGain
    self.trackPeak = trackPeak
    self.albumGain = albumGain
    self.albumPeak = albumPeak
  }

  public static let none = ReplayGainValues()

  public var hasTrackValues: Bool { trackGain != 0 || trackPeak > 0 }
  public var hasAlbumValues: Bool { albumGain != 0 || albumPeak > 0 }
}

// MARK: - ReplayGainConfiguration

/// The user's ReplayGain settings. The defaults reproduce the original behaviour:
/// track gain, no clipping prevention, no preamp.
public struct ReplayGainConfiguration: Equatable, Sendable {
  public var isEnabled: Bool
  public var sourceMode: ReplayGainSourceMode
  public var isClippingPreventionEnabled: Bool
  /// Added to the gain of tagged playables, in dB.
  public var preampDB: Float
  /// Applied to playables without ReplayGain tags, in dB.
  public var preampWithoutTagsDB: Float

  public init(
    isEnabled: Bool = true,
    sourceMode: ReplayGainSourceMode = .defaultValue,
    isClippingPreventionEnabled: Bool = false,
    preampDB: Float = 0,
    preampWithoutTagsDB: Float = 0
  ) {
    self.isEnabled = isEnabled
    self.sourceMode = sourceMode
    self.isClippingPreventionEnabled = isClippingPreventionEnabled
    self.preampDB = preampDB
    self.preampWithoutTagsDB = preampWithoutTagsDB
  }

  public static let defaultValue = ReplayGainConfiguration()
}

// MARK: - ReplayGain

public enum ReplayGain {
  /// Allowed range for both preamp settings, in dB.
  public static let preampRange: ClosedRange<Float> = -15 ... 15

  /// The linear volume factor (1.0 = unchanged) for a playable.
  ///
  /// - Album mode uses the album values and falls back to the track values when the
  ///   playable has no album tags; track mode falls back to album values the same way.
  /// - Playables without any tag get `preampWithoutTagsDB`.
  /// - With clipping prevention, the factor is capped at `1 / peak`, so the loudest
  ///   sample stays at or below full scale (ReplayGain 1.0 specification, "clipping prevention").
  public static func linearGain(
    values: ReplayGainValues,
    configuration: ReplayGainConfiguration,
    isShuffle: Bool
  ) -> Float {
    guard configuration.isEnabled else { return 1.0 }

    let prefersAlbum: Bool
    switch configuration.sourceMode {
    case .track: prefersAlbum = false
    case .album: prefersAlbum = true
    case .auto: prefersAlbum = !isShuffle
    }

    let gain: Float
    let peak: Float
    if prefersAlbum, values.hasAlbumValues {
      (gain, peak) = (values.albumGain, values.albumPeak)
    } else if values.hasTrackValues {
      (gain, peak) = (values.trackGain, values.trackPeak)
    } else if values.hasAlbumValues {
      (gain, peak) = (values.albumGain, values.albumPeak)
    } else {
      return linear(fromDB: clampedPreamp(configuration.preampWithoutTagsDB))
    }

    var factor = linear(fromDB: gain + clampedPreamp(configuration.preampDB))
    if configuration.isClippingPreventionEnabled, peak > 0 {
      factor = min(factor, 1.0 / peak)
    }
    return factor
  }

  public static func linear(fromDB db: Float) -> Float {
    pow(10.0, db / 20.0)
  }

  static func clampedPreamp(_ db: Float) -> Float {
    min(max(db, preampRange.lowerBound), preampRange.upperBound)
  }
}
