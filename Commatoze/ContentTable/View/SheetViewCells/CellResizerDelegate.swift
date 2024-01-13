//

import Spreadsheet

protocol CellResizerDelegate: AnyObject {
	func cellBeganResizing(_ cell: SheetViewCell)
	func cell(_ cell: SheetViewCell, updatedResizingTo size: CGFloat)
	func cell(_ cell: SheetViewCell, endedResizingTo size: CGFloat)
}
