//

import UIKit

struct MainMenu {
	static func fileMenu() -> [UIMenuElement] {
		let open = UIKeyCommand(
			title: NSLocalizedString("Open...", comment: "Open"),
			action: #selector(ContentTableViewController.openAction(_:)),
			input: "o",
			modifierFlags: .command)

		let openAndReplace = UIKeyCommand(
			title: NSLocalizedString(
				"Open in This Window",
				comment: "Open file replacing current content"),
			action: #selector(ContentTableViewController.openAndReplaceAction(_:)),
			input: "o",
			modifierFlags: [.command, .shift])

		let openMenu = UIMenu(options: .displayInline, children: [open, openAndReplace])

		let save = UIKeyCommand(
			title: NSLocalizedString("Save", comment: "Save"),
			action: #selector(ContentTableViewController.saveAction(_:)),
			input: "s",
			modifierFlags: .command)

		let saveAs = UIKeyCommand(
			title: NSLocalizedString("Save As...", comment: "Save"),
			action: #selector(ContentTableViewController.saveAsAction(_:)),
			input: "s",
			modifierFlags: [.command, .shift])

		let saveMenu = UIMenu(options: .displayInline, children: [save, saveAs])

		return [openMenu, saveMenu]
	}

	static func editMenu() -> [UIMenuElement] {
		let undo = UIKeyCommand(
			title: NSLocalizedString("Undo", comment: "Undo"),
			action: #selector(ContentTableViewController.undoAction(_:)),
			input: "z",
			modifierFlags: .command)
		let redo = UIKeyCommand(
			title: NSLocalizedString("Redo", comment: "Redo"),
			action: #selector(ContentTableViewController.redoAction(_:)),
			input: "z",
			modifierFlags: [.command, .shift])
		let undoMenu = UIMenu(options: .displayInline, children: [undo, redo])

		let cut = UIKeyCommand(
			title: NSLocalizedString("Cut", comment: "Cut"),
			action: #selector(ContentTableViewController.cutAction(_:)),
			input: "x",
			modifierFlags: .command)
		let copy = UIKeyCommand(
			title: NSLocalizedString("Copy", comment: "Copy"),
			action: #selector(ContentTableViewController.copyAction(_:)),
			input: "c",
			modifierFlags: .command)
		let paste = UIKeyCommand(
			title: NSLocalizedString("Paste", comment: "Paste"),
			action: #selector(ContentTableViewController.pasteAction(_:)),
			input: "v",
			modifierFlags: .command)
		let delete = UIKeyCommand(
			title: NSLocalizedString("Delete", comment: "Delete"),
			action: #selector(ContentTableViewController.deleteAction(_:)),
			input: "\u{8}",
			modifierFlags: .command)
		let editMenu = UIMenu(options: .displayInline, children: [cut, copy, paste, delete])

		return [undoMenu, editMenu]
	}
}
