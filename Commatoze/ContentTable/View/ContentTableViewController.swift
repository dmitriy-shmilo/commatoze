//

import UIKit
import Spreadsheet
import Combine

class ContentTableViewController: UIViewController {
	@IBOutlet private weak var sheet: SheetView!

	let viewModel = ContentTableViewModel()
	var currentEditor: UITextView?

	private var subscriptions = Set<AnyCancellable>()

	override func viewDidLoad() {
		super.viewDidLoad()

		setupSheet()
		setupCurrentFile()
		setupCells()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		guard let url = Bundle.main.url(forResource: "test", withExtension: ".csv") else {
			return
		}
		viewModel.readFile(url: url)
	}



	override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		guard let press = presses.first else {
			super.pressesBegan(presses, with: event)
			return
		}

		if updateSelectionIn(sheet: sheet, whenKeyPressed: press) {
			return
		}

		if startEditingCellIn(sheet: sheet, whenKeyPressed: press) {
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

		if action == #selector(undoAction(_:)) {
			return viewModel.canUndo.value
		}

		if action == #selector(redoAction(_:)) {
			return viewModel.canRedo.value
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

	// MARK: - Menu Actions
	func openFile() {
		let controller = UIDocumentPickerViewController(
			documentTypes: ["public.text"],
			in: .open)
		// TODO: allow opening multiple documents
		controller.allowsMultipleSelection = false
		controller.delegate = self
		present(controller, animated: true)
	}

	func saveFile() {
		// TODO: show the save picker
		guard let url = viewModel.currentFile.value else {
			return
		}
		viewModel.saveFile(to: url)
	}

	func undo() {
		guard viewModel.canUndo.value else {
			return
		}
		viewModel.undo()
	}

	func redo() {
		guard viewModel.canRedo.value else {
			return
		}
		viewModel.redo()
	}

	// MARK: - Setup
	private func setupSheet() {
		sheet.register(SheetViewLabelCell.self, forCellReuseIdentifier: "cell")
		sheet.register(SheetViewLabelCell.self, forCellReuseIdentifier: "top")
		sheet.register(SheetViewLabelCell.self, forCellReuseIdentifier: "left")
		sheet.dataSource = self
		sheet.delegate = self
	}

	private func setupCurrentFile() {
		viewModel.currentFile
			.sink { [weak self] _ in
				self?.sheet.reloadData()
			}
			.store(in: &subscriptions)

		viewModel.currentFileName
			.sink { [weak self] name in
				self?.view?.window?.windowScene?.title = name
			}
			.store(in: &subscriptions)
	}

	private func setupCells() {
		viewModel.cellChanged
			.sink { [weak self] index in
				self?.sheet.reloadCellAt(index: index)
			}
			.store(in: &subscriptions)
	}
}

extension ContentTableViewController {
	func startEditingCellIn(sheet: SheetView, whenKeyPressed press: UIPress) -> Bool {
		guard let code = press.key?.keyCode else {
			return false
		}

		guard currentEditor == nil else {
			return false
		}

		let topLeft = sheet.currentSelection.topLeft(in: sheet)
		let cellIndex = topLeft.firstIndex(in: sheet)

		guard cellIndex != .invalid else {
			return false
		}

		if code == .keyboardReturnOrEnter || code == .keypadEnter || code == .keyboardReturn {
			sheet.setSelection(topLeft)
			sheet.scrollToCurrentSelection(animated: true)
			sheet.editCellAt(cellIndex)
			return true
		}

		if let text = press.key?.characters,
		   text.count > 0 && text.allSatisfy({
				$0.isLetter || $0.isNumber || $0.isPunctuation || $0.isWhitespace
		}) {
			sheet.setSelection(topLeft)
			sheet.scrollToCurrentSelection(animated: true)
			sheet.editCellAt(cellIndex)
			currentEditor?.text = text
			return true
		}

		return false
	}

	func updateSelectionIn(sheet: SheetView, whenKeyPressed press: UIPress) -> Bool {
		guard currentEditor == nil else {
			return false
		}

		switch sheet.currentSelection {
		case .cellRange(_, _, _, _), .cellSet(_):
			return updateCellSelectionIn(sheet: sheet, whenKeyPressed: press)
		case .columnRange(_, _), .columnSet(_):
			return updateColumnSelectionIn(sheet: sheet, whenKeyPressed: press)
		default:
			return false
		}
	}

	func updateCellSelectionIn(sheet: SheetView, whenKeyPressed press: UIPress) -> Bool {
		guard let code = press.key?.keyCode else {
			return false
		}

		let topLeft = sheet.currentSelection.topLeft(in: sheet)
		let cellIndex = topLeft.firstIndex(in: sheet)

		switch code {
		case .keyboardUpArrow:
			let cellIndex = cellIndex.indexByAdding(rows: -1, in: sheet)
			guard cellIndex != .invalid else {
				return false
			}
			sheet.setSelection(.singleCell(with: cellIndex))
			sheet.scrollToCurrentSelection(animated: true)
			return true
		case .keyboardDownArrow:
			let cellIndex = cellIndex.indexByAdding(rows: 1, in: sheet)
			guard cellIndex != .invalid else {
				return false
			}
			sheet.setSelection(.singleCell(with: cellIndex))
			sheet.scrollToCurrentSelection(animated: true)
			return true
		case .keyboardLeftArrow:
			let cellIndex = cellIndex.indexByAdding(columns: -1, in: sheet)
			guard cellIndex != .invalid else {
				return false
			}
			sheet.setSelection(.singleCell(with: cellIndex))
			sheet.scrollToCurrentSelection(animated: true)
			return true
		case .keyboardRightArrow:
			let cellIndex = cellIndex.indexByAdding(columns: 1, in: sheet)
			guard cellIndex != .invalid else {
				return false
			}
			sheet.setSelection(.singleCell(with: cellIndex))
			sheet.scrollToCurrentSelection(animated: true)
			return true
		case .keyboardEscape:
			guard topLeft != .none else {
				return false
			}
			sheet.setSelection(.none)
			return true
		default:
			return false
		}
	}

	func updateColumnSelectionIn(sheet: SheetView, whenKeyPressed press: UIPress) -> Bool {
		guard let code = press.key?.keyCode else {
			return false
		}

		let topLeft = sheet.currentSelection.topLeft(in: sheet)
		let topLeftIndex = topLeft.firstIndex(in: sheet)
		let left = topLeftIndex.col

		guard topLeftIndex != .invalid else {
			return false
		}

		switch code {
		case .keyboardDownArrow:
			sheet.setSelection(.singleCell(with: topLeftIndex))
			sheet.scrollToCurrentSelection(animated: true)
			return true
		case .keyboardLeftArrow:
			let column = left - 1
			guard sheet.isValid(column: column) else {
				return false
			}
			sheet.setSelection(.singleColumn(with: column))
			sheet.scrollToCurrentSelection(animated: true)
			return true
		case .keyboardRightArrow:
			let column = left + 1
			guard sheet.isValid(column: column) else {
				return false
			}
			sheet.setSelection(.singleColumn(with: column))
			sheet.scrollToCurrentSelection(animated: true)
			return true
		case .keyboardEscape:
			guard topLeft != .none else {
				return false
			}
			sheet.setSelection(.none)
			return true
		default:
			return false
		}
	}
}

// MARK: - Menu Actions
extension ContentTableViewController {
	// MARK: - File
	@objc func openAction(_ sender: UICommand) {
		openFile()
	}

	@objc func saveAction(_ sender: UICommand) {
		saveFile()
	}

	// MARK: - Edit
	@objc func undoAction(_ sender: UICommand) {
		undo()
	}

	@objc func redoAction(_ sender: UICommand) {
		redo()
	}
	
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
