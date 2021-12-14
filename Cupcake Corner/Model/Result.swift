//
//  Result.swift
//  Cupcake Corner
//
//  Created by Connor A Lynch on 13/12/2021.
//

import Foundation
import AVKit

struct Response: Codable {
    var results: [Result]
}

struct Result: Codable {
    var trackId: Int
    var trackName: String
    var artistName: String
    var collectionName: String
    var artworkUrl100: String
    var previewUrl: String
}

struct ResultViewModel: Identifiable, Codable {
    var id: Int
    var trackName: String
    var collectionName: String
    var image: String
    var previewURL: String
    var artistName: String
    
    var isPlaying: Bool = false
    
    init(result: Result){
        self.id = result.trackId
        self.trackName = result.trackName
        self.collectionName = result.collectionName
        self.image = result.artworkUrl100
        self.previewURL = result.previewUrl
        if result.artistName.count > 50 {
            self.artistName = String("\(result.artistName.prefix(50))...")
        }else{
            self.artistName = String(result.artistName)
        }
    }
}
