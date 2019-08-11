//
//  InAppPurchaseViewController.swift
//  applepay-sample
//
//  Created by kagemiku on 2019/08/11.
//  Copyright © 2019 kagemiku. All rights reserved.
//

import UIKit

class InAppPurchaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func didTapInAppPurchaseButton(_ sender: Any) {
        InAppPurchaseManager.shared.requestPurchase()
    }

}
