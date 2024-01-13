//

import UIKit
import Spreadsheet

class HorizontalHeaderCell: SheetViewSimpleCell {
	weak var resizerDelegate: CellResizerDelegate?

	@IBOutlet private(set) weak var titleLabel: UILabel!
	@IBOutlet private(set) weak var resizerView: UIView!
	@IBOutlet private(set) weak var resizerDecoration: UIView!

	private var width: CGFloat = 0.0
	private var resizerStartPoint: CGPoint?

	override func awakeFromNib() {
		super.awakeFromNib()
		setup()
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		resizerDecoration.isHidden = true
	}

	// MARK: - Private Methods
	private func setup() {
		isUserInteractionEnabled = true
		let resizerHoverRecognizer = UIHoverGestureRecognizer(target: self, action: #selector(onResizerHover))
		let resizerDragRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onResizerDrag))
		resizerView.addGestureRecognizer(resizerDragRecognizer)
		resizerView.addGestureRecognizer(resizerHoverRecognizer)
	}

	@IBAction private func onResizerDrag(_ sender: UIPanGestureRecognizer) {
		guard let delegate = resizerDelegate else {
			return
		}

		let point = sender.translation(in: self)
		switch sender.state {
		case .began:
			resizerStartPoint = point
			width = frame.width
			delegate.cellBeganResizing(self)
		case .changed:
			guard let start = resizerStartPoint else {
				return
			}
			let offset = point.x - start.x
			delegate.cell(self, updatedResizingTo: width + offset)
		case .ended:
			guard let start = resizerStartPoint else {
				return
			}
			let offset = point.x - start.x
			delegate.cell(self, endedResizingTo: width + offset)

			resizerStartPoint = nil
			resizerDecoration.isHidden = true
			if NSCursor.current == NSCursor.resizeLeftRight {
				NSCursor.pop()
			}
		default:
			break
		}
	}

	@IBAction private func onResizerHover(_ sender: UIHoverGestureRecognizer) {
		switch sender.state {
		case .began:
			NSCursor.resizeLeftRight.push()
			resizerDecoration.isHidden = false
		case .ended:
			NSCursor.pop()
			resizerDecoration.isHidden = true
		default:
			break
		}
	}
}
