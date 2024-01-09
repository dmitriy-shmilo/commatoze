//

import UIKit
import Spreadsheet

protocol ContentTextEditorViewDelegate: AnyObject {
	func textEditorDidCancelEditing(_ editor: ContentTextEditorView)
	func textEditorDidConfirmEditing(_ editor: ContentTextEditorView)
}

class ContentTextEditorView: UITextView {
	var cellIndex = SheetIndex.invalid
	weak var editorDelegate: ContentTextEditorViewDelegate?

	private var eventBusMonitor: IPDFMacEventBusMonitor?

	init() {
		super.init(frame: .zero, textContainer: nil)
		setup()
	}

	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}

	deinit {
		guard let eventBusMonitor = eventBusMonitor else {
			return
		}
		IPDFMacEventBus.shared().remove(eventBusMonitor)
	}

	// MARK: - Private Methods
	private func cancel() {
		editorDelegate?.textEditorDidCancelEditing(self)
	}

	private func confirm() {
		editorDelegate?.textEditorDidConfirmEditing(self)
	}

	private func setup() {
		let eventBusMonitor = IPDFMacEventBusMonitor(type: .keydown) { [weak self] event in
			if event.isESC() {
				self?.cancel()
				return nil
			}

			if event.cmdModifier() && event.isEnter() {
				self?.confirm()
				return nil
			}

			return event
		}
		IPDFMacEventBus.shared().add(eventBusMonitor)
		self.eventBusMonitor = eventBusMonitor

		isEditable = true
		layer.borderColor = UIColor.systemBlue.cgColor
		backgroundColor = .tertiarySystemBackground
		textColor = .label
	}
}
