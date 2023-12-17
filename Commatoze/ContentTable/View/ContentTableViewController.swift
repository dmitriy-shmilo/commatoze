//

import UIKit
import Spreadsheet
import Combine

class ContentTableViewController: UIViewController, UIDocumentPickerDelegate {
	@IBOutlet private weak var sheet: SheetView!

	let viewModel = ContentTableViewModel()

	private var subscriptions = Set<AnyCancellable>()

	override func viewDidLoad() {
		super.viewDidLoad()

		sheet.register(SheetViewLabelCell.self, forCellReuseIdentifier: "cell")
		sheet.register(SheetViewLabelCell.self, forCellReuseIdentifier: "top")
		sheet.register(SheetViewLabelCell.self, forCellReuseIdentifier: "left")
		sheet.dataSource = self
		sheet.delegate = self

		viewModel.currentFile
			.sink { [weak self] _ in
				self?.sheet.reloadData()
			}
			.store(in: &subscriptions)

		viewModel.cellChanged
			.sink { [weak self] index in
				self?.sheet.reloadCellAt(index: index)
			}
			.store(in: &subscriptions)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		guard let url = Bundle.main.url(forResource: "test", withExtension: ".csv") else {
			return
		}
		viewModel.readFile(url: url)
	}

	// MARK: - Menu Overrides
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		let selectionActions = [
			#selector(cutAction(_:)),
			#selector(copyAction(_:)),
			#selector(pasteAction(_:)),
			#selector(deleteAction(_:)),
		]
		if selectionActions.contains(action) {
			return sheet.currentSelection
				.topLeft(in: sheet)
				.firstIndex(in: sheet) != .invalid
		}
		return super.canPerformAction(action, withSender: sender)
	}

	override func copy(_ sender: Any?) {
		let topLeft = sheet.currentSelection.topLeft(in: sheet).firstIndex(in: sheet)
		guard topLeft != .invalid else {
			return
		}

		UIPasteboard.general.string = viewModel.getField(at: topLeft)
	}

	override func paste(_ sender: Any?) {
		guard let value = UIPasteboard.general.string,
			  value.count > 0 else {
			return
		}
		let topLeft = sheet.currentSelection.topLeft(in: sheet).firstIndex(in: sheet)
		guard topLeft != .invalid else {
			return
		}

		viewModel.setField(at: topLeft, to: value)
	}

	override func delete(_ sender: Any?) {
		let topLeft = sheet.currentSelection.topLeft(in: sheet).firstIndex(in: sheet)
		guard topLeft != .invalid else {
			return
		}

		viewModel.setField(at: topLeft, to: "")
	}

	override func cut(_ sender: Any?) {
		let topLeft = sheet.currentSelection.topLeft(in: sheet).firstIndex(in: sheet)
		guard topLeft != .invalid else {
			return
		}

		UIPasteboard.general.string = viewModel.getField(at: topLeft)
		viewModel.setField(at: topLeft, to: "")
	}
}

// MARK: - Menu Actions
extension ContentTableViewController {
	@objc func copyAction(_ sender: UICommand) {
		copy(self)
	}

	@objc func pasteAction(_ sender: UICommand) {
		paste(self)
	}

	@objc func cutAction(_ sender: UICommand) {
		cut(self)
	}

	@objc func deleteAction(_ sender: UICommand) {
		delete(self)
	}
}
