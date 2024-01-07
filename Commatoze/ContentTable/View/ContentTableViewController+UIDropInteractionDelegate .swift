//

import UIKit

extension ContentTableViewController: UIDropInteractionDelegate {
	func dropInteraction(
		_ interaction: UIDropInteraction,
		canHandle session: UIDropSession
	) -> Bool {
		return true
	}

	func dropInteraction(
		_ interaction: UIDropInteraction,
		sessionDidUpdate session: UIDropSession
	) -> UIDropProposal {
		return UIDropProposal(operation: .move)
	}

	func dropInteraction(
		_ interaction: UIDropInteraction,
		performDrop session: UIDropSession
	) {
		session.items.first?
			.itemProvider
			.loadInPlaceFileRepresentation(
				forTypeIdentifier: "public.item"
			) { url, copy, err in
				guard let url = url else { return }
				self.viewModel.readFile(url: url)
			}
	}
}
