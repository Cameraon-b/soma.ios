import UIKit

final class BreathingViewController: UITableViewController {

    // Represents one breathing pattern row
    private struct Pattern {
        let title: String
        let subtitle: String
        let description: String
    }

    // Data for the table (static for now)
    private let patterns: [Pattern] = [
        .init(
            title: "Box (4–4–4–4)",
            subtitle: "Inhale 4 · Hold 4 · Exhale 4 · Hold 4",
            description: "A balanced practice that calms the nervous system. \n\n“Balance is not something you find, it is something you create.” — Unknown"
        ),
        .init(
            title: "4–7–8",
            subtitle: "Inhale 4 · Hold 7 · Exhale 8",
            description: "Known as the ‘relaxing breath,’ this helps ease anxiety and prepare for sleep. \n\n“Breathe in deeply to bring your mind home to your body.” — Thích Nhất Hạnh"
        ),
        .init(
            title: "Resonant (5:5)",
            subtitle: "Inhale 5 · Exhale 5 (~6/min)",
            description: "Creates heart–brain coherence, bringing peace and clarity. \n\n“The rhythm of the body, the melody of the mind, and the harmony of the soul create the symphony of life.” — B.K.S. Iyengar"
        ),
        .init(
            title: "Extended Exhale (4–6)",
            subtitle: "Inhale 4 · Exhale 6",
            description: "Lengthening the exhale triggers relaxation and release. \n\n“Let go of your attachment to being right, and suddenly your mind is more open.” — Ralph Marston"
        ),
        .init(
            title: "Cyclic Sigh",
            subtitle: "2 short inhales · 1 long exhale",
            description: "A powerful reset for stress, shown to quickly restore balance. \n\n“Within you there is a stillness and a sanctuary to which you can retreat at any time.” — Hermann Hesse"
        )
    ]

    private static let reuseID = "BreathCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Breathing"

        // Table style
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.reuseID)

        // Background image (fills table; resized in viewDidLayoutSubviews)
        let bg = UIImageView(image: UIImage(named: "bg_breathing")) //pulls breathing background image from assets
        bg.contentMode = .scaleAspectFill
        bg.clipsToBounds = true
        tableView.backgroundView = bg
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure the background covers the whole table on rotations/size changes
        tableView.backgroundView?.frame = tableView.bounds
    }

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        patterns.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue a basic cell and configure its content
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.reuseID, for: indexPath)
        let item = patterns[indexPath.row]

        // Primary + secondary text
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.secondaryText = item.subtitle
        content.textProperties.font = .preferredFont(forTextStyle: .headline)
        content.textProperties.color = .label
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content

        // Translucent rounded "card" background
        var bg = UIBackgroundConfiguration.listCell()
        bg.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.55)
        bg.cornerRadius = 12
        bg.backgroundInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        cell.backgroundConfiguration = bg

        // Adjust background alpha on highlight/selection for nice feedback
        cell.configurationUpdateHandler = { cell, state in
            var bg = UIBackgroundConfiguration.listCell()
            let alpha: CGFloat = (state.isHighlighted || state.isSelected) ? 0.90 : 0.75
            bg.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(alpha)
            bg.cornerRadius = 12
            bg.backgroundInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            cell.backgroundConfiguration = bg
        }

        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Tap -> show the full description in an alert
        tableView.deselectRow(at: indexPath, animated: true)
        let item = patterns[indexPath.row]

        let alert = UIAlertController(
            title: item.title,
            message: "\(item.subtitle)\n\n\(item.description)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        present(alert, animated: true)
    }
}
