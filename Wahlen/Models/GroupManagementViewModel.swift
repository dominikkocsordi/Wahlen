import Foundation
import Observation
import AppKit

@MainActor
@Observable
final class GroupManagementViewModel {
    var groups: [VoterGroup] = []
    var codes: [VoterCode] = []
    var selectedGroup: VoterGroup?
    
    var newGroupName: String = ""
    var newGroupCodeCount: String = ""
    var isSubmitting = false
    var errorMessage: String?

    func loadGroups() async {
        do {
            self.groups = try await ElectionService.shared.fetchGroups()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func selectGroup(_ group: VoterGroup) async {
        self.selectedGroup = group
        do {
            self.codes = try await ElectionService.shared.fetchCodes(for: group.id)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func createGroup() async {
        guard !newGroupName.isEmpty, let count = Int(newGroupCodeCount), count > 0 else { return }
        isSubmitting = true
        errorMessage = nil
        
        do {
            let group = try await ElectionService.shared.createGroupWithCodes(name: newGroupName, codeCount: count)
            newGroupName = ""
            newGroupCodeCount = ""
            await loadGroups()
            await selectGroup(group)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    var exportDataString: String {
        guard let selectedGroup else { return "" }
        let lines = codes.enumerated().map { i, c in "\(i + 1). \(c.code)\(c.used ? " (verwendet)" : "")" }
        return "FSBS Wahlen – Codes für Gruppe: \(selectedGroup.name)\n\n" + lines.joined(separator: "\n")
    }

    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(exportDataString, forType: .string)
    }

    func assignGroup(_ group: VoterGroup, to session: VoteSession?) async {
        do {
            try await ElectionService.shared.assignGroup(groupId: group.id, to: session?.id)
            await loadGroups()
            if let g = groups.first(where: { $0.id == group.id }) {
                await selectGroup(g)
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func deleteGroup(_ group: VoterGroup) async {
        do {
            try await ElectionService.shared.deleteGroup(groupId: group.id)
            if selectedGroup?.id == group.id {
                selectedGroup = nil
                codes = []
            }
            await loadGroups()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
