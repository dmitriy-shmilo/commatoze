//

import Spreadsheet

extension SheetSelection {
	func selection(
		withColumnsShiftedBy offset: Int,
		columnCount: Int = Int.max
	) -> SheetSelection {
		let maxColumn = columnCount - 1

		switch self {
		case .rowRange(_, _), .rowSet(_), .none:
			return self
		case .cellRange(let left, let top, let right, let bottom):
			return .cellRange(
				left: max(0, left + offset),
				top: top,
				right: min(maxColumn, right + offset),
				bottom: bottom)
		case .cellSet(let indices):
			let indices = indices.map {
				return SheetIndex(
					col: min(max(0, $0.col + offset), maxColumn),
					row: $0.row,
					columnCount: columnCount)
			}
			return .cellSet(indices: .init(indices))
		case .columnRange(let from, let to):
			return .columnRange(
				from: max(0, from + offset),
				to: min(maxColumn, to + offset))
		case .columnSet(let indices):
			let indices = indices.map {
				return min(max(0, $0 + offset), maxColumn)
			}
			return .columnSet(indices: .init(indices))
		}
	}

	func selection(
		withRowsShiftedBy offset: Int,
		columnCount: Int = Int.max,
		rowCount: Int = Int.max
	) -> SheetSelection {
		let maxRow = rowCount - 1

		switch self {
		case .columnRange(_, _), .columnSet(_), .none:
			return self
		case .cellRange(let left, let top, let right, let bottom):
			return .cellRange(
				left: left,
				top: top,
				right: right,
				bottom: bottom)
		case .cellSet(let indices):
			let indices = indices.map {
				return SheetIndex(
					col: $0.col,
					row: min(max(0, $0.row + offset), maxRow),
					columnCount: columnCount)
			}
			return .cellSet(indices: .init(indices))
		case .rowRange(let from, let to):
			return .rowRange(
				from: max(0, from + offset),
				to: min(maxRow, to + offset))
		case .rowSet(let indices):
			let indices = indices.map {
				return min(max(0, $0 + offset), maxRow)
			}
			return .rowSet(indices: .init(indices))
		}
	}
}
