//

import UIKit
import Spreadsheet

protocol ContentTextEditorViewDelegate: AnyObject {
	func textEditorDidCancelEditing(_ editor: ContentTextEditorView)
	func textEditorDidConfirmEditing(_ editor: ContentTextEditorView)
}

class ContentTextEditorView: UITextView, UITextViewDelegate {
	var cellIndex = SheetIndex.invalid
	weak var editorDelegate: ContentTextEditorViewDelegate?

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

	override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		// TODO: pressesBegan is not called for Esc and Return keys and should be handled on a lower level
		// see https://stackoverflow.com/a/72409736/575979 and https://github.com/mmackh/Catalyst-Helpers
		guard let key = presses.first?.key else {
			super.pressesBegan(presses, with: event)
			return
		}
		if key.keyCode == .keyboardEscape {
			editorDelegate?.textEditorDidCancelEditing(self)
			return
		}

		if (key.keyCode == .keypadEnter || key.keyCode == .keyboardReturnOrEnter)
			&& key.modifierFlags == .command {
			editorDelegate?.textEditorDidConfirmEditing(self)
			return
		}

		super.pressesBegan(presses, with: event)
	}

	// MARK: - Private Methods
	private func setup() {
		delegate = self
		isEditable = true
		layer.borderColor = UIColor.systemBlue.cgColor
		backgroundColor = .tertiarySystemBackground
		textColor = .label
	}
}

extension ContentTextEditorView: UITextFieldDelegate {
	func textViewDidEndEditing(_ textView: UITextView) {
		editorDelegate?.textEditorDidCancelEditing(self)
	}
}
