import XCTest
@testable import GamesWithFriends

/// Pins the Country Letter Challenge matcher. The original report: on a "C"
/// round, several countries a player would reasonably name were rejected.
@MainActor
final class CountryLetterMatchingTests: XCTestCase {

    private var cCountries: [Country] { CountriesData.letterIndex["C"] ?? [] }

    private func resolve(_ input: String, letter: String = "C") -> String? {
        (CountriesData.letterIndex[letter] ?? []).first { $0.matches(input) }?.name
    }

    // MARK: - Data integrity

    func testEveryCountryIsFiledUnderItsOwnFirstLetter() {
        for (letter, countries) in CountriesData.letterIndex {
            for country in countries {
                XCTAssertEqual(country.firstLetter, letter, "\(country.name) filed under \(letter)")
            }
        }
    }

    func testNoAlternateNameCollidesAcrossCountries() {
        var seen: [String: String] = [:]
        for country in CountriesData.all {
            for label in [country.name] + country.alternateNames {
                let key = Country.normalize(label)
                if let owner = seen[key], owner != country.name {
                    XCTFail("\"\(label)\" resolves to both \(owner) and \(country.name)")
                }
                seen[key] = country.name
            }
        }
    }

    func testBothCongosLiveUnderC() {
        let names = cCountries.map(\.name)
        XCTAssertTrue(names.contains("Congo"), "Republic of the Congo missing from C")
        XCTAssertTrue(names.contains("Congo (DRC)"), "DR Congo missing from C")
        XCTAssertNil(CountriesData.letterIndex["D"]?.first { $0.name.contains("Congo") })
    }

    // MARK: - "C" round inputs from the bug report

    func testCommonCPhrasingsAreAccepted() {
        let expectations: [(String, String)] = [
            ("Cape Verde", "Cabo Verde"),
            ("Central African Republic", "Central African Republic"),
            ("Columbia", "Colombia"),
            ("The Comoros", "Comoros"),
            ("Congo", "Congo"),
            ("Republic of Congo", "Congo"),
            ("Republic of the Congo", "Congo"),
            ("Congo-Brazzaville", "Congo"),
            ("Democratic Republic of the Congo", "Congo (DRC)"),
            ("Democratic Republic of Congo", "Congo (DRC)"),
            ("DR Congo", "Congo (DRC)"),
            ("DRC", "Congo (DRC)"),
            ("Congo-Kinshasa", "Congo (DRC)"),
            ("Zaire", "Congo (DRC)"),
            ("Ivory Coast", "Côte d'Ivoire"),
            ("Cote d’Ivoire", "Côte d'Ivoire"),
            ("Czech Republic", "Czechia"),
            ("Czech", "Czechia"),
            ("Cypress", "Cyprus"),
            ("  canada ", "Canada"),
        ]
        for (input, expected) in expectations {
            XCTAssertEqual(resolve(input), expected, "input: \(input)")
        }
    }

    func testCommonPhrasingsOnOtherLetters() {
        let expectations: [(String, String, String)] = [
            ("U", "USA", "United States"),
            ("U", "America", "United States"),
            ("U", "UK", "United Kingdom"),
            ("U", "Britain", "United Kingdom"),
            ("U", "England", "United Kingdom"),
            ("U", "UAE", "United Arab Emirates"),
            ("S", "St. Lucia", "Saint Lucia"),
            ("S", "St Kitts", "Saint Kitts and Nevis"),
            ("S", "St Vincent", "Saint Vincent and the Grenadines"),
            ("S", "Sao Tome", "São Tomé and Príncipe"),
            ("B", "Bosnia", "Bosnia and Herzegovina"),
            ("T", "Trinidad", "Trinidad and Tobago"),
            ("T", "Türkiye", "Turkey"),
            ("N", "Holland", "Netherlands"),
            ("N", "Macedonia", "North Macedonia"),
            ("A", "Antigua", "Antigua and Barbuda"),
            ("E", "Swaziland", "Eswatini"),
        ]
        for (letter, input, expected) in expectations {
            XCTAssertEqual(resolve(input, letter: letter), expected, "input: \(input)")
        }
    }

    // MARK: - View model feedback

    func testGuessForAnotherLetterNamesTheRightLetter() {
        let vm = CountryGameViewModel()
        vm.selectLetter("C")
        vm.currentGuess = "Denmark"
        vm.submitGuess()
        XCTAssertEqual(vm.feedbackType, .error)
        XCTAssertTrue(vm.feedbackMessage.contains("Denmark"), vm.feedbackMessage)
        XCTAssertTrue(vm.feedbackMessage.contains("D"), vm.feedbackMessage)
        XCTAssertTrue(vm.guessedCountries.isEmpty)
    }

    func testTypedGuessStillCreditsOncePerCountry() {
        let vm = CountryGameViewModel()
        vm.selectLetter("C")
        vm.currentGuess = "Chile"
        vm.submitGuess()
        vm.currentGuess = "chile"
        vm.submitGuess()
        XCTAssertEqual(vm.guessedCountries.map(\.name), ["Chile"])
        XCTAssertEqual(vm.feedbackType, .error)
    }

    // MARK: - Spoken transcripts

    func testSpokenTranscriptCreditsEachCountryOnce() {
        let vm = CountryGameViewModel()
        vm.selectLetter("C")
        vm.handleSpeechTranscript("Canada")
        vm.handleSpeechTranscript("Canada Chile")
        vm.handleSpeechTranscript("Canada Chile um Cuba Canada")
        XCTAssertEqual(vm.guessedCountries.map(\.name), ["Canada", "Chile", "Cuba"])
        XCTAssertEqual(vm.feedbackType, .success)
    }

    func testSpokenFullDRCNameDoesNotAlsoCreditPlainCongo() {
        let vm = CountryGameViewModel()
        vm.selectLetter("C")
        vm.handleSpeechTranscript("Democratic Republic")
        vm.handleSpeechTranscript("Democratic Republic of the")
        vm.handleSpeechTranscript("Democratic Republic of the Congo")
        XCTAssertEqual(vm.guessedCountries.map(\.name), ["Congo (DRC)"])
    }

    func testSpokenMultiWordNamesResolveAcrossWindows() {
        let vm = CountryGameViewModel()
        vm.selectLetter("C")
        vm.handleSpeechTranscript("okay Central African Republic and then Costa Rica and the Ivory Coast")
        XCTAssertEqual(vm.guessedCountries.map(\.name),
                       ["Central African Republic", "Costa Rica", "Côte d'Ivoire"])
    }

    func testSpokenGuessIgnoredWhenNotPlaying() {
        let vm = CountryGameViewModel()
        vm.selectLetter("C")
        vm.finishGame()
        vm.handleSpeechTranscript("Canada")
        XCTAssertTrue(vm.guessedCountries.isEmpty)
    }

    func testSpokenLastCountryFinishesTheRound() {
        let vm = CountryGameViewModel()
        vm.selectLetter("Q")
        vm.handleSpeechTranscript("Qatar")
        XCTAssertEqual(vm.remainingCount, 0)
    }
}
