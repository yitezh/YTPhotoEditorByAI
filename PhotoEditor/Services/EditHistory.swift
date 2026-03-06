import Foundation

/// Manages undo/redo history using parameter snapshots.
/// Each edit operation pushes a snapshot of EditParameters onto the undo stack.
/// Undo pops from the undo stack and pushes onto the redo stack.
/// Any new push after an undo clears the redo stack.
class EditHistory {

    private var undoStack: [EditParameters] = []
    private var redoStack: [EditParameters] = []

    /// Whether there are operations that can be undone.
    var canUndo: Bool {
        return !undoStack.isEmpty
    }

    /// Whether there are operations that can be redone.
    var canRedo: Bool {
        return !redoStack.isEmpty
    }

    /// The number of entries in the undo stack (for testing).
    var undoCount: Int {
        return undoStack.count
    }

    /// The number of entries in the redo stack (for testing).
    var redoCount: Int {
        return redoStack.count
    }

    /// Push a new edit state onto the history.
    /// Clears the redo stack since a new branch of edits has started.
    func push(_ parameters: EditParameters) {
        undoStack.append(parameters)
        redoStack.removeAll()
    }

    /// Undo the last edit operation.
    /// Returns the previous EditParameters, or nil if there is nothing to undo.
    @discardableResult
    func undo() -> EditParameters? {
        guard let last = undoStack.popLast() else { return nil }
        redoStack.append(last)
        return undoStack.last
    }

    /// Redo the most recently undone operation.
    /// Returns the restored EditParameters, or nil if there is nothing to redo.
    @discardableResult
    func redo() -> EditParameters? {
        guard let last = redoStack.popLast() else { return nil }
        undoStack.append(last)
        return last
    }
}
