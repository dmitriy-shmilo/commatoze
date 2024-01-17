//

import UIKit
import Spreadsheet

class MainMenuController: NSObject {
	weak var sheet: SheetView?
	weak var coordinator: ContentTableCoordinator?
	weak var viewModel: ContentTableViewModel?

	init(sheet: SheetView? = nil,
		 coordinator: ContentTableCoordinator? = nil,
		 viewModel: ContentTableViewModel? = nil) {
		self.sheet = sheet
		self.coordinator = coordinator
		self.viewModel = viewModel
	}

	func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		guard let sheet = sheet,
			  let viewModel = viewModel else {
			return false
		}

		let enabledActions = [
			#selector(openAction(_:)),
			#selector(openAndReplaceAction(_:)),
			#selector(saveAsAction(_:))
		]

		if enabledActions.contains(action) {
			return true
		}

		if action == #selector(saveAction(_:)) {
			return viewModel.canUndo.value
		}

		let selectionActions = [
			#selector(cutAction(_:)),
			#selector(copyAction(_:)),
			#selector(pasteAction(_:)),
			#selector(deleteAction(_:)),
		]
		if selectionActions.contains(action) {
			return !viewModel.isEditing.value
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
			return !viewModel.isEditing.value
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
			return !viewModel.isEditing.value
			&& sheet.currentSelection
				.topLeft(in: sheet)
				.firstIndex(in: sheet)
				.col != SheetIndex.invalid.col
		}

		return false
	}

	// MARK: - File
	@objc func openAction(_ sender: UICommand) {
		coordinator?.presentOpenFilePicker(willReplaceContent: false)
	}

	@objc func openAndReplaceAction(_ sender: UICommand) {
		viewModel?.pickFile()
		coordinator?.presentOpenFilePicker(willReplaceContent: true)
	}

	@objc func saveAction(_ sender: UICommand) {
		guard let viewModel = viewModel else {
			return
		}
		if let url = viewModel.currentFile.value {
			viewModel.saveFile(to: url)
			return
		}

		saveAsAction(sender)
	}

	@objc func saveAsAction(_ sender: UICommand) {
		guard let viewModel = viewModel else {
			return
		}
		viewModel.saveTempFile()
		viewModel.pickFile()
		if let tempUrl = viewModel.tempUrl {
			coordinator?.presentSaveFilePicker(for: tempUrl)
		}
	}

	// MARK: - Edit
	@objc func undoAction(_ sender: UICommand) {
		guard let viewModel = viewModel else {
			return
		}
		guard viewModel.canUndo.value else {
			return
		}
		viewModel.undo()
	}

	@objc func redoAction(_ sender: UICommand) {
		guard let viewModel = viewModel else {
			return
		}
		guard viewModel.canRedo.value else {
			return
		}
		viewModel.redo()
	}

	@objc func copyAction(_ sender: UICommand?) {
		guard let sheet = sheet,
			  let viewModel = viewModel else {
			return
		}

		let topLeft = sheet.currentSelection
			.topLeft(in: sheet)
			.firstIndex(in: sheet)
		guard topLeft != .invalid else {
			return
		}

		UIPasteboard.general.string = viewModel.getField(at: topLeft)
	}

	@objc func pasteAction(_ sender: UICommand?) {
		guard let sheet = sheet,
			  let viewModel = viewModel else {
			return
		}
		
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

	@objc func deleteAction(_ sender: UICommand?) {
		guard let sheet = sheet,
			  let viewModel = viewModel else {
			return
		}

		let topLeft = sheet.currentSelection
			.topLeft(in: sheet)
			.firstIndex(in: sheet)

		guard topLeft != .invalid else {
			return
		}

		viewModel.setField(at: topLeft, to: "")
	}

	@objc func cutAction(_ sender: UICommand?) {
		guard let sheet = sheet,
			  let viewModel = viewModel else {
			return
		}

		let topLeft = sheet.currentSelection
			.topLeft(in: sheet)
			.firstIndex(in: sheet)
		guard topLeft != .invalid else {
			return
		}

		UIPasteboard.general.string = viewModel.getField(at: topLeft)
		viewModel.setField(at: topLeft, to: "")
	}

	// MARK: - Data
	@objc func insertColumnBefore(_ sender: UICommand) {
		guard let sheet = sheet,
			  let viewModel = viewModel else {
			return
		}
		let column = sheet
			.currentSelection
			.topLeft(in: sheet)
			.firstIndex(in: sheet)
			.col
		viewModel.insertColumn(at: column)
	}

	@objc func insertColumnAfter(_ sender: UICommand) {
		guard let sheet = sheet,
			  let viewModel = viewModel else {
			return
		}
		let column = sheet
			.currentSelection
			.topLeft(in: sheet)
			.firstIndex(in: sheet)
			.col + 1
		viewModel.insertColumn(at: column)
	}

	@objc func insertRowBefore(_ sender: UICommand) {
		guard let sheet = sheet,
			  let viewModel = viewModel else {
			return
		}
		let row = sheet
			.currentSelection
			.topLeft(in: sheet)
			.firstIndex(in: sheet)
			.row
		viewModel.insertRow(at: row)
	}

	@objc func insertRowAfter(_ sender: UICommand) {
		guard let sheet = sheet,
			  let viewModel = viewModel else {
			return
		}
		let row = sheet
			.currentSelection
			.topLeft(in: sheet)
			.firstIndex(in: sheet)
			.row + 1
		viewModel.insertRow(at: row)
	}
}


