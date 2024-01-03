//

import Combine
import LibCSV

// TODO: get rid of this dependency in the view model
import Spreadsheet

class ContentTableViewModel {
	let cellChanged = PassthroughSubject<SheetIndex, Never>()
	let undoStackChanged = PassthroughSubject<Void, Never>()

	let data = CurrentValueSubject(value: [String]())
	let columns = CurrentValueSubject(value: [String]())
	let rows = CurrentValueSubject(value: [String]())
	let currentFile = CurrentValueSubject<URL?, Never>(nil)
	let currentFileName = CurrentValueSubject(value: "")
	let canUndo = CurrentValueSubject(value: false)
	let canRedo = CurrentValueSubject(value: false)
	let isBusy = CurrentValueSubject(value: false)

	let isLoadingFile = CurrentValueSubject(value: false)
	let isSavingFile = CurrentValueSubject(value: false)

	private var undoManager = UndoManager()
	private var subscriptions = Set<AnyCancellable>()

	// TODO: abstract libcsv away
	private let parser = CSVReader()
	private var rawData = [String]()
	private var rawColumns = [String]()
	private var readingHeader = true
	private var rawUrl: URL?

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

				guard let data = self?.data.value,
					  let columns = self?.columns.value else {
					return
				}

				let writer = CSVWriter()
				let tempUrl = try FileManager
					.default
					.url(
						for: FileManager.SearchPathDirectory.itemReplacementDirectory,
						in: .userDomainMask,
						appropriateFor: url,
						create: true)
					.appendingPathComponent(UUID().uuidString)

				try writer.start(opening: tempUrl)
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

				if FileManager.default.fileExists(atPath: tempUrl.path) {
					let _ = try FileManager.default.replaceItemAt(url, withItemAt: tempUrl)
				}
			} catch {
				// TODO: report errors to the user
			}
		}
	}

	func setField(at index: SheetIndex, to value: String) {
		guard index.index >= 0 && index.index < data.value.count else {
			return
		}
		let previous = data.value[index.index]
		undoManager.registerUndo(withTarget: self) { viewModel in
			viewModel.setField(at: index, to: previous)
		}
		data.value.withUnsafeMutableBufferPointer {
			$0[index.index] = value
		}

		undoStackChanged.send()
		cellChanged.send(index)
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
			.CombineLatest(isSavingFile, isLoadingFile)
			.map {
				$0 || $1
			}
			.assign(to: \.value, on: isBusy)
			.store(in: &subscriptions)
	}

	// MARK: - Private Methods
	private func reset() {
		readingHeader = true
		rawData = []
		rawColumns = []
		undoManager.removeAllActions()
		undoStackChanged.send()
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
		data.send(rawData)
		columns.send(rawColumns)
		currentFile.send(rawUrl)
	}
}
