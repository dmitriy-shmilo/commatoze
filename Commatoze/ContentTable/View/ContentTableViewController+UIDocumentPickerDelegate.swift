//

import UIKit

extension ContentTableViewController: UIDocumentPickerDelegate {
	func documentPicker(
		_ controller: UIDocumentPickerViewController,
		didPickDocumentsAt urls: [URL]
	) {
		guard let url = urls.first else {
			return
		}
		AppCoordinator.shared.startContentTable(url: url)
		isPickingFile.send(false)
	}

	func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
		isPickingFile.send(false)
	}
}
