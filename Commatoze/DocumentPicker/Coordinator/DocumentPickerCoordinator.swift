//

import UIKit

class DocumentPickerCoordinator: CoordinatorBase {
	static let resultCancel = 0
	static let resultOpen = 1
	static let resultSave = 2

	private var presentingController: UIViewController?
	private var pickerController: DocumentPickerController?
	private let exportUrl: URL?

	init(with presentingController: UIViewController, exportUrl: URL? = nil) {
		self.presentingController = presentingController
		self.exportUrl = exportUrl
	}

	override func start() {
		let controller: UIDocumentPickerViewController

		if let exportUrl = exportUrl {
			if #available(macCatalyst 16.0, *) {
				controller = .init(forExporting: [exportUrl])
			} else {
				controller = .init(url: exportUrl, in: .exportToService)
			}
		} else {
			controller = .init(
				documentTypes: ["public.text"],
				in: .open)
		}
		// TODO: allow opening multiple documents
		pickerController = .init(with: self)
		controller.allowsMultipleSelection = false
		controller.delegate = pickerController
		presentingController?.present(controller, animated: true)
	}
}

extension DocumentPickerCoordinator: DocumentPickerCoordinatorInput {
	func cancel() {
		finishWithResult(Self.resultCancel, userData: nil)
	}

	func confirm(urls: [URL]) {
		if exportUrl != nil {
			finishWithResult(Self.resultSave, userData: urls)
			return
		}
		finishWithResult(Self.resultOpen, userData: urls)
	}
}
