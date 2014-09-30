//
//  ViewController.swift
//  SwifterDemoMac
//
//  Copyright (c) 2014 Matt Donnelly.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Cocoa
import Accounts
import SwifterMac

class ViewController: NSViewController {

    let useACAccount = true
                            
    override func viewDidLoad() {
        super.viewDidLoad()

        let failureHandler: ((NSError) -> Void) = {
            error in

            println(error.localizedDescription)
        }

        if useACAccount {
            let accountStore = ACAccountStore()
            let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)

            accountStore.requestAccessToAccountsWithType(accountType, options: nil) {
                granted, error in

                if granted {
                    let twitterAccounts = accountStore.accountsWithAccountType(accountType)

                    if (twitterAccounts != nil) {
                        if twitterAccounts.count == 0 {
                            println("There are no Twitter accounts configured. You can add or create a Twitter account in Settings.")
                        }
                        else {
                            let twitterAccount = twitterAccounts[0] as ACAccount

                            let swifter = Swifter(account: twitterAccount)

                            swifter.getStatusesHomeTimelineWithCount(20, sinceID: nil, maxID: nil, trimUser: true, contributorDetails: false, includeEntities: true, success: {
                                (statuses: [JSONValue]?) in

                                println(statuses)

                                },
                                failure: failureHandler)
                        }
                    }
                    else {
                        println("There are no Twitter accounts configured. You can add or create a Twitter account in Settings.")
                    }
                }
            }
        }
        else {
            let swifter = Swifter(consumerKey: "RErEmzj7ijDkJr60ayE2gjSHT", consumerSecret: "SbS0CHk11oJdALARa7NDik0nty4pXvAxdt7aj0R5y1gNzWaNEx")

            swifter.authorizeWithCallbackURL(NSURL(string: "swifter://success"), success: {
                accessToken, response in

                println("Successfully authorized")

                swifter.getStatusesHomeTimelineWithCount(20, sinceID: nil, maxID: nil, trimUser: true, contributorDetails: false, includeEntities: true, success: {
                    (statuses: [JSONValue]?) in

                    println(statuses)

                    },
                    failure: failureHandler)

                }, failure: failureHandler)
        }
    }

}

