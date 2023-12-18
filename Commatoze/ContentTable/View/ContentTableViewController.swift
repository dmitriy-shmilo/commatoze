//

import UIKit
import Spreadsheet
import Combine

class ContentTableViewController: UIViewController, UIDocumentPickerDelegate {
	@IBOutlet private weak var sheet: SheetView!

	let viewModel = ContentTableViewModel()
	var currentEditor: UITextView?

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

	override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		guard let press = presses.first,
			  let code =  press.key?.keyCode else {
			super.pressesBegan(presses, with: event)
			return
		}

		let topLeft = sheet.currentSelection.topLeft(in: sheet)
		let cellIndex = topLeft.firstIndex(in: sheet)
		guard cellIndex != .invalid else {
			super.pressesBegan(presses, with: event)
			return
		}

		if currentEditor == nil && (code == .keyboardReturnOrEnter || code == .keypadEnter) {
			sheet.setSelection(topLeft)
			sheet.editCellAt(cellIndex)
			return
		}

		if let text = press.key?.characters,
			currentEditor == nil && text.count > 0 && text.allSatisfy({
				$0.isLetter || $0.isNumber || $0.isPunctuation || $0.isWhitespace
		}) {
			sheet.setSelection(topLeft)
			sheet.editCellAt(cellIndex)
			currentEditor?.text = text
			return
		}

		super.pressesBegan(presses, with: event)
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
			return currentEditor == nil
			&& sheet.currentSelection
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

	func closeCellEditor(
		_ editor: ContentTextEditorView,
		at index: SheetIndex,
		andConfirm confirm: Bool
	) {
		guard currentEditor == editor else {
			return
		}
		if let text = editor.text, confirm {
			viewModel.setField(at: index, to: text)
		}
		currentEditor = nil
		sheet.endEditCell()
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
