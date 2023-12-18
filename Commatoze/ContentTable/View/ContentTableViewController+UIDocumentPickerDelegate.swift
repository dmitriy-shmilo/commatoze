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
	}
}
