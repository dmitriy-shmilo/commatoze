//

import UIKit
import Spreadsheet

class ContentTableViewController: UIViewController, UIDocumentPickerDelegate {
	@IBOutlet private weak var sheet: SheetView!

	let columnCount = 20
	let rowCount = 50

	var data = [String]()

	override func viewDidLoad() {
		super.viewDidLoad()
		for y in 0..<rowCount {
			for x in 0..<columnCount {
				data.append("Col: \(x), Row: \(y)")
			}
		}

		sheet.register(SheetViewTextCell.self, forCellReuseIdentifier: "cell")
		sheet.dataSource = self
		sheet.delegate = self
		sheet.reloadData()
	}
}

extension ContentTableViewController: SheetDataSource {
	
	func sheetNumberOfFixedRows(_ sheet: SheetView, in area: SheetViewArea) -> Int {
		return 1
	}

	func sheetNumberOfFixedColumns(_ sheet: SheetView, in area: SheetViewArea) -> Int {
		return 1
	}

	func sheetColumnWidth(_ sheet: SheetView, at index: Int) -> CGFloat {
		return 150.0
	}

	func sheetRowHeight(_ sheet: SheetView, at index: Int) -> CGFloat {
		return 75.0
	}

	func sheetNumberOfColumns(_ sheet: SheetView) -> Int {
		return columnCount
	}

	func sheetNumberOfRows(_ sheet: SheetView) -> Int {
		return rowCount
	}

	func sheet(_ sheet: SheetView, cellFor index: SheetIndex) -> SheetViewCell {
		guard let cell = sheet.dequeueReusableCell(withIdentifier: "cell") as? SheetViewTextCell else {
			return .init()
		}
		let datum = data[index.index]

		cell.label.text = datum
		cell.label.font = .systemFont(ofSize: 16.0)
		cell.label.textColor = .secondaryLabel
		cell.normalBackgroundColor = .systemBackground
		cell.selectedBackgroundColor = .systemBlue.withAlphaComponent(0.3)
		return cell
	}

	func sheetNumberOfFixedTopRows(_ sheet: SheetView) -> Int {
		return 1
	}

	func sheet(_ sheet: SheetView, cellForFixedRowAt index: SheetIndex, in area: SheetViewArea) -> SheetViewCell {
		guard let cell = sheet.dequeueReusableCell(withIdentifier: "cell") as? SheetViewTextCell else {
			return .init()
		}

		cell.label.text = "\(index.col)"
		cell.label.font = .boldSystemFont(ofSize: 16.0)
		cell.label.textColor = .secondaryLabel
		cell.normalBackgroundColor = .secondarySystemBackground

		return cell
	}

	func sheet(_ sheet: SheetView, cellForFixedColumnAt index: SheetIndex, in area: SheetViewArea) -> SheetViewCell {
		guard let cell = sheet.dequeueReusableCell(withIdentifier: "cell") as? SheetViewTextCell else {
			return .init()
		}
		cell.label.textAlignment = .center
		cell.label.textColor = .secondaryLabel
		cell.label.font = .boldSystemFont(ofSize: 16.0)
		cell.label.text = "\(index.row)"

		if index.row % 2 == 0 {
			cell.normalBackgroundColor = .secondarySystemBackground
		} else {
			cell.normalBackgroundColor = .tertiarySystemBackground
		}

		return cell
	}
}

extension ContentTableViewController: SheetViewDelegate {
	func sheet(_ sheet: SheetView, shouldEditCellAt index: SheetIndex) -> Bool {
		return true
	}
	
	func sheet(_ sheet: SheetView, editorCellFor index: SheetIndex) -> UIView? {
		let datum = data[index.index]
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
		data[index.index] = (editor as? UITextView)?.text ?? ""
		sheet.reloadCellAt(index: index)
	}
}
