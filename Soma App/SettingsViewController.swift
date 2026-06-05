import UIKit

final class SettingsViewController: UITableViewController {

    private enum Row: Int { case haptics = 0, sounds = 1, darkMode = 2 }

    // creates new settings row
    private struct Keys {
        static let haptics          = "haptics"
        static let sounds           = "sounds"
        static let darkModeOverride = "darkModeOverride"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"

        //background
        tableView.backgroundColor = .clear
        if tableView.backgroundView == nil {
            let bg = UIImageView(image: UIImage(named: "bg_settings"))// pulls background imagre from assets
            bg.contentMode = .scaleAspectFill
            bg.clipsToBounds = true
            tableView.backgroundView = bg
        }
    }

    // changes system to dark mode(tables and some text)
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyAppearanceOverride(UserDefaults.standard.bool(forKey: Keys.darkModeOverride))
    }

    // handles table in settings
    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        cell.selectionStyle = .none

        // Simple flat background for settings "tray"
        var bg = UIBackgroundConfiguration.listCell()
        bg.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.75)
        bg.backgroundInsets = .zero
        bg.cornerRadius = 0
        cell.backgroundConfiguration = bg

        // handles cell selection, changes for feedback
        cell.configurationUpdateHandler = { cell, state in
            var bg = UIBackgroundConfiguration.listCell()
            let alpha: CGFloat = (state.isHighlighted || state.isSelected) ? 0.70 : 0.75
            bg.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(alpha)
            bg.backgroundInsets = .zero
            bg.cornerRadius = 0
            cell.backgroundConfiguration = bg
        }

        // Labels
        cell.textLabel?.textColor = .label
        cell.detailTextLabel?.textColor = .secondaryLabel

        // Switch setup
        switch Row(rawValue: indexPath.row) {
        case .haptics:
            cell.textLabel?.text = "Haptics"
            attachSwitchIfNeeded(to: cell,
                                 isOn: UserDefaults.standard.bool(forKey: Keys.haptics),
                                 action: #selector(hapticsChanged(_:)))
        case .sounds:
            cell.textLabel?.text = "UI Sounds"
            attachSwitchIfNeeded(to: cell,
                                 isOn: UserDefaults.standard.bool(forKey: Keys.sounds),
                                 action: #selector(soundsChanged(_:)))
        case .darkMode:
            cell.textLabel?.text = "Dark Mode"
            attachSwitchIfNeeded(to: cell,
                                 isOn: UserDefaults.standard.bool(forKey: Keys.darkModeOverride),
                                 action: #selector(darkModeChanged(_:)))
        case .none:
            break
        }
    }




    // adds the switch in code vs storyboard
    private func attachSwitchIfNeeded(to cell: UITableViewCell, isOn: Bool, action: Selector) {
        if let sw = cell.accessoryView as? UISwitch {
            if sw.isOn != isOn { sw.isOn = isOn }
        } else {
            let sw = UISwitch()
            sw.isOn = isOn
            sw.addTarget(self, action: action, for: .valueChanged)
            cell.accessoryView = sw
        }
    }

    //updates haptics switch
    @objc private func hapticsChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: Keys.haptics)
    }

    //updates sounds switch
    @objc private func soundsChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: Keys.sounds)
    }

    //updates dark mode switch
    @objc private func darkModeChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: Keys.darkModeOverride)
        applyAppearanceOverride(sender.isOn)
    }

    // dark mode across app
    private func applyAppearanceOverride(_ enabled: Bool) {
        let style: UIUserInterfaceStyle = enabled ? .dark : .unspecified
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}
