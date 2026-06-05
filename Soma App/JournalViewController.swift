import UIKit

// structure for journal entry
struct JournalEntry: Codable, Identifiable {
    let id: UUID
    var date: Date
    var title: String
    var subtitle: String
    var body: String
}

// class for creating, saving, loading, deleting journal entry
final class JournalStore {
    static let shared = JournalStore()

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("journal_entries.json")
    }()

    private(set) var entries: [JournalEntry] = []

    private init() { load() }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) {
            entries = decoded
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Journal save error:", error)
        }
    }

    func add(title: String, subtitle: String, body: String) {
        let entry = JournalEntry(id: UUID(), date: Date(), title: title, subtitle: subtitle, body: body)
        entries.insert(entry, at: 0) // newest first
        save()
    }

    func delete(at index: Int) {
        guard entries.indices.contains(index) else { return }
        entries.remove(at: index)
        save()
    }
}

// journal view controller
final class JournalViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var backgroundImageView: UIImageView?
    @IBOutlet weak var textView: UITextView?

    private let store = JournalStore.shared

    private var tableView: UITableView!
    private var ctaButton: UIButton!

    // Compose overlay views (created on demand)
    private var overlay: UIView?
    private var card: UIView?
    private var titleField: UITextField?
    private var subtitleField: UITextField?
    private var bodyView: UITextView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Journal"

        setupBackground()
        hideOldTextViewIfAny()
        setupTable()
        addCreateButton()
        installAddNavButton()
        refreshEmptyState()
    }

    // journal background

    private func setupBackground() {
        if backgroundImageView == nil {
            let bg = UIImageView(image: UIImage(named: "bg_journal")) // pulls background image from assets
            bg.translatesAutoresizingMaskIntoConstraints = false
            bg.contentMode = .scaleAspectFill
            bg.clipsToBounds = true
            view.addSubview(bg)
            NSLayoutConstraint.activate([
                bg.topAnchor.constraint(equalTo: view.topAnchor),
                bg.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                bg.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                bg.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
            view.sendSubviewToBack(bg)
        } else {
            let bg = backgroundImageView!
            bg.translatesAutoresizingMaskIntoConstraints = false
            bg.contentMode = .scaleAspectFill
            bg.clipsToBounds = true
            NSLayoutConstraint.activate([
                bg.topAnchor.constraint(equalTo: view.topAnchor),
                bg.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                bg.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                bg.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
            view.sendSubviewToBack(bg)
        }
    }

    // creates table that holds new entries
    private func setupTable() {
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "EntryCell")

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Hide legacy text view

    private func hideOldTextViewIfAny() {
        textView?.isHidden = true
        textView?.isUserInteractionEnabled = false
    }

    // button for create new entry

    private func addCreateButton() {
        ctaButton = UIButton(type: .system)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false

        var cfg = UIButton.Configuration.filled()
        cfg.title = "Create New Entry"
        cfg.image = UIImage(systemName: "square.and.pencil")
        cfg.imagePadding = 8
        cfg.cornerStyle = .large
        cfg.baseBackgroundColor = .systemGray4
        cfg.baseForegroundColor = .black
        ctaButton.configuration = cfg

        ctaButton.addTarget(self, action: #selector(createTapped), for: .primaryActionTriggered)
        view.addSubview(ctaButton)

        NSLayoutConstraint.activate([
            ctaButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            ctaButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            ctaButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            ctaButton.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            ctaButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        ])
    }

    // creates new entry in nav bar, used when entries are already present
    private func installAddNavButton() {
        let item = UIBarButtonItem(title: "New Entry", style: .plain, target: self, action: #selector(createTapped))
        // Optional: bolder font for legibility
        item.setTitleTextAttributes([.font: UIFont.preferredFont(forTextStyle: .headline)], for: .normal)
        navigationItem.rightBarButtonItem = item
    }

    // hides create new entry button if entries are present, returns the button if entries are deleted/not present
    private func refreshEmptyState() {
        let isEmpty = store.entries.isEmpty
        ctaButton.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        tableView.reloadData()
    }
    // calls presentComposer to create new entry
    @objc private func createTapped() {
        presentComposer()
    }

    // to create new entry in journal
    private func presentComposer() {
        // Dim background
        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Card
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        overlay.addSubview(card)

        let maxWidth: CGFloat = min(view.bounds.width - 32, 560)
        let topPad: CGFloat = 24

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            card.topAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.topAnchor, constant: topPad),
            card.widthAnchor.constraint(equalToConstant: maxWidth),
            card.bottomAnchor.constraint(lessThanOrEqualTo: overlay.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])

        // Fields
        let titleField = UITextField()
        titleField.placeholder = "Title"
        styleField(titleField)

        let subtitleField = UITextField()
        subtitleField.placeholder = "Description"
        styleField(subtitleField)

        let bodyView = UITextView()
        bodyView.font = .preferredFont(forTextStyle: .body)
        bodyView.backgroundColor = .secondarySystemBackground
        bodyView.layer.cornerRadius = 12
        bodyView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        bodyView.heightAnchor.constraint(equalToConstant: 180).isActive = true

        // Buttons
        let save = UIButton(type: .system)
        var saveCfg = UIButton.Configuration.filled()
        saveCfg.title = "Save"
        saveCfg.cornerStyle = .large
        save.configuration = saveCfg

        let cancel = UIButton(type: .system)
        var cancelCfg = UIButton.Configuration.plain()
        cancelCfg.title = "Cancel"
        cancel.configuration = cancelCfg

        save.addTarget(self, action: #selector(saveEntry), for: .primaryActionTriggered)
        cancel.addTarget(self, action: #selector(cancelCompose), for: .primaryActionTriggered)

        // Stacks
        let buttonsRow = UIStackView(arrangedSubviews: [cancel, save])
        buttonsRow.axis = .horizontal
        buttonsRow.spacing = 12
        buttonsRow.distribution = .fillEqually

        let form = UIStackView(arrangedSubviews: [titleField, subtitleField, bodyView, buttonsRow])
        form.axis = .vertical
        form.spacing = 12
        form.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(form)
        NSLayoutConstraint.activate([
            form.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            form.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            form.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            form.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        // Tap outside to cancel (only when tapping outside the card)
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancelCompose))
        tap.delegate = self
        overlay.addGestureRecognizer(tap)

        // Keep refs
        self.overlay = overlay
        self.card = card
        self.titleField = titleField
        self.subtitleField = subtitleField
        self.bodyView = bodyView

        // Focus title
        titleField.becomeFirstResponder()

        // Small pop-in
        overlay.alpha = 0
        card.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        UIView.animate(withDuration: 0.2) {
            overlay.alpha = 1
            card.transform = .identity
        }
    }

    // style of text field for entry
    private func styleField(_ tf: UITextField) {
        tf.font = .preferredFont(forTextStyle: .body)
        tf.backgroundColor = .secondarySystemBackground
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        tf.leftViewMode = .always
        tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
        tf.clearButtonMode = .whileEditing
        tf.autocapitalizationType = .sentences
    }

    // save entry
    @objc private func saveEntry() {
        let title = titleField?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if title.isEmpty {
            // Minimal feedback: flash the title field border
            if let tf = titleField {
                tf.layer.borderColor = UIColor.systemRed.cgColor
                tf.layer.borderWidth = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    tf.layer.borderWidth = 0
                }
            }
            return
        }
        let subtitle = subtitleField?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let body = bodyView?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        store.add(title: title, subtitle: subtitle, body: body)
        dismissComposer()
        refreshEmptyState()
    }

    //calls dismiss composer to cancel entry
    @objc private func cancelCompose() {
        dismissComposer()
    }

    // close entry
    private func dismissComposer() {
        guard let overlay = overlay, let card = card else { return }
        UIView.animate(withDuration: 0.18, animations: {
            overlay.alpha = 0
            card.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }, completion: { _ in
            overlay.removeFromSuperview()
        })
        self.overlay = nil
        self.card = nil
        self.titleField = nil
        self.subtitleField = nil
        self.bodyView = nil
    }

    // Only cancel when tapping outside the card
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let overlay = overlay, let card = card else { return false }
        let point = touch.location(in: overlay)
        return !card.frame.contains(point)
    }

    // handles table as entries are added
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        store.entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EntryCell", for: indexPath)
        let item = store.entries[indexPath.row]

        // Content
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.secondaryText = item.subtitle.isEmpty
            ? DateFormatter.localizedString(from: item.date, dateStyle: .medium, timeStyle: .short)
            : item.subtitle
        content.textProperties.font = .preferredFont(forTextStyle: .headline)
        content.textProperties.color = .label
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content

        // Translucent "card" background (rounded + insets)
        var bg = UIBackgroundConfiguration.listCell()
        bg.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.55)
        bg.cornerRadius = 12
        bg.backgroundInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        cell.backgroundConfiguration = bg

        // Subtle highlight/selection keeping same shape
        cell.configurationUpdateHandler = { cell, state in
            var bg = UIBackgroundConfiguration.listCell()
            let alpha: CGFloat = (state.isHighlighted || state.isSelected) ? 0.70 : 0.55
            bg.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(alpha)
            bg.cornerRadius = 12
            bg.backgroundInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            cell.backgroundConfiguration = bg
        }

        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // Swipe to delete journal entries
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        store.delete(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        refreshEmptyState()
    }

    // Tap to view, shows entry as an alert
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = store.entries[indexPath.row]
        let body = item.body.isEmpty ? " " : item.body
        let message = (item.subtitle.isEmpty ? "" : "\(item.subtitle)\n\n") + body
        let a = UIAlertController(title: item.title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}
