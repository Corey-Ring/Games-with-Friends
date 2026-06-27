import XCTest
@testable import GamesWithFriends

final class ClueBuildersTests: XCTestCase {
    func testNewClueTypesHaveIcons() {
        let newTypes: [ClueType] = [.genreIdentity, .longevity, .blockbuster, .franchise]
        for type in newTypes {
            XCTAssertFalse(type.icon.isEmpty, "\(type) must have an icon")
        }
    }
}
