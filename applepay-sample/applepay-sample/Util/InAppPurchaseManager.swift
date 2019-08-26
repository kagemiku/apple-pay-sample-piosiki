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

    enum ReceiptErrorStatus: Int {
        case invalidJSON                    = 21000
        case invalidReceiptDataProperty     = 21002
        case unauthenticableReceipt         = 21003
        case mismatchedSharedSecret         = 21004
        case unavairableReceiptServer       = 21005
        case expiredSubscription            = 21006
        case invalidReceiptForProduction    = 21007
        case invalidReceiptForTest          = 21008
        case unacceptableReceipt            = 21010
        case internalDataAccess             = 21100
    }

    private override init() { }

    func requestPurchase() {
        let productIdentifiers: Set = ["inu"]
        let productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest.delegate = self
        productsRequest.start()

        NotificationCenter.default.post(name: InAppPurchaseStatusKey.start.name, object: nil)
    }

    func restorePurchase() {
        let request = SKReceiptRefreshRequest()
        request.delegate = self
        request.start()
        SKPaymentQueue.default().restoreCompletedTransactions()

        NotificationCenter.default.post(name: InAppPurchaseStatusKey.start.name, object: nil)
    }

    private func validateReceipt(url: String) {
        let receiptUrl = Bundle.main.appStoreReceiptURL
        let receiptData = try! Data(contentsOf: receiptUrl!)

        let requestContents = [
            "receipt-data": receiptData.base64EncodedString(options: .endLineWithCarriageReturn),
            "password": "password",
        ]
        let requestData = try! JSONSerialization.data(withJSONObject: requestContents, options: .init(rawValue: 0))

        var request = URLRequest(url: URL(string: url)!)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"content-type")
        request.timeoutInterval = 5.0
        request.httpMethod = "POST"
        request.httpBody = requestData

        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            guard error == nil else {
                print("Error: \(error!)")
                return
            }
            guard let jsonData = data else { return }

            do {
                let json = try JSONSerialization.jsonObject(with: jsonData, options: .init(rawValue: 0)) as! [String: AnyObject]

                let status = json["status"] as! Int
                if status == ReceiptErrorStatus.invalidReceiptForProduction.rawValue {
                    self.validateReceipt(url: "https://sandbox.itunes.apple.com/verifyReceipt")
                }

                guard let receipts = json["receipt"] as? [String: AnyObject] else { return }

                // verify receipt
            } catch let error {
                print("Error in validateReceipt: \(error)")
            }
        })
        task.resume()
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
                validateReceipt(url: "https://buy.itunes.apple.com/verifyReceipt")
                queue.finishTransaction(transaction)
                NotificationCenter.default.post(name: InAppPurchaseStatusKey.finish.name, object: nil)
            case .failed:
                print("failed")
                queue.finishTransaction(transaction)
                NotificationCenter.default.post(name: InAppPurchaseStatusKey.finish.name, object: nil)
            case .restored:
                print("resotred")
                queue.finishTransaction(transaction)
                validateReceipt(url: "https://buy.itunes.apple.com/verifyReceipt")
                NotificationCenter.default.post(name: InAppPurchaseStatusKey.finish.name, object: nil)
            case .deferred:
                print("deferred")
            @unknown default:
                fatalError()
            }
        }
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("Queue: \(queue)")
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("Queue: \(queue), error: \(error)")
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
