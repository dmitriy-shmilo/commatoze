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
		viewModel.readFile(url: url)
		isPickingFile.send(false)
	}

	func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
		isPickingFile.send(false)
	}
}
