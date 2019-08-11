//
//  InAppPurchaseManager.swift
//  applepay-sample
//
//  Created by kagemiku on 2019/08/11.
//  Copyright © 2019 kagemiku. All rights reserved.
//

import Foundation
import StoreKit

class InAppPurchaseManager: NSObject {

    static let shared = InAppPurchaseManager()

    enum InAppPurchaseStatusKey: String {
        case start
        case finish

        var name: Notification.Name {
            return Notification.Name(self.rawValue)
        }
    }

    private override init() { }

    func requestPurchase() {
        let productIdentifiers: Set = ["neko"]
        let productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest.delegate = self
        productsRequest.start()

        NotificationCenter.default.post(name: InAppPurchaseStatusKey.start.name, object: nil)
    }

    func restore() {
        let request = SKReceiptRefreshRequest()
        request.delegate = self
        request.start()
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

}

extension InAppPurchaseManager: SKPaymentTransactionObserver {

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                print("purchasing")
            case .purchased:
                print("purchased")
                queue.finishTransaction(transaction)
                NotificationCenter.default.post(name: InAppPurchaseStatusKey.finish.name, object: nil)
            case .failed:
                print("failed")
                queue.finishTransaction(transaction)
                NotificationCenter.default.post(name: InAppPurchaseStatusKey.finish.name, object: nil)
            case .restored:
                print("resotred")
                queue.finishTransaction(transaction)
                NotificationCenter.default.post(name: InAppPurchaseStatusKey.finish.name, object: nil)
            case .deferred:
                print("deferred")
            @unknown default:
                fatalError()
            }
        }
    }

}

extension InAppPurchaseManager: SKProductsRequestDelegate {

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard response.invalidProductIdentifiers.count == 0 else {
            print("invalidProductIdentifiers.count is not 0: \(response.invalidProductIdentifiers)")
            return
        }

        for product in response.products {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        }
    }

}

extension InAppPurchaseManager: SKRequestDelegate {

    func requestDidFinish(_ request: SKRequest) {
        print("requestDidFinish: \(request)")
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("requestDidFail: \(request)")
        print("error: \(error)")
    }

}
