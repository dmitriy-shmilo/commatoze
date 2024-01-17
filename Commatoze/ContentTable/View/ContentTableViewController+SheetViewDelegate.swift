//

import UIKit
import Spreadsheet

extension ContentTableViewController: SheetViewDelegate {
	func sheet(_ sheet: SheetView, editorCellFor index: SheetIndex) -> UIView? {
		let datum = viewModel.data.value[index.index]
		let editor = ContentTextEditorView()
		editor.cellIndex = index
		editor.text = datum
		editor.font = .systemFont(ofSize: 16.0)
		editor.editorDelegate = self
		currentEditor = editor
		viewModel.startEditing()
		return editor
	}

	func sheet(_ sheet: SheetView, didEndEditingCellAt index: SheetIndex, with editor: UIView) {
		guard let editor = editor as? ContentTextEditorView else {
			return
		}
		closeCellEditor(editor, at: index, andConfirm: true)
	}
}
