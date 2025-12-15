//
//  WaitView.swift
//  Seven Hand Poker
//
//  Converted to Swift from WaitView.h/m
//

import UIKit

class WaitView: UIView {
    // MARK: - Properties

    private var indicator: UIActivityIndicatorView!
    private var textLabel: UILabel!

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        self.frame = CGRect(x: 0, y: 0, width: 480, height: 320)

        indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.center = self.center

        textLabel = UILabel(frame: CGRect(x: 180, y: 100, width: 160, height: 40))
        textLabel.font = UIFont(name: "Helvetica", size: 20)
        textLabel.textColor = .white
        textLabel.text = "Start Matching"
        textLabel.backgroundColor = .clear

        backgroundColor = UIColor(white: 0.2, alpha: 0.5)

        addSubview(indicator)
        addSubview(textLabel)
        startAnimating()
    }

    // MARK: - Animation Control

    func startAnimating() {
        isHidden = false
        indicator.startAnimating()
    }

    func stopAnimating() {
        isHidden = true
        indicator.stopAnimating()
    }
}
