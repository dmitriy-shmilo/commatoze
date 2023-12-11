//

import UIKit
import Spreadsheet
import Combine

class ContentTableViewController: UIViewController, UIDocumentPickerDelegate {
	@IBOutlet private weak var sheet: SheetView!

	private let viewModel = ContentTableViewModel()
	private var subscriptions = Set<AnyCancellable>()

	override func viewDidLoad() {
		super.viewDidLoad()

		sheet.register(SheetViewTextCell.self, forCellReuseIdentifier: "cell")
		sheet.register(SheetViewTextCell.self, forCellReuseIdentifier: "top")
		sheet.register(SheetViewTextCell.self, forCellReuseIdentifier: "left")
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
		return viewModel.columns.value.count
	}

	func sheetNumberOfRows(_ sheet: SheetView) -> Int {
		return viewModel.rows.value.count
	}

	func sheet(_ sheet: SheetView, cellFor index: SheetIndex) -> SheetViewCell {
		guard let cell = sheet.dequeueReusableCell(withIdentifier: "cell") as? SheetViewTextCell else {
			return .init()
		}
		let datum = viewModel.data.value[index.index]

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
		guard let cell = sheet.dequeueReusableCell(withIdentifier: "top") as? SheetViewTextCell else {
			return .init()
		}

		cell.label.text = viewModel.columns.value[index.col]
		cell.label.font = .boldSystemFont(ofSize: 16.0)
		cell.label.textColor = .secondaryLabel
		cell.normalBackgroundColor = .secondarySystemBackground

		return cell
	}

	func sheet(_ sheet: SheetView, cellForFixedColumnAt index: SheetIndex, in area: SheetViewArea) -> SheetViewCell {
		guard let cell = sheet.dequeueReusableCell(withIdentifier: "left") as? SheetViewTextCell else {
			return .init()
		}
		cell.label.textAlignment = .center
		cell.label.textColor = .secondaryLabel
		cell.label.font = .boldSystemFont(ofSize: 16.0)
		cell.label.text = viewModel.rows.value[index.row]

		if index.row % 2 == 0 {
			cell.normalBackgroundColor = .secondarySystemBackground
		} else {
			cell.normalBackgroundColor = .tertiarySystemBackground
		}

		return cell
	}
}

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
		viewModel.setField(at: index, to: (editor as? UITextView)?.text ?? "")
	}
}
