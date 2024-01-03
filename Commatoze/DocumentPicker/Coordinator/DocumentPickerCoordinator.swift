//

import UIKit

class DocumentPickerCoordinator: CoordinatorBase {
	static let resultCancel = 0
	static let resultOpen = 1

	private var presentingController: UIViewController?
	private var pickerController: DocumentPickerController?

	init(with presentingController: UIViewController) {
		self.presentingController = presentingController

	}

	override func start() {
		let controller = UIDocumentPickerViewController(
			documentTypes: ["public.text"],
			in: .open)
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
		finishWithResult(Self.resultOpen, userData: urls)
	}
}
