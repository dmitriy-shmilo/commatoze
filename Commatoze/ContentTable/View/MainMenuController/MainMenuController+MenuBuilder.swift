//

import UIKit

extension MainMenuController: MenuBuilder {
	static func buildMenu(with builder: UIMenuBuilder) {
		builder.remove(menu: .format)
		builder.remove(menu: .view)

		builder.replaceChildren(ofMenu: .file) { _ in
			Self.fileMenu()
		}

		builder.replaceChildren(ofMenu: .edit) { _ in
			Self.editMenu()
		}

		builder.insertSibling(
			Self.dataMenu(),
			afterMenu: .edit)
	}

	private static func fileMenu() -> [UIMenuElement] {
		let open = UIKeyCommand(
			title: NSLocalizedString("Open...", comment: "Open"),
			action: #selector(openAction(_:)),
			input: "o",
			modifierFlags: .command)

		let openAndReplace = UIKeyCommand(
			title: NSLocalizedString(
				"Open in This Window",
				comment: "Open file replacing current content"),
			action: #selector(openAndReplaceAction(_:)),
			input: "o",
			modifierFlags: [.command, .shift])

		let openMenu = UIMenu(options: .displayInline, children: [open, openAndReplace])

		let save = UIKeyCommand(
			title: NSLocalizedString("Save", comment: "Save"),
			action: #selector(saveAction(_:)),
			input: "s",
			modifierFlags: .command)

		let saveAs = UIKeyCommand(
			title: NSLocalizedString("Save As...", comment: "Save"),
			action: #selector(saveAsAction(_:)),
			input: "s",
			modifierFlags: [.command, .shift])

		let saveMenu = UIMenu(options: .displayInline, children: [save, saveAs])

		return [openMenu, saveMenu]
	}

	private static func editMenu() -> [UIMenuElement] {
		let undo = UIKeyCommand(
			title: NSLocalizedString("Undo", comment: "Undo"),
			action: #selector(undoAction(_:)),
			input: "z",
			modifierFlags: .command)
		let redo = UIKeyCommand(
			title: NSLocalizedString("Redo", comment: "Redo"),
			action: #selector(redoAction(_:)),
			input: "z",
			modifierFlags: [.command, .shift])
		let undoMenu = UIMenu(options: .displayInline, children: [undo, redo])

		let cut = UIKeyCommand(
			title: NSLocalizedString("Cut", comment: "Cut"),
			action: #selector(cutAction(_:)),
			input: "x",
			modifierFlags: .command)
		let copy = UIKeyCommand(
			title: NSLocalizedString("Copy", comment: "Copy"),
			action: #selector(copyAction(_:)),
			input: "c",
			modifierFlags: .command)
		let paste = UIKeyCommand(
			title: NSLocalizedString("Paste", comment: "Paste"),
			action: #selector(pasteAction(_:)),
			input: "v",
			modifierFlags: .command)
		let delete = UIKeyCommand(
			title: NSLocalizedString("Delete", comment: "Delete"),
			action: #selector(deleteAction(_:)),
			input: "\u{8}",
			modifierFlags: .command)
		let editMenu = UIMenu(options: .displayInline, children: [cut, copy, paste, delete])

		return [undoMenu, editMenu]
	}

	private static func dataMenu() -> UIMenu {
		let insertColBefore = UICommand(
			title: NSLocalizedString("Insert Column Before", comment: ""),
			action: #selector(insertColumnBefore(_:))
		)

		let insertColAfter = UICommand(
			title: NSLocalizedString("Insert Column After", comment: ""),
			action: #selector(insertColumnAfter(_:))
		)

		let columnMenu = UIMenu(options: .displayInline, children: [insertColBefore, insertColAfter])

		let insertRowBefore = UICommand(
			title: NSLocalizedString("Insert Row Before", comment: ""),
			action: #selector(insertRowBefore(_:))
		)

		let insertRowAfter = UICommand(
			title: NSLocalizedString("Insert Row After", comment: ""),
			action: #selector(insertRowAfter(_:))
		)

		let rowMenu = UIMenu(options: .displayInline, children: [insertRowBefore, insertRowAfter])

		let dataMenu = UIMenu(
			title: NSLocalizedString("Data", comment: "Data"),
			children: [columnMenu, rowMenu])

		return dataMenu
	}
}
