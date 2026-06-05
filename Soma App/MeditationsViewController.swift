import UIKit
import AVFoundation

final class MeditationsViewController: UITableViewController {

    // creates each cell in table
    private struct Session {
        let title: String
        let subtitle: String
        let file: String   // audio file (without extension)
    }

    // initializes each cell in table
    private let sessions: [Session] = [
        .init(title: "5 min Relax",  subtitle: "Quick body scan to settle the mind", file: "meditation_5min"),
        .init(title: "10 min Focus", subtitle: "Breath-counting for attention",      file: "meditation_10min"),
        .init(title: "20 min Sitting", subtitle: "Concentrating on the breath",     file: "meditation_20min")
    ]

    // audio player UI
    private var player: AVAudioPlayer?
    private var playerTimer: Timer?

    // Overlay UI
    private var overlay: UIView?
    private var card: UIView?
    private var titleLabel: UILabel?
    private var subtitleLabel: UILabel?
    private var playPauseButton: UIButton?
    private var stopButton: UIButton?
    private var slider: UISlider?
    private var timeLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Meditations"

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SessionCell")
        tableView.tableFooterView = UIView()

        if tableView.backgroundView == nil {
            let bg = UIImageView(image: UIImage(named: "bg_meditations"))
            bg.contentMode = .scaleAspectFill
            bg.clipsToBounds = true
            tableView.backgroundView = bg
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.backgroundView?.frame = tableView.bounds
    }

    // creates table
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sessions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SessionCell", for: indexPath)
        let item = sessions[indexPath.row]

        // handes the cells
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.secondaryText = item.subtitle
        content.textProperties.font = .preferredFont(forTextStyle: .headline)
        content.textProperties.color = .label
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content

        //handles the background of table view
        var bg = UIBackgroundConfiguration.listCell()
        bg.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.55)
        bg.cornerRadius = 12
        bg.backgroundInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        cell.backgroundConfiguration = bg

        //handles cell selection
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sessions[indexPath.row]
        presentPlayer(for: item)
    }

    // loads audio player when cell is selected
    private func presentPlayer(for sess: Session) {
        // 1) Dim overlay
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

        // Tap outside to close
        overlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissPlayer)))

        // 2) Card
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        overlay.addSubview(card)

        // updated constraints: bottom anchor + top minimum + max height
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            // keep a visible margin at the top so it never gets cut off
            card.topAnchor.constraint(greaterThanOrEqualTo: overlay.safeAreaLayoutGuide.topAnchor, constant: 80),

            // cap height so it never grows too tall (tweak 0.45–0.55 to taste)
            card.heightAnchor.constraint(lessThanOrEqualTo: overlay.safeAreaLayoutGuide.heightAnchor, multiplier: 0.50)
        ])


        // Audio player controls
        // title
        let title = UILabel()
        title.text = sess.title
        title.font = .preferredFont(forTextStyle: .title2)

        // subtitles
        let sub = UILabel()
        sub.text = sess.subtitle
        sub.textColor = .secondaryLabel
        sub.font = .preferredFont(forTextStyle: .subheadline)
        sub.numberOfLines = 2

        //play/pause button
        let playPause = UIButton(type: .system)
        var playCfg = UIButton.Configuration.filled()
        playCfg.title = "Play"
        playCfg.image = UIImage(systemName: "play.fill")
        playCfg.imagePadding = 6
        playCfg.cornerStyle = .large
        playPause.configuration = playCfg
        playPause.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)

        // stop button
        let stop = UIButton(type: .system)
        var stopCfg = UIButton.Configuration.plain()
        stopCfg.title = "Stop"
        stopCfg.image = UIImage(systemName: "stop.fill")
        stopCfg.imagePadding = 6
        stop.configuration = stopCfg
        stop.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)

        // slider
        let slider = UISlider()
        slider.minimumValue = 0
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)

        // shows audio play time/total time
        let time = UILabel()
        time.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        time.textColor = .secondaryLabel
        time.text = "0:00 / 0:00"

        // shows close button
        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        close.addTarget(self, action: #selector(dismissPlayer), for: .touchUpInside)

        // Layout stacks
        // title and sub first line
        let header = UIStackView(arrangedSubviews: [title, sub])
        header.axis = .vertical
        header.spacing = 2

        // play/pause/stop/close second line
        let buttons = UIStackView(arrangedSubviews: [playPause, stop, close])
        buttons.axis = .horizontal
        buttons.spacing = 12
        buttons.distribution = .fillEqually

        // slider/play time/total time third line
        let bottomRow = UIStackView(arrangedSubviews: [slider, time])
        bottomRow.axis = .horizontal
        bottomRow.spacing = 8
        time.setContentHuggingPriority(.required, for: .horizontal)

        // handles layout + constraints
        let vstack = UIStackView(arrangedSubviews: [header, buttons, bottomRow])
        vstack.axis = .vertical
        vstack.spacing = 12
        vstack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(vstack)
        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            vstack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            vstack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            vstack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        // Save refs for later updates
        self.overlay = overlay
        self.card = card
        self.titleLabel = title
        self.subtitleLabel = sub
        self.playPauseButton = playPause
        self.stopButton = stop
        self.slider = slider
        self.timeLabel = time

        // 4) Prepare audio
        prepareAudio(for: sess.file)

        // Nice entrance
        overlay.alpha = 0
        card.transform = CGAffineTransform(translationX: 0, y: 30)
        UIView.animate(withDuration: 0.2) {
            overlay.alpha = 1
            card.transform = .identity
        }
    }

    //close audio player
    @objc private func dismissPlayer() {
        player?.stop()
        player = nil
        playerTimer?.invalidate()
        playerTimer = nil

        guard let overlay = overlay, let card = card else { return }
        UIView.animate(withDuration: 0.18, animations: {
            overlay.alpha = 0
            card.transform = CGAffineTransform(translationX: 0, y: 20)
        }, completion: { _ in
            overlay.removeFromSuperview()
        })
        self.overlay = nil
        self.card = nil
        self.playPauseButton = nil
        self.stopButton = nil
        self.slider = nil
        self.timeLabel = nil
    }

    // loads audio file
    private func prepareAudio(for file: String) {
        guard let url = Bundle.main.url(forResource: file, withExtension: "mp3") else {
            timeLabel?.text = "Audio not found"
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()

            slider?.maximumValue = Float(player?.duration ?? 0)
            updateTimeLabel()
            updatePlayPauseButton(isPlaying: false)
        } catch {
            timeLabel?.text = "Audio error"
            print("Audio error:", error)
        }
    }

    // pauses audio
    @objc private func playPauseTapped() {
        guard let p = player else { return }
        if p.isPlaying {
            p.pause()
            stopTimer()
            updatePlayPauseButton(isPlaying: false)
        } else {
            p.play()
            startTimer()
            updatePlayPauseButton(isPlaying: true)
        }
    }

    // stops audio
    @objc private func stopTapped() {
        guard let p = player else { return }
        p.stop()
        p.currentTime = 0
        stopTimer()
        slider?.value = 0
        updateTimeLabel()
        updatePlayPauseButton(isPlaying: false)
    }

    // handles changes on slider, jumps to interval selected
    @objc private func sliderChanged(_ s: UISlider) {
        player?.currentTime = TimeInterval(s.value)
        updateTimeLabel()
    }

    // starts timer upon playing of audio
    private func startTimer() {
        stopTimer()
        playerTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self = self, let p = self.player else { return }
            self.slider?.value = Float(p.currentTime)
            self.updateTimeLabel()
        }
        RunLoop.main.add(playerTimer!, forMode: .common)
    }

    // stops timer upon stopping of audio
    private func stopTimer() {
        playerTimer?.invalidate()
        playerTimer = nil
    }

    // updates the time as audio plays
    private func updateTimeLabel() {
        guard let p = player else { return }
        timeLabel?.text = "\(fmt(p.currentTime)) / \(fmt(p.duration))"
    }

    // changes play/pause button depending on button tapped
    private func updatePlayPauseButton(isPlaying: Bool) {
        guard let btn = playPauseButton else { return }
        var cfg = btn.configuration ?? .filled()
        if isPlaying {
            cfg.title = "Pause"
            cfg.image = UIImage(systemName: "pause.fill")
        } else {
            cfg.title = "Play"
            cfg.image = UIImage(systemName: "play.fill")
        }
        btn.configuration = cfg
    }

    // formats time interval
    private func fmt(_ t: TimeInterval) -> String {
        let total = Int(round(t))
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
