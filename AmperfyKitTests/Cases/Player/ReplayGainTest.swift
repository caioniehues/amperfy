//
//  ReplayGainTest.swift
//  AmperfyKitTests
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

@testable import AmperfyKit
import XCTest

class ReplayGainTest: XCTestCase {
  private let accuracy: Float = 0.0001

  private let tagged = ReplayGainValues(trackGain: -6, trackPeak: 0.9, albumGain: -8, albumPeak: 0.95)

  private func gain(
    _ values: ReplayGainValues,
    _ configuration: ReplayGainConfiguration = .defaultValue,
    shuffle: Bool = false
  ) -> Float {
    ReplayGain.linearGain(values: values, configuration: configuration, isShuffle: shuffle)
  }

  func testDisabledIsUnity() {
    XCTAssertEqual(gain(tagged, ReplayGainConfiguration(isEnabled: false)), 1.0)
  }

  func testDefaultAppliesTrackGainLikeBefore() {
    // The original player applied pow(10, trackGain / 20) and nothing else.
    XCTAssertEqual(gain(tagged), pow(10, -6.0 / 20.0), accuracy: accuracy)
  }

  func testUntaggedIsUnityByDefault() {
    XCTAssertEqual(gain(.none), 1.0)
  }

  func testUntaggedUsesPreampWithoutTags() {
    let config = ReplayGainConfiguration(preampWithoutTagsDB: -6)
    XCTAssertEqual(gain(.none, config), pow(10, -6.0 / 20.0), accuracy: accuracy)
  }

  func testAlbumModeUsesAlbumGain() {
    let config = ReplayGainConfiguration(sourceMode: .album)
    XCTAssertEqual(gain(tagged, config), pow(10, -8.0 / 20.0), accuracy: accuracy)
  }

  func testAlbumModeFallsBackToTrackGain() {
    let trackOnly = ReplayGainValues(trackGain: -6, trackPeak: 0.9)
    let config = ReplayGainConfiguration(sourceMode: .album)
    XCTAssertEqual(gain(trackOnly, config), pow(10, -6.0 / 20.0), accuracy: accuracy)
  }

  func testTrackModeFallsBackToAlbumGain() {
    let albumOnly = ReplayGainValues(albumGain: -8, albumPeak: 0.95)
    XCTAssertEqual(gain(albumOnly), pow(10, -8.0 / 20.0), accuracy: accuracy)
  }

  func testAutoModeFollowsShuffle() {
    let config = ReplayGainConfiguration(sourceMode: .auto)
    XCTAssertEqual(gain(tagged, config, shuffle: false), pow(10, -8.0 / 20.0), accuracy: accuracy)
    XCTAssertEqual(gain(tagged, config, shuffle: true), pow(10, -6.0 / 20.0), accuracy: accuracy)
  }

  func testShuffleIsIgnoredOutsideAutoMode() {
    XCTAssertEqual(gain(tagged, .defaultValue, shuffle: true), gain(tagged, .defaultValue, shuffle: false))
    let album = ReplayGainConfiguration(sourceMode: .album)
    XCTAssertEqual(gain(tagged, album, shuffle: true), gain(tagged, album, shuffle: false))
  }

  func testClippingPreventionCapsBoostAtInversePeak() {
    // A quiet track: +12.4 dB would push a 0.35 peak to about 1.46.
    let quiet = ReplayGainValues(trackGain: 12.4, trackPeak: 0.35)
    XCTAssertEqual(gain(quiet), pow(10, 12.4 / 20.0), accuracy: accuracy)
    let config = ReplayGainConfiguration(isClippingPreventionEnabled: true)
    XCTAssertEqual(gain(quiet, config), 1.0 / 0.35, accuracy: accuracy)
  }

  func testClippingPreventionLeavesAttenuationAlone() {
    let config = ReplayGainConfiguration(isClippingPreventionEnabled: true)
    XCTAssertEqual(gain(tagged, config), pow(10, -6.0 / 20.0), accuracy: accuracy)
  }

  func testClippingPreventionIgnoresMissingPeak() {
    let noPeak = ReplayGainValues(trackGain: 6)
    let config = ReplayGainConfiguration(isClippingPreventionEnabled: true)
    XCTAssertEqual(gain(noPeak, config), pow(10, 6.0 / 20.0), accuracy: accuracy)
  }

  func testPreampAddsToTaggedGain() {
    let config = ReplayGainConfiguration(preampDB: 4)
    XCTAssertEqual(gain(tagged, config), pow(10, -2.0 / 20.0), accuracy: accuracy)
  }

  func testPreampCountsTowardsClippingLimit() {
    let config = ReplayGainConfiguration(isClippingPreventionEnabled: true, preampDB: 15)
    XCTAssertEqual(gain(tagged, config), 1.0 / 0.9, accuracy: accuracy)
  }

  func testPreampIsClampedToRange() {
    let tooHigh = ReplayGainConfiguration(preampDB: 40)
    XCTAssertEqual(gain(tagged, tooHigh), pow(10, 9.0 / 20.0), accuracy: accuracy)
    let tooLow = ReplayGainConfiguration(preampWithoutTagsDB: -40)
    XCTAssertEqual(gain(.none, tooLow), pow(10, -15.0 / 20.0), accuracy: accuracy)
  }

  func testSourceModeRawValuesAreStable() {
    // Persisted in UserSettings: changing these would break saved settings.
    XCTAssertEqual(ReplayGainSourceMode.track.rawValue, 0)
    XCTAssertEqual(ReplayGainSourceMode.album.rawValue, 1)
    XCTAssertEqual(ReplayGainSourceMode.auto.rawValue, 2)
  }
}
