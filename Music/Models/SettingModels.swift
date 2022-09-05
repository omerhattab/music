//
//  SettingModels.swift
//  Music
//
//  Created by btk-mac on 20.05.2022.
//

import Foundation

struct Section {
    let title: String
    let options: [Option]
}

struct Option {
    let title: String
    let handler: () -> Void
}
