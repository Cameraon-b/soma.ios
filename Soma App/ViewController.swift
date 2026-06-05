import UIKit

final class ViewController: UIViewController {

    // MARK: - Outlets (connected from storyboard)
    @IBOutlet weak var backgroundImageView: UIImageView?
    @IBOutlet weak var bottomStack: UIStackView!
    @IBOutlet weak var meditateButton: UIButton!
    @IBOutlet weak var breathingButton: UIButton!
    @IBOutlet weak var journalButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var quoteImageView: UIImageView!
    @IBOutlet weak var quoteLabel: UILabel!

    // MARK: - Private UI
    private var bottomBar: UIView!               // container for bottom stack
    private let barHeight: CGFloat = 64          // fixed bar height
    private var signInButton: UIButton!          // top-right sign in

    // background offsets for orientation
    private let backgroundYOffset: CGFloat = 0
    private let landscapeBackgroundYOffset: CGFloat = 80
    private var bgTopC: NSLayoutConstraint?
    private var bgBottomC: NSLayoutConstraint?

    private var quoteConstraints: [NSLayoutConstraint] = []

    // gradient overlay at top of bg
    private let topGradient = CAGradientLayer()

    // landscape positioning constants
    private let landscapeShiftY: CGFloat = 210
    private let landscapeBleedY: CGFloat = 250

    // MARK: - Convenience
    private var isPhoneLandscape: Bool {
        traitCollection.userInterfaceIdiom == .phone && view.bounds.width > view.bounds.height
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        repinBackgroundIfNeeded()      // pin bg image with custom constraints
        updateBackgroundForOrientation()

        setupBottomBar()
        styleStack()
        styleButtons()
        layoutQuoteImage()
        setupSignInButton()
        addTopGradientOverlay()

        // button tap handlers
        [meditateButton, breathingButton, journalButton, settingsButton].forEach {
            $0?.addTarget(self, action: #selector(menuTapped(_:)), for: .touchUpInside)
        }

        // fade-in for quote (portrait only)
        quoteImageView?.alpha = 0
        quoteLabel?.alpha = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self, !self.isPhoneLandscape else { return }
            UIView.animate(withDuration: 0.6) {
                self.quoteImageView?.alpha = 1
                self.quoteLabel?.alpha = 1
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTopGradientFrame()      // resize gradient overlay
        updateBackgroundForOrientation()
        updateQuoteVisibility()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // update layout on rotation
        coordinator.animate(alongsideTransition: { _ in
            self.layoutQuoteImage()
            self.updateBackgroundForOrientation()
            self.updateQuoteVisibility()
            self.view.layoutIfNeeded()
        })
    }

    // MARK: - Quote layout
    private func layoutQuoteImage() {
        guard let qi = quoteImageView else { return }
        qi.translatesAutoresizingMaskIntoConstraints = false
        qi.contentMode = .scaleAspectFit

        NSLayoutConstraint.deactivate(quoteConstraints)

        // margins + dynamic height
        let side: CGFloat = 24
        let topPad: CGFloat = (traitCollection.horizontalSizeClass == .compact) ? 250 : 300
        let bottomPad: CGFloat = 16

        var cs: [NSLayoutConstraint] = [
            qi.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: side),
            qi.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -side),
            qi.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topPad),
            qi.bottomAnchor.constraint(lessThanOrEqualTo: bottomBar.topAnchor, constant: -bottomPad)
        ]

        // maintain image aspect ratio if available
        if let img = qi.image, img.size.width > 0 {
            let ratio = img.size.height / img.size.width
            cs.append(qi.heightAnchor.constraint(equalTo: qi.widthAnchor, multiplier: ratio))
        }

        // minimum + max heights
        let minH: CGFloat = (traitCollection.horizontalSizeClass == .compact) ? 220 : 280
        let minHC = qi.heightAnchor.constraint(greaterThanOrEqualToConstant: minH)
        minHC.priority = .defaultHigh
        cs.append(minHC)
        cs.append(qi.heightAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.55))

        NSLayoutConstraint.activate(cs)
        quoteConstraints = cs
    }

    private func updateQuoteVisibility() {
        let hide = isPhoneLandscape
        quoteImageView?.isHidden = hide
        quoteLabel?.isHidden = hide
    }

    // MARK: - Background
    private func repinBackgroundIfNeeded() {
        guard let bg = backgroundImageView else { return }

        // remove old constraints
        var toDeactivate: [NSLayoutConstraint] = []
        for c in view.constraints {
            let first = c.firstItem as AnyObject?
            let second = c.secondItem as AnyObject?
            if (first === bg) || (second === bg) { toDeactivate.append(c) }
        }
        NSLayoutConstraint.deactivate(toDeactivate)
        NSLayoutConstraint.deactivate(bg.constraints)

        // new fill constraints
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.contentMode = .scaleAspectFill
        bg.clipsToBounds = true

        let top = bg.topAnchor.constraint(equalTo: view.topAnchor, constant: backgroundYOffset)
        let bottom = bg.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: backgroundYOffset)
        let leading = bg.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let trailing = bg.trailingAnchor.constraint(equalTo: view.trailingAnchor)

        NSLayoutConstraint.activate([top, bottom, leading, trailing])
        bgTopC = top
        bgBottomC = bottom

        view.sendSubviewToBack(bg)
    }

    private func updateBackgroundForOrientation() {
        guard let bgTopC, let bgBottomC else { return }
        if isPhoneLandscape {
            // shift + bleed for landscape
            bgTopC.constant = -landscapeBleedY + landscapeShiftY
            bgBottomC.constant = landscapeBleedY + landscapeShiftY
        } else {
            bgTopC.constant = backgroundYOffset
            bgBottomC.constant = backgroundYOffset
        }
    }

    // MARK: - Bottom bar
    private func setupBottomBar() {
        bottomBar = UIView()
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBar)

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: barHeight)
        ])

        // move stack into bottomBar if not already
        if bottomStack.superview !== bottomBar {
            bottomStack.removeFromSuperview()
            bottomStack.translatesAutoresizingMaskIntoConstraints = false
            bottomBar.addSubview(bottomStack)
        }

        NSLayoutConstraint.activate([
            bottomStack.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            bottomStack.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor),
            bottomStack.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            bottomStack.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor)
        ])
    }

    private func styleStack() {
        bottomStack.axis = .horizontal
        bottomStack.distribution = .fillEqually
        bottomStack.alignment = .fill
        bottomStack.spacing = 0
    }

    // MARK: - Button style
    private func styleButtons() {
        let buttons = [meditateButton, breathingButton, journalButton, settingsButton]
        let titles  = ["Meditate", "Breath", "Journal", "Settings"]
        let symbols = ["figure.mind.and.body", "leaf.fill", "book.closed.fill", "gearshape.fill"]

        // assign title + SF Symbol for each button
        for (btn, pair) in zip(buttons, zip(titles, symbols)) {
            guard let b = btn else { continue }
            var cfg = UIButton.Configuration.plain()
            cfg.title = pair.0
            cfg.image = UIImage(systemName: pair.1)
            cfg.imagePlacement = .top
            cfg.imagePadding = 4
            cfg.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
            cfg.baseForegroundColor = .systemGray
            cfg.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
            b.configuration = cfg
        }
    }

    // MARK: - Actions / Navigation
    @IBAction func menuTapped(_ sender: UIButton) {
        if sender === meditateButton {
            push("MeditationsVC", as: MeditationsViewController.self)
        } else if sender === breathingButton {
            push("BreathingVC", as: BreathingViewController.self)
        } else if sender === journalButton {
            push("JournalVC", as: JournalViewController.self)
        } else if sender === settingsButton {
            push("SettingsVC", as: SettingsViewController.self)
        }
    }

    // helper: push or present a storyboard VC by ID
    private func push<T: UIViewController>(_ id: String, as type: T.Type) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: id) as? T else {
            assertionFailure("Storyboard ID \(id) not found or wrong class")
            return
        }
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            present(vc, animated: true)
        }
    }

    // MARK: - Sign In
    private func setupSignInButton() {
        signInButton = UIButton(type: .system)

        // config with icon + text
        var cfg = UIButton.Configuration.plain()
        cfg.baseForegroundColor = .systemGray
        cfg.title = "Sign In"
        cfg.image = UIImage(systemName: "person.crop.circle")
        cfg.imagePadding = 6
        cfg.cornerStyle = .large
        signInButton.configuration = cfg

        signInButton.addTarget(self, action: #selector(showAuthMenu(_:)), for: .touchUpInside)
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(signInButton)
        view.bringSubviewToFront(signInButton)

        NSLayoutConstraint.activate([
            signInButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            signInButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
    }

    // action sheet with login/signup
    @objc private func showAuthMenu(_ sender: UIView) {
        let sheet = UIAlertController(title: "Account", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Log In", style: .default) { _ in self.showLoginForm() })
        sheet.addAction(UIAlertAction(title: "Sign Up", style: .default) { _ in self.showSignupForm() })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }
        present(sheet, animated: true)
    }

    // simple login alert
    private func showLoginForm() {
        let a = UIAlertController(title: "Log In", message: nil, preferredStyle: .alert)
        a.addTextField { tf in
            tf.placeholder = "Email"; tf.keyboardType = .emailAddress; tf.autocapitalizationType = .none
        }
        a.addTextField { tf in
            tf.placeholder = "Password"; tf.isSecureTextEntry = true
        }
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        a.addAction(UIAlertAction(title: "Log In", style: .default) { _ in
            let email = a.textFields?[0].text ?? ""
            let pass  = a.textFields?[1].text ?? ""
            print("Log In ->", email, pass)
        })
        present(a, animated: true)
    }

    // simple signup alert
    private func showSignupForm() {
        let a = UIAlertController(title: "Sign Up", message: nil, preferredStyle: .alert)
        a.addTextField { tf in
            tf.placeholder = "Email"; tf.keyboardType = .emailAddress; tf.autocapitalizationType = .none
        }
        a.addTextField { tf in
            tf.placeholder = "Password"; tf.isSecureTextEntry = true
        }
        a.addTextField { tf in
            tf.placeholder = "Confirm Password"; tf.isSecureTextEntry = true
        }
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        a.addAction(UIAlertAction(title: "Create Account", style: .default) { _ in
            let email   = a.textFields?[0].text ?? ""
            let pass    = a.textFields?[1].text ?? ""
            let confirm = a.textFields?[2].text ?? ""
            print("Sign Up ->", email, pass, confirm)
        })
        present(a, animated: true)
    }

    // MARK: - Top gradient
    private func addTopGradientOverlay() {
        guard let bg = backgroundImageView else { return }

        // black-to-clear fade at top of background
        topGradient.colors = [
            UIColor.black.withAlphaComponent(0.8).cgColor,
            UIColor.clear.cgColor
        ]
        topGradient.locations = [0.0, 1.0]
        topGradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        topGradient.endPoint   = CGPoint(x: 0.5, y: 1.0)

        if topGradient.superlayer == nil {
            bg.layer.addSublayer(topGradient)
        }
        updateTopGradientFrame()
    }

    private func updateTopGradientFrame() {
        guard let bg = backgroundImageView else { return }
        let h: CGFloat = 150
        topGradient.frame = CGRect(x: 0, y: 0, width: bg.bounds.width, height: min(h, bg.bounds.height))
        topGradient.contentsScale = view.window?.screen.scale ?? UIScreen.main.scale
    }
}
