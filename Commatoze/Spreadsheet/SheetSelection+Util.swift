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
		default:
			return .singleCell(with: .invalid)
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
}
