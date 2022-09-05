//
//  FeaturedPlaylistsResponse.swift
//  Music
//
//  Created by btk-mac on 30.05.2022.
//

import Foundation

struct FeaturedPlaylistsResponse: Codable {
    let playlists: PlaylistResponse
}

struct PlaylistResponse:Codable {
    let items: [Playlist]
}

struct User: Codable {
    let display_name: String
    let external_urls: [String: String]
    let id: String
}
