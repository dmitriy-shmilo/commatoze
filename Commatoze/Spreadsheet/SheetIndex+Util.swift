//

import Spreadsheet

extension SheetIndex {
	func indexByAdding(columns: Int, in sheet: SheetView) -> SheetIndex {
		guard self != .invalid else {
			return .invalid
		}
		guard sheet.isValid(column: col + columns) else {
			return .invalid
		}
		return sheet.makeIndex(col + columns, row)
	}

	func indexByAdding(rows: Int, in sheet: SheetView) -> SheetIndex {
		guard self != .invalid else {
			return .invalid
		}
		guard sheet.isValid(row: row + rows) else {
			return .invalid
		}
		return sheet.makeIndex(col, row + rows)
	}
}
