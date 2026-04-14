//
//  BlankPosition.swift
//  GamesWithFriends
//

import Foundation

/// Where the blank sits in the setup string. Used for typography hints and
/// animation flourishes on the quote card.
enum BlankPosition: String, Codable {
    case start   // "___ I am your father"
    case middle  // "May the force ___ with you"
    case end     // "I'll be ___"
}
