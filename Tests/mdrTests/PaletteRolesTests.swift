import SwiftUI
import Testing
@testable import MDReaderCore

struct PaletteRolesTests {
    @Test func roleIDsAreUnique() {
        let roles = PaletteRoleGroup.allCases.flatMap(\.roles)
        #expect(Set(roles.map(\.id)).count == roles.count)
    }

    @Test func everyColorRolePointsAtADistinctPaletteProperty() {
        let colors = PaletteRoleGroup.allCases.flatMap(\.roles).compactMap(\.keyPath)
        #expect(Set(colors).count == colors.count)
    }

    @Test func colorRolesResolveKeyPathsAndOthersDoNot() {
        for role in PaletteRoleGroup.allCases.flatMap(\.roles) {
            if case .color = role.kind {
                #expect(role.keyPath != nil, "\(role.label) should resolve")
            } else {
                #expect(role.keyPath == nil, "\(role.label) is not a color role")
            }
        }
    }

    @Test func catalogCoversEveryPaletteColorRole() {
        let colorRoles = PaletteRoleGroup.allCases.flatMap(\.roles).filter { $0.keyPath != nil }.count
        let colorProperties = Mirror(reflecting: Palette.linear).children.filter { $0.value is Color }.count
        #expect(colorRoles == colorProperties)
    }

    @Test func everyFontRoleMapsToOneTokenProperty() {
        #expect(roleCount { if case .font = $0 { return true }; return false } == CGFloatProperties(in: FontConfig.linear))
    }

    @Test func everySpacingRoleMapsToOneTokenProperty() {
        #expect(roleCount { if case .spacing = $0 { return true }; return false } == CGFloatProperties(in: Spacing.linear))
    }

    @Test func everyRadiusRoleMapsToOneTokenProperty() {
        #expect(roleCount { if case .radius = $0 { return true }; return false } == CGFloatProperties(in: Radius.linear))
    }

    @Test func familyRoleIsTheSingleFamilyRole() {
        let familyRoles = PaletteRoleGroup.allCases.flatMap(\.roles).filter { role in
            if case .family = role.kind { return true }
            return false
        }
        #expect(familyRoles.count == 1)
        #expect(familyRoles[0].id == "family")
        #expect(familyRoles[0].label == "Font family")
    }

    @Test func allGroupsAreNonEmpty() {
        #expect(PaletteRoleGroup.allCases.allSatisfy { !$0.roles.isEmpty })
    }

    private func roleCount(_ matches: (PaletteRole.Kind) -> Bool) -> Int {
        PaletteRoleGroup.allCases.flatMap(\.roles).filter { matches($0.kind) }.count
    }

    private func CGFloatProperties(in value: some Any) -> Int {
        Mirror(reflecting: value).children.compactMap { $0.value as? CGFloat }.count
    }
}
