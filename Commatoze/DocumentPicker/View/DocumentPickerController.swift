//

import UIKit

class DocumentPickerController: NSObject {
	weak var coordinator: DocumentPickerCoordinatorInput?

	init(with coordinator: DocumentPickerCoordinatorInput? = nil) {
		self.coordinator = coordinator
	}
}

extension DocumentPickerController: UIDocumentPickerDelegate {
	func documentPicker(
		_ controller: UIDocumentPickerViewController,
		didPickDocumentsAt urls: [URL]
	) {
		coordinator?.confirm(urls: urls)
	}

	func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
		coordinator?.cancel()
	}
}
