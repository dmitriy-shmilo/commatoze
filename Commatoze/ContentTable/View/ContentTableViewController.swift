//

import UIKit
import Spreadsheet
import Combine

class ContentTableViewController: UIViewController {
	@IBOutlet private weak var sheet: SheetView!
	@IBOutlet private weak var loadingOverlay: UIView!

	weak var coordinator: ContentTableCoordinator?
	var viewModel: ContentTableViewModel!
	let isPickingFile = CurrentValueSubject(value: false)
	var currentEditor: UITextView?

	private(set) var horizontalResizer: HorizontalCellResizer!
	private(set) var verticalResizer: VerticalCellResizer!

	private var subscriptions = Set<AnyCancellable>()

	override func viewDidLoad() {
		super.viewDidLoad()
		setup()
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

		let rowActions = [
			#selector(insertRowBefore(_:)),
			#selector(insertRowAfter(_:))
		]

		if rowActions.contains(action) {
			return currentEditor == nil
			&& sheet.currentSelection
				.topLeft(in: sheet)
				.firstIndex(in: sheet)
				.row != SheetIndex.invalid.row
		}

		let columnActions = [
			#selector(insertColumnAfter(_:)),
			#selector(insertColumnBefore(_:))
		]

		if columnActions.contains(action) {
			return currentEditor == nil
			&& sheet.currentSelection
				.topLeft(in: sheet)
				.firstIndex(in: sheet)
				.col != SheetIndex.invalid.col
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
	func openFile(andReplace replace: Bool) {
		coordinator?.presentOpenFilePicker(willReplaceContent: replace)
	}

	func saveFile(andReplace replace: Bool) {
		if let url = viewModel.currentFile.value, replace {
			viewModel.saveFile(to: url)
			return
		}

		viewModel.saveTempFile()
		if let tempUrl = viewModel.tempUrl {
			coordinator?.presentSaveFilePicker(for: tempUrl)
		}
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
	private func setup() {
		subscriptions.removeAll()
		setupLoadingOverlay()
		setupSheet()
		setupCurrentFile()
		setupCells()
		setupInteractions()
	}
	
	private func setupSheet() {
		sheet.register(SheetViewLabelCell.self, forCellReuseIdentifier: "cell")
		sheet.register(.init(nibName: "HorizontalHeaderCell", bundle: .main), forCellReuseIdentifier: "top")
		sheet.register(.init(nibName: "VerticalHeaderCell", bundle: .main), forCellReuseIdentifier: "left")
		sheet.dataSource = self
		sheet.delegate = self

		horizontalResizer = .init(sheet: sheet)
		verticalResizer = .init(sheet: sheet)
	}

	private func setupCurrentFile() {
		viewModel.currentFile
			.receive(on: DispatchQueue.main)
			.sink { [weak self] _ in
				self?.sheet.reloadData()
			}
			.store(in: &subscriptions)

		viewModel.currentFileName
			.receive(on: DispatchQueue.main)
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

		viewModel.data
			.sink { [weak self] _ in
				self?.sheet.reloadData()
			}
			.store(in: &subscriptions)

		viewModel.rows
			.sink { [weak self] _ in
				self?.sheet.reloadData()
			}
			.store(in: &subscriptions)

		viewModel.columns
			.sink { [weak self] _ in
				self?.sheet.reloadData()
			}
			.store(in: &subscriptions)
	}

	private func setupLoadingOverlay() {
		loadingOverlay.backgroundColor = loadingOverlay.backgroundColor?.withAlphaComponent(0.5)
		viewModel.isBusy.combineLatest(isPickingFile)
			.map { (busy, picking) in !(busy || picking) }
			.receive(on: DispatchQueue.main)
			.assign(to: \.isHidden, on: loadingOverlay)
			.store(in: &subscriptions)
	}

	private func setupInteractions() {
		let dropInteraction = UIDropInteraction(delegate: self)
		view.addInteraction(dropInteraction)
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
		case .rowRange(_, _), .rowSet(_):
			return updateRowSelectionIn(sheet: sheet, whenKeyPressed: press)
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

	func updateRowSelectionIn(sheet: SheetView, whenKeyPressed press: UIPress) -> Bool {
		guard let code = press.key?.keyCode else {
			return false
		}

		let topLeft = sheet.currentSelection.topLeft(in: sheet)
		let topLeftIndex = topLeft.firstIndex(in: sheet)
		let top = topLeftIndex.row

		guard topLeftIndex != .invalid else {
			return false
		}

		switch code {
		case .keyboardDownArrow:
			let row = top + 1
			guard sheet.isValid(row: row) else {
				return false
			}
			sheet.setSelection(.singleRow(with: row))
			sheet.scrollToCurrentSelection(animated: true)
			return true
		case .keyboardUpArrow:
			let row = top - 1
			guard sheet.isValid(row: row) else {
				return false
			}
			sheet.setSelection(.singleRow(with: row))
			sheet.scrollToCurrentSelection(animated: true)
			return true
		case .keyboardRightArrow:
			sheet.setSelection(.singleCell(with: topLeftIndex))
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
		openFile(andReplace: false)
	}

	@objc func openAndReplaceAction(_ sender: UICommand) {
		openFile(andReplace: true)
	}

	@objc func saveAction(_ sender: UICommand) {
		saveFile(andReplace: true)
	}

	@objc func saveAsAction(_ sender: UICommand) {
		saveFile(andReplace: false)
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

	// MARK: - Data
	// TODO: extract into a separate menu controller
	@objc func insertColumnBefore(_ sender: UICommand) {
		let column = sheet
			.currentSelection
			.topLeft(in: sheet)
			.firstIndex(in: sheet)
			.col
		viewModel.insertColumn(at: column)
	}

	@objc func insertColumnAfter(_ sender: UICommand) {
		let column = sheet
			.currentSelection
			.topLeft(in: sheet)
			.firstIndex(in: sheet)
			.col + 1
		viewModel.insertColumn(at: column)
	}

	@objc func insertRowBefore(_ sender: UICommand) {
		let row = sheet
			.currentSelection
			.topLeft(in: sheet)
			.firstIndex(in: sheet)
			.row
		viewModel.insertRow(at: row)
	}

	@objc func insertRowAfter(_ sender: UICommand) {
		let row = sheet
			.currentSelection
			.topLeft(in: sheet)
			.firstIndex(in: sheet)
			.row + 1
		viewModel.insertRow(at: row)
	}
}

class HorizontalCellResizer: CellResizerDelegate {

	private weak var sheet: SheetView?

	init(sheet: SheetView?) {
		self.sheet = sheet
	}

	func cellBeganResizing(_ cell: Spreadsheet.SheetViewCell) {
		sheet?.beginResizingColumn(at: cell.sheetIndex.col)
	}

	func cell(_ cell: Spreadsheet.SheetViewCell, updatedResizingTo size: CGFloat) {
		sheet?.updateResizingColumn(at: cell.sheetIndex.col, to: size)
	}

	func cell(_ cell: Spreadsheet.SheetViewCell, endedResizingTo size: CGFloat) {
		sheet?.endResizingColumn()
		sheet?.setWidth(size, for: cell.sheetIndex.col)
	}
}

class VerticalCellResizer: CellResizerDelegate {

	private weak var sheet: SheetView?

	init(sheet: SheetView?) {
		self.sheet = sheet
	}

	func cellBeganResizing(_ cell: Spreadsheet.SheetViewCell) {
		sheet?.beginResizingRow(at: cell.sheetIndex.row)
	}

	func cell(_ cell: Spreadsheet.SheetViewCell, updatedResizingTo size: CGFloat) {
		sheet?.updateResizingRow(at: cell.sheetIndex.row, to: size)
	}

	func cell(_ cell: Spreadsheet.SheetViewCell, endedResizingTo size: CGFloat) {
		sheet?.endResizingRow()
		sheet?.setHeight(size, for: cell.sheetIndex.row)
	}
}


