//
//  PaymentsViewController.swift
//  applepay-sample
//
//  Created by kagemiku on 2019/08/11.
//  Copyright © 2019 kagemiku. All rights reserved.
//

import UIKit

class PaymentsViewController: UIViewController {

    private lazy var inAppPurchaseViewController: InAppPurchaseViewController = {
        let vc = InAppPurchaseViewController()
        return vc
    }()

    private lazy var applePayViewController: ApplePayViewController = {
        let vc = ApplePayViewController()
        return vc
    }()

    @IBOutlet private weak var containerView: UIStackView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupChilds()
        setupNotifications()
    }

    private func setupChilds() {
        addChild(inAppPurchaseViewController)
        containerView.addArrangedSubview(inAppPurchaseViewController.view)
        inAppPurchaseViewController.didMove(toParent: self)

        addChild(applePayViewController)
        containerView.addArrangedSubview(applePayViewController.view)
        applePayViewController.didMove(toParent: self)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(forName: InAppPurchaseManager.InAppPurchaseStatusKey.start.name, object: nil, queue: .main) { [weak self] _ in
            self?.activityIndicator.startAnimating()
        }

        NotificationCenter.default.addObserver(forName: InAppPurchaseManager.InAppPurchaseStatusKey.finish.name, object: nil, queue: .main) { [weak self] _ in
            self?.activityIndicator.stopAnimating()
        }
    }

}
