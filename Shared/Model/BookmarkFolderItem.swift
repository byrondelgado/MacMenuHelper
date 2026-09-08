//
//  BookmarkFolderItem.swift
//  BookmarkFolderItem
//
//  Created by Kyle on 2021/10/10.
//

import AppKit
import Foundation
import os.log

private let logger = Logger(subsystem: subsystem, category: "folder_item")

struct BookmarkFolderItem: FolderItem {
    var url: URL
    var bookmark: Data

    var path: String { url.path }

    init(_ url: URL) throws {
        guard url.isFileURL else { throw FileActionSafety.ValidationError.nonFileURL }
        self.url = url
        let result = url.startAccessingSecurityScopedResource()
        defer { if result { url.stopAccessingSecurityScopedResource() } }
        bookmark = try url.bookmarkData(options: .withSecurityScope)
    }

    enum CodingKeys: String, CodingKey {
        case url, bookmark
    }

    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        bookmark = try values.decode(Data.self, forKey: .bookmark)
        var isStale = false
        do {
            url = try URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
        } catch {
            // Show for the main app
            url = try values.decode(URL.self, forKey: .url)
        }
        guard url.isFileURL else { throw FileActionSafety.ValidationError.nonFileURL }
    }
}
