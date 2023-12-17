//

import UIKit
import Spreadsheet

extension ContentTableViewController: SheetViewDelegate {
	func sheet(_ sheet: SheetView, editorCellFor index: SheetIndex) -> UIView? {
		let datum = viewModel.data.value[index.index]
		let cell = UITextView()
		cell.text = datum
		cell.isEditable = true
		cell.layer.borderColor = UIColor.systemBlue.cgColor
		cell.backgroundColor = .tertiarySystemBackground
		cell.textColor = .label
		cell.font = .systemFont(ofSize: 16.0)
		return cell
	}

	func sheet(_ sheet: SheetView, didEndEditingCellAt index: SheetIndex, with editor: UIView) {
		guard let editor = editor as? UITextView,
			  let text = editor.text else {
			return
		}
		viewModel.setField(at: index, to: text)
	}
}
