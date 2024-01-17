//

import Spreadsheet

extension SheetSelection {
	func topLeft(in sheet: SheetView) -> SheetSelection {
		switch self {
		case .cellRange(let left, let top, _, _):
			return .singleCell(with: sheet.makeIndex(left, top))
		case .cellSet(let indices):
			let left = indices.map { $0.col }.reduce(Int.max, min)
			let top = indices.map { $0.row }.reduce(Int.max, min)
			return .singleCell(with: sheet.makeIndex(left, top))
		case .columnSet(let indices):
			let left = indices.reduce(Int.max, min)
			return .singleCell(with: sheet.makeIndex(left, 0))
		case .columnRange(let from, _):
			return .singleCell(with: sheet.makeIndex(from, 0))
		case .rowSet(let indices):
			let top = indices.reduce(Int.max, min)
			return .singleCell(with: sheet.makeIndex(0, top))
		case .rowRange(let from, _):
			return .singleCell(with: sheet.makeIndex(0, from))
		default:
			return .none
		}
	}

	func firstIndex(in _: SheetView) -> SheetIndex {
		switch self {
		case .cellSet(let indices):
			return indices.first ?? .invalid
		default:
			return .invalid
		}
	}

	func isColumnSelection() -> Bool {
		switch self {
		case .columnRange(_, _), .columnSet(_):
			return true
		default:
			return false
		}
	}

	func isRowSelection() -> Bool {
		switch self {
		case .rowRange(_, _), .rowSet(_):
			return true
		default:
			return false
		}
	}
}
