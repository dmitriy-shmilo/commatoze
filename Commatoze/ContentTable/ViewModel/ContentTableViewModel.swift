//

import Combine
import LibCSV

// TODO: get rid of this dependency in the view model
import Spreadsheet

class ContentTableViewModel {
	enum ContentTableError: Error {
		case unknown
		case isBusy
	}

	let cellChanged = PassthroughSubject<SheetIndex, Never>()
	let undoStackChanged = PassthroughSubject<Void, Never>()

	let data = CurrentValueSubject(value: [String]())
	let columns = CurrentValueSubject(value: [String]())
	let rows = CurrentValueSubject(value: [String]())
	let currentFile = CurrentValueSubject<URL?, Never>(nil)
	let currentFileName = CurrentValueSubject(value: "")

	let isDirty = CurrentValueSubject(value: false)
	let canUndo = CurrentValueSubject(value: false)
	let canRedo = CurrentValueSubject(value: false)
	let isEditing = CurrentValueSubject(value: false)

	let isBusy = CurrentValueSubject(value: false)
	let isPickingFile = CurrentValueSubject(value: false)
	let isLoadingFile = CurrentValueSubject(value: false)
	let isSavingFile = CurrentValueSubject(value: false)

	private(set) var tempUrl: URL?

	private var undoManager = UndoManager()
	private var subscriptions = Set<AnyCancellable>()

	// TODO: abstract libcsv away
	private let parser = CSVReader()
	private var rawData = [String]()
	private var rawColumns = [String]()
	private var readingHeader = true
	private var rawUrl: URL? = nil

	init() {
		parser.delegate = self
		setupBusyFlags()
		setupData()
		setupFileUrl()
		setupUndoManager()
	}

	convenience init(with url: URL) {
		self.init()
		readFile(url: url)
	}

	// MARK: - File Handling
	func pickFile() {
		// TODO: make coordinator calls from here
		isPickingFile.send(true)
	}

	func stopPickingFile() {
		isPickingFile.send(false)
	}
	
	func readFile(url: URL) {
		guard !isBusy.value else {
			return
		}
		isLoadingFile.send(true)
		DispatchQueue.global().async { [weak self] in
			do {
				defer {
					self?.isLoadingFile.send(false)
				}
				self?.reset()
				self?.rawUrl = url
				try self?.parser.parse(url: url)
			} catch {
				// TODO: report errors to the user
			}
		}
	}

	// TODO: this method is complete trash and needs to be rewritten
	func saveTempFile() {
		guard !isBusy.value else {
			return
		}

		isSavingFile.send(true)
		defer {
			isSavingFile.send(false)
		}

		let tempDir = FileManager
			.default
			.temporaryDirectory
			.appendingPathComponent(UUID().uuidString, isDirectory: true)

		if tempUrl == nil {
			tempUrl = tempDir
				.appendingPathComponent(currentFileName.value, isDirectory: false)
		}

		if let tempUrl = tempUrl {
			do {
				// TODO: abstract file manager away
				try FileManager.default.createDirectory(
					at: tempDir,
					withIntermediateDirectories: true)
				try writeTo(url: tempUrl)
			} catch {
				// TODO: log and report to the user
			}
		}
	}

	func cleanUpTempFile() {
		guard let tempUrl = tempUrl else {
			return
		}

		try? FileManager.default.removeItem(at: tempUrl)
	}

	func saveFile(to url: URL) {
		guard !isBusy.value else {
			return
		}
		isSavingFile.send(true)

		DispatchQueue.global().async { [weak self] in
			do {
				defer {
					self?.isSavingFile.send(false)
				}

				let tempUrl = try FileManager
					.default
					.url(
						for: FileManager.SearchPathDirectory.itemReplacementDirectory,
						in: .userDomainMask,
						appropriateFor: url,
						create: true)
					.appendingPathComponent(UUID().uuidString)

				try self?.writeTo(url: tempUrl)

				if FileManager.default.fileExists(atPath: tempUrl.path) {
					let _ = try FileManager.default.replaceItemAt(url, withItemAt: tempUrl)
				}
				self?.isDirty.send(false)
			} catch {
				// TODO: report errors to the user
			}
		}
	}

	// MARK: - Editing
	func startEditing() {
		isEditing.send(true)
	}

	func stopEditing() {
		isEditing.send(false)
	}

	func setField(at index: SheetIndex, to value: String) {
		guard index.index >= 0 && index.index < data.value.count else {
			return
		}
		let previous = data.value[index.index]

		registerUndo(whileDirty: isDirty.value) { viewModel in
			viewModel.setField(at: index, to: previous)
		}

		data.value.withUnsafeMutableBufferPointer {
			$0[index.index] = value
		}

		undoStackChanged.send()
		cellChanged.send(index)
		isDirty.send(true)
	}

	func getField(at index: SheetIndex) -> String {
		guard index.index >= 0 && index.index < data.value.count else {
			return ""
		}
		return data.value[index.index]
	}

	func undo() {
		undoManager.undo()
		undoStackChanged.send()
	}

	func redo() {
		undoManager.redo()
		undoStackChanged.send()
	}

	// MARK: - Layout Editing
	func insertColumn(at insertIndex: Int) {
		// TODO: make async
		let oldData = data.value
		let rowCount = rows.value.count
		let columnCount = columns.value.count

		guard (0...columnCount).contains(insertIndex) else {
			return
		}

		registerUndo(whileDirty: isDirty.value) { viewModel in
			viewModel.removeColumns(from: insertIndex, to: insertIndex + 1)
		}

		var newData = [String]()
		newData.reserveCapacity(oldData.count + rowCount)

		for y in 0..<rowCount {
			for x in 0..<columnCount {
				if x == insertIndex {
					newData.append("")
				}

				newData.append(oldData[x + y * columnCount])

				// special case when inserting a column after the last one
				if insertIndex == columnCount && x == columnCount - 1 {
					newData.append("")
				}
			}
		}

		var newColumns = columns.value
		newColumns.insert("", at: insertIndex)

		columns.send(newColumns)
		data.send(newData)
	}

	func insertRow(at insertIndex: Int) {
		let oldData = data.value
		let rowCount = rows.value.count
		let columnCount = columns.value.count

		guard (0...rowCount).contains(insertIndex) else {
			return
		}

		registerUndo(whileDirty: isDirty.value) { viewModel in
			viewModel.removeRows(from: insertIndex, to: insertIndex + 1)
		}

		var newData = oldData
		let newRow = (0..<columnCount).map { _ in "" }
		newData.reserveCapacity(oldData.count + columnCount)
		newData.insert(contentsOf: newRow, at: insertIndex * columnCount)

		data.send(newData)
	}

	func removeColumns(from startIndex: Int, to endIndex: Int) {
		// TODO: register undo
		// TODO: support index set removal
		let oldData = data.value
		let rowCount = rows.value.count
		let columnCount = columns.value.count

		guard (0..<columnCount).contains(startIndex)
				&& (0...columnCount).contains(endIndex)
				&& endIndex > startIndex else {
			return
		}
		let removeRange = startIndex..<endIndex

		var newData = [String]()
		var newColumns = columns.value
		newData.reserveCapacity(rowCount * (columnCount - endIndex + startIndex))
		for y in 0..<rowCount {
			for x in 0..<columnCount {
				if removeRange.contains(x) {
					continue
				}

				newData.append(oldData[x + y * columnCount])
			}
		}
		newColumns.removeSubrange(removeRange)

		columns.send(newColumns)
		data.send(newData)
	}

	func removeRows(from startIndex: Int, to endIndex: Int) {
		let oldData = data.value
		let rowCount = rows.value.count
		let columnCount = columns.value.count

		guard (0..<rowCount).contains(startIndex)
				&& (0...rowCount).contains(endIndex)
				&& endIndex > startIndex else {
			return
		}

		var newData = oldData
		var newRows = rows.value
		newData.reserveCapacity(columnCount * (rowCount - endIndex + startIndex))
		newData.removeSubrange(startIndex * columnCount..<endIndex * columnCount)
		newRows.removeSubrange(startIndex..<endIndex)

		rows.send(newRows)
		data.send(newData)
	}

	// MARK: - Setup
	private func setupUndoManager() {
		undoStackChanged
			.map { [weak self] _ in
				return self?.undoManager.canUndo ?? false
			}
			.assign(to: \.value, on: canUndo)
			.store(in: &subscriptions)

		undoStackChanged
			.map { [weak self] _ in
				return self?.undoManager.canRedo ?? false
			}
			.assign(to: \.value, on: canRedo)
			.store(in: &subscriptions)
	}

	private func setupData() {
		data.combineLatest(columns)
			.map { (data, columns) in
				guard data.count > 0, columns.count > 0 else {
					return []
				}

				return (0..<(data.count / columns.count)).map {
					return "\($0)"
				}
			}
			.assign(to: \.value, on: rows)
			.store(in: &subscriptions)
	}

	private func setupFileUrl() {
		currentFile
			.map {
				guard let url = $0, url.lastPathComponent != "" else {
					return NSLocalizedString("Untitled", comment: "")
				}
				return url.lastPathComponent
			}
			.assign(to: \.value, on: currentFileName)
			.store(in: &subscriptions)
	}

	private func setupBusyFlags() {
		Publishers
			.CombineLatest3(isSavingFile, isLoadingFile, isPickingFile)
			.map {
				$0 || $1 || $2
			}
			.assign(to: \.value, on: isBusy)
			.store(in: &subscriptions)
	}

	// MARK: - Private Methods
	private func reset() {
		readingHeader = true
		rawData = []
		rawColumns = []
		isDirty.send(false)
		undoManager.removeAllActions()
		undoStackChanged.send()
	}

	private func writeTo(url: URL) throws {
		let data = data.value
		let columns = columns.value
		let writer = CSVWriter()

		try writer.start(opening: url)
		for header in columns.enumerated() {
			try writer.write(
				field: header.element,
				lastInRow: header.offset == columns.count - 1)
		}
		try writer.writeRow()

		for datum in data.enumerated() {
			let endRow = (datum.offset + 1) % columns.count == 0
			try writer.write(
				field: datum.element,
				lastInRow: endRow)
			if endRow {
				try writer.writeRow()
			}
		}

		try writer.finish()
	}

	private func registerUndo(
		whileDirty isDirty: Bool,
		handler: @escaping (ContentTableViewModel) -> Void) {
		if isDirty {
			undoManager.registerUndo(withTarget: self, handler: handler)
		} else {
			undoManager.registerUndo(withTarget: self) {
				handler($0)
				$0.isDirty.send(false)
			}
		}
	}
}

extension ContentTableViewModel: CSVReaderDelegate {
	func csvReader(_ reader: LibCSV.CSVReader, didReadField field: String) {
		if readingHeader {
			rawColumns.append(field)
		} else {
			rawData.append(field)
		}
	}

	func csvReader(_ reader: LibCSV.CSVReader, didReadRowTerminatedBy character: Character?) {
		readingHeader = false
	}

	func csvReaderDidFinish(_ reader: LibCSV.CSVReader) {
		DispatchQueue.main.async {
			self.data.send(self.rawData)
			self.columns.send(self.rawColumns)
			self.currentFile.send(self.rawUrl)
		}
	}
}
