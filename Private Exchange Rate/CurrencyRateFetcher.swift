//
//  CurrencyRateFetcher.swift
//  Private Exchange Rate
//
//  Created by Dmitriy Portenko on 08.05.2023.
//

import Foundation
import Alamofire

class CurrencyRateFetcher {
    static let shared = CurrencyRateFetcher()
    private init() {}

    func fetchRates(completion: @escaping ([CurrencyRate]?) -> Void) {
        let url = "https://api.privatbank.ua/p24api/pubinfo?exchange&coursid=5"
        
        AF.request(url).validate().responseDecodable(of: [CurrencyRate].self) { response in
            switch response.result {
            case .success(let rates):
                completion(rates)
            case .failure(_):
                completion(nil)
            }
        }
    }
}
