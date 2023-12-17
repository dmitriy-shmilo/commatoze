//

import UIKit

struct MainMenu {
	static func editMenu() -> [UIMenuElement] {
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

		return [cut, copy, paste, delete]
	}
}
