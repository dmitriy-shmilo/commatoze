//

import Spreadsheet

extension ContentTableViewController: SheetViewDataSource {
	private static let maxCharCount = 512

	func sheetColumnWidth(_ sheet: SheetView, at index: Int) -> CGFloat {
		return 200.0
	}

	func sheetRowHeight(_ sheet: SheetView, at index: Int) -> CGFloat {
		return 50.0
	}

	func sheetNumberOfFixedRows(_ sheet: SheetView, in area: SheetViewArea) -> Int {
		return 1
	}

	func sheetNumberOfFixedColumns(_ sheet: SheetView, in area: SheetViewArea) -> Int {
		return 1
	}

	func sheetNumberOfFixedTopRows(_ sheet: SheetView) -> Int {
		return 1
	}

	func sheetNumberOfColumns(_ sheet: SheetView) -> Int {
		return viewModel.columns.value.count
	}

	func sheetNumberOfRows(_ sheet: SheetView) -> Int {
		return viewModel.rows.value.count
	}

	func sheet(_ sheet: SheetView, cellFor index: SheetIndex) -> SheetViewCell {
		guard let cell = sheet.dequeueReusableCell(withIdentifier: "cell") as? SheetViewLabelCell else {
			return .init()
		}
		let datum = viewModel.data.value[index.index]

		if datum.count > Self.maxCharCount {
			let endIndex = datum.index(datum.startIndex, offsetBy: Self.maxCharCount)
			cell.label.text = String(datum[..<endIndex])
		} else {
			cell.label.text = datum
		}
		cell.label.font = .systemFont(ofSize: 16.0)
		return cell
	}

	func sheet(_ sheet: SheetView, cellForFixedRowAt index: SheetIndex, in area: SheetViewArea) -> SheetViewCell {
		guard let cell = sheet.dequeueReusableCell(withIdentifier: "top") as? HorizontalHeaderCell else {
			return .init()
		}
		let datum = viewModel.columns.value[index.col]

		if datum.count > Self.maxCharCount {
			let endIndex = datum.index(datum.startIndex, offsetBy: Self.maxCharCount)
			cell.titleLabel.text = String(datum[..<endIndex])
		} else {
			cell.titleLabel.text = datum
		}
		cell.titleLabel.font = .boldSystemFont(ofSize: 16.0)
		cell.normalBackgroundColor = .secondarySystemBackground
		cell.resizerDelegate = horizontalResizer

		return cell
	}

	func sheet(_ sheet: SheetView, cellForFixedColumnAt index: SheetIndex, in area: SheetViewArea) -> SheetViewCell {
		guard let cell = sheet.dequeueReusableCell(withIdentifier: "left") as? VerticalHeaderCell else {
			return .init()
		}
		let datum = viewModel.rows.value[index.row]

		if datum.count > Self.maxCharCount {
			let endIndex = datum.index(datum.startIndex, offsetBy: Self.maxCharCount)
			cell.titleLabel.text = String(datum[..<endIndex])
		} else {
			cell.titleLabel.text = datum
		}
		cell.titleLabel.textAlignment = .center
		cell.titleLabel.font = .boldSystemFont(ofSize: 16.0)
		cell.resizerDelegate = verticalResizer

		if index.row % 2 == 0 {
			cell.normalBackgroundColor = .secondarySystemBackground
		} else {
			cell.normalBackgroundColor = .tertiarySystemBackground
		}

		return cell
	}
}
