//
//  Track.swift
//  RNTrackPlayer
//
//  Created by David Chavez on 12.08.17.
//  Copyright © 2017 David Chavez. All rights reserved.
//

import Foundation
import MediaPlayer
import AVFoundation
import SwiftAudioEx

class Track: NSObject, AudioItem, TimePitching, AssetOptionsProviding {
    let url: MediaURL

    @objc var title: String
    @objc var artist: String

    var date: String?
    var desc: String?
    var genre: String?
    var duration: Double?
    var skipped: Bool = false
    var artworkURL: MediaURL?
    let headers: [String: Any]?
    let pitchAlgorithm: String?
    var preferPreciseDuration: Bool?

    @objc var album: String?
    @objc var artwork: MPMediaItemArtwork?

    private var originalObject: [String: Any]

    init?(dictionary: [String: Any]) {
        guard let title = dictionary["title"] as? String,
            let artist = dictionary["artist"] as? String,
            let url = MediaURL(object: dictionary["url"])
            else { return nil }

        self.url = url
        self.title = title
        self.artist = artist

        self.date = dictionary["date"] as? String
        self.album = dictionary["album"] as? String
        self.genre = dictionary["genre"] as? String
        self.desc = dictionary["description"] as? String
        self.duration = dictionary["duration"] as? Double
        self.headers = dictionary["headers"] as? [String: Any]
        self.artworkURL = MediaURL(object: dictionary["artwork"])
        self.pitchAlgorithm = dictionary["pitchAlgorithm"] as? String

        self.preferPreciseDuration = dictionary["preferPreciseDuration"] as? Bool

        self.originalObject = dictionary
    }


    // MARK: - Public Interface

    func toObject() -> [String: Any] {
        return originalObject
    }

    func updateMetadata(dictionary: [String: Any]) {
        self.title = (dictionary["title"] as? String) ?? self.title
        self.artist = (dictionary["artist"] as? String) ?? self.artist

        self.date = dictionary["date"] as? String
        self.album = dictionary["album"] as? String
        self.genre = dictionary["genre"] as? String
        self.desc = dictionary["description"] as? String
        self.duration = dictionary["duration"] as? Double
        self.artworkURL = MediaURL(object: dictionary["artwork"])

        self.originalObject = self.originalObject.merging(dictionary) { (_, new) in new }
    }

    // MARK: - AudioItem Protocol

    func getSourceUrl() -> String {
        return url.isLocal ? url.value.path : url.value.absoluteString
    }

    func getArtist() -> String? {
        return artist
    }

    func getTitle() -> String? {
        return title
    }

    func getAlbumTitle() -> String? {
        return album
    }

    func getSourceType() -> SourceType {
        return url.isLocal ? .file : .stream
    }

    func getArtwork(_ handler: @escaping (UIImage?) -> Void) {
        if let artworkURL = artworkURL?.value {
            if(self.artworkURL?.isLocal ?? false){
                let image = UIImage.init(contentsOfFile: artworkURL.path);
                handler(image);
            } else {
                URLSession.shared.dataTask(with: artworkURL, completionHandler: { (data, _, error) in
                    if let data = data, let artwork = UIImage(data: data), error == nil {
                        handler(artwork)
                    }

                    handler(nil)
                }).resume()
            }
        }

        handler(nil)
    }

    // MARK: - TimePitching Protocol

    func getPitchAlgorithmType() -> AVAudioTimePitchAlgorithm {
        if let pitchAlgorithm = pitchAlgorithm {
            switch pitchAlgorithm {
            case PitchAlgorithm.linear.rawValue:
                return .varispeed
            case PitchAlgorithm.music.rawValue:
                return .spectral
            case PitchAlgorithm.voice.rawValue:
                return .timeDomain
            default:
                return .lowQualityZeroLatency
            }
        }

        return .lowQualityZeroLatency
    }

    // MARK: - Authorizing Protocol

    func getAssetOptions() -> [String: Any] {
        if preferPreciseDuration == true {
            return [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        }

        if let headers = headers {
            return ["AVURLAssetHTTPHeaderFieldsKey": headers]
        }

        return [:]
    }

}
