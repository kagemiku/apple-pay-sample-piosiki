//
//  ApplePayViewController.swift
//  applepay-sample
//
//  Created by kagemiku on 2019/07/25.
//  Copyright © 2019 kagemiku. All rights reserved.
//

import UIKit
import PassKit
import Stripe

class ApplePayViewController: UIViewController {

    private static let merchantIdentifier = "merchant.com.kagemiku.piosiki"

    private var paymentNetworksToSupport: [PKPaymentNetwork] {
        return [
            .visa,
        ]
    }

    private lazy var paymentButton: PKPaymentButton = {
        let button = PKPaymentButton(paymentButtonType: .plain, paymentButtonStyle: .black)
        button.addTarget(self, action: #selector(ApplePayViewController.didPaymentButtonTap), for: .touchUpInside)

        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        createSubviews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !isApplePayAvailable() {
            paymentButton.isHidden = true
        } else if !isPaymentNetworksAvailable() {
            paymentButton.isHidden = true
            showApplePaySetupAlert()
        } else {
            paymentButton.isHidden = false
        }
    }

    private func createSubviews() {
        view.addSubview(paymentButton)
        paymentButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                paymentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                paymentButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ]
        )
    }

    private func isApplePayAvailable() -> Bool {
        return PKPaymentAuthorizationViewController.canMakePayments()
    }

    private func isPaymentNetworksAvailable() -> Bool {
        return PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworksToSupport)
    }

    private func showApplePaySetupAlert() {
        let alert = UIAlertController(
            title: "Avairable cards are not registered",
            message: "Do you register a new card?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
            PKPassLibrary().openPaymentSetup()
        })
        alert.addAction(UIAlertAction(title: "No", style: .cancel))

        present(alert, animated: true, completion: nil)
    }

    private func paymentSummaryItems() -> [PKPaymentSummaryItem] {
        let itemFee: NSDecimalNumber = 500
        let item = PKPaymentSummaryItem(label: "neko", amount: itemFee)

        let deliveryFee: NSDecimalNumber = 5
        let deliveryFeeItem = PKPaymentSummaryItem(label: "delivery fee", amount: deliveryFee)

        let totalFee = NSDecimalNumber(value: itemFee.intValue + deliveryFee.intValue)
        let totalItem = PKPaymentSummaryItem(label: "total", amount: totalFee)

        return [item, deliveryFeeItem, totalItem]
    }

    private func shippingMethods() -> [PKShippingMethod] {
        let shippingMethod = PKShippingMethod(label: "kuroneko", amount: 50)
        shippingMethod.identifier = "BlackCat"
        shippingMethod.detail = "So good shipping company"

        return [shippingMethod]
    }

    @objc
    func didPaymentButtonTap() {
        let paymentRequest = PKPaymentRequest()
        paymentRequest.currencyCode = "JPY"
        paymentRequest.countryCode = "JP"
        paymentRequest.merchantIdentifier = ApplePayViewController.merchantIdentifier
        paymentRequest.supportedNetworks = paymentNetworksToSupport
        paymentRequest.merchantCapabilities = PKMerchantCapability.capability3DS
        paymentRequest.paymentSummaryItems = paymentSummaryItems()
        paymentRequest.shippingMethods = shippingMethods()

        guard let paymentController = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) else { return }
        paymentController.delegate = self
        present(paymentController, animated: true, completion: nil)
    }

}

extension ApplePayViewController: PKPaymentAuthorizationViewControllerDelegate {

    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        print("payment: \(payment)")

        let finishWithStatus: (PKPaymentAuthorizationStatus) -> Void = { status in
            if controller.presentingViewController != nil {
                // Notify PKPaymentAuthorizationViewController
                completion(.init(status: status, errors: nil))
            } else {
                // PKPaymentAuthorizationViewController was dismissed
            }
        };

        STPAPIClient.shared().createPaymentMethod(with: payment) { (paymentMethod: STPPaymentMethod?, error: Error?) in
            guard error == nil else {
                print("Error: \(error!)")
                completion(.init(status: .failure, errors: [error!]))
                return
            }

            guard let paymentMethod = paymentMethod else {
                print("Error: paymentMethod is nil")
                completion(.init(status: .failure, errors: nil))
                return
            }

            let clientSecret = "secret_key"
            let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
            paymentIntentParams.paymentMethodId = paymentMethod.stripeId

            // Confirm the Payment Intent with the payment method
            STPPaymentHandler.shared().confirmPayment(paymentIntentParams, with: self) { (status, paymentIntent, error) in
                switch (status) {
                case .succeeded:
                    finishWithStatus(.success)
                case .canceled:
                    finishWithStatus(.failure)
                case .failed:
                    finishWithStatus(.failure)
                default:
                    fatalError()
                }
            }
        }
    }

    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didSelect shippingMethod: PKShippingMethod, handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void) {
        completion(.init(paymentSummaryItems: paymentSummaryItems()))
    }

    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didSelectShippingContact contact: PKContact, handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void) {
        completion(.init(errors: nil, paymentSummaryItems: paymentSummaryItems(), shippingMethods: shippingMethods()))
    }

}

extension ApplePayViewController: STPAuthenticationContext {

    func authenticationPresentingViewController() -> UIViewController {
        return self
    }

    func prepareAuthenticationContextForPresentation(completion: @escaping STPVoidBlock) {
        if presentedViewController != nil {
            dismiss(animated: true) {
                completion()
            }
        } else {
            completion()
        }
    }

}
