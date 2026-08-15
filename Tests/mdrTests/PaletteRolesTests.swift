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
        #expect(colorRoles == 19)
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
}
