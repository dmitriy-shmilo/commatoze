//

import UIKit

extension ContentTableViewController: ContentTextEditorViewDelegate {
	func textEditorDidCancelEditing(_ editor: ContentTextEditorView) {
		closeCellEditor(editor, at: editor.cellIndex, andConfirm: false)
	}

	func textEditorDidConfirmEditing(_ editor: ContentTextEditorView) {
		closeCellEditor(editor, at: editor.cellIndex, andConfirm: true)
	}
}
