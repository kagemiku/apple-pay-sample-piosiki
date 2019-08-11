//
//  PaymentsViewController.swift
//  applepay-sample
//
//  Created by kagemiku on 2019/08/11.
//  Copyright © 2019 kagemiku. All rights reserved.
//

import UIKit

class PaymentsViewController: UIViewController {

    private lazy var applePayViewController: ApplePayViewController = {
        let vc = ApplePayViewController()
        return vc
    }()

    @IBOutlet private weak var containerView: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(applePayViewController)
        containerView.addArrangedSubview(applePayViewController.view)
        applePayViewController.didMove(toParent: self)
    }

}
