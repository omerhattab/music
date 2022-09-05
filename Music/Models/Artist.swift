//
//  Artist.swift
//  Music
//
//  Created by btk-mac on 13.05.2022.
//

import Foundation

struct Artist: Codable {
    let id: String
    let name: String
    let type: String
    let external_urls: [String:String]
}
