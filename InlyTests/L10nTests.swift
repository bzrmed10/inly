import Foundation
import Testing
@testable import Inly

struct L10nTests {
    private func placeholders(_ s: String) -> [String] {
        var found: [String] = []
        let chars = Array(s.replacingOccurrences(of: "%%", with: ""))
        var i = 0
        while i < chars.count {
            if chars[i] == "%", i + 1 < chars.count {
                var j = i + 1
                var spec = "%"
                while j < chars.count, chars[j].isNumber || chars[j] == "$" { spec.append(chars[j]); j += 1 }
                if j < chars.count { spec.append(chars[j]) }
                found.append(spec.contains("$") ? String(spec.last!) : spec)
                i = j
            }
            i += 1
        }
        return found.sorted()
    }

    @Test func everyKeyHasAllLanguages() {
        for (key, entry) in Strings.table where !key.contains("#") && !key.hasPrefix("unit.") {
            #expect(!entry.fr.isEmpty, "French missing: \(key)")
            #expect(!entry.ar.isEmpty, "Arabic missing: \(key)")
            #expect(!entry.es.isEmpty, "Spanish missing: \(key)")
        }
    }

    @Test func placeholdersMatchTheEnglishKey() {
        for (key, entry) in Strings.table where !key.contains("#") && !key.hasPrefix("unit.") {
            let expected = placeholders(key)
            #expect(placeholders(entry.fr) == expected, "French placeholders: \(key)")
            #expect(placeholders(entry.ar) == expected, "Arabic placeholders: \(key)")
            #expect(placeholders(entry.es) == expected, "Spanish placeholders: \(key)")
        }
    }

    @Test func englishPlurals() {
        #expect(L10n.t("%d hours", language: "en") == "%d hours")
        #expect(L10n.t("unit.h", language: "en") == "h")
        #expect(L10n.t("unit.m", language: "en") == "m")
    }

    @Test func missingKeyFallsBackToEnglish() {
        #expect(L10n.t("A key nobody translated", language: "fr") == "A key nobody translated")
    }

    @Test func frenchAndArabicLookups() {
        #expect(L10n.t("Take out", language: "fr") == "Retirer")
        #expect(L10n.t("Take out", language: "ar") == "إخراج")
        #expect(L10n.t("Take out", language: "es") == "Quitar")
    }

    @Test func supportedLanguagesAreResolved() {
        #expect(L10n.supported.contains(L10n.systemCode))
    }
}
