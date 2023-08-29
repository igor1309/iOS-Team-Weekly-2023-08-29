//
//  CvvPinServiceTests.swift
//  
//
//  Created by Igor Malyarov on 29.08.2023.
//

import XCTest

protocol GetProcessingSessionCodeService {
    
    func get(completion: @escaping (Result<ProcessingSessionCode, Error>) -> Void)
}

struct ProcessingSessionCode {}

protocol ExchangeKeyService {
    
    func exchange(_ code: ProcessingSessionCode, completion: @escaping (Result<KeyExchange, Error>) -> Void)
}

struct KeyExchange {}

protocol ConfirmExchangeService {}

struct OTP {}

final class CvvPinService {
    
    private let getProcessingSessionCodeService: GetProcessingSessionCodeService
    private let exchangeKeyService: ExchangeKeyService
    private let confirmExchangeService: ConfirmExchangeService
    
    init(
        getProcessingSessionCodeService: GetProcessingSessionCodeService,
        exchangeKeyService: ExchangeKeyService,
        confirmExchangeService: ConfirmExchangeService
    ) {
        self.getProcessingSessionCodeService = getProcessingSessionCodeService
        self.exchangeKeyService = exchangeKeyService
        self.confirmExchangeService = confirmExchangeService
    }
    
    typealias ExchangeKeyCompletion = (Result<KeyExchange, Error>) -> Void
    
    func exchangeKey(completion: @escaping ExchangeKeyCompletion) {
        
        getProcessingSessionCodeService.get { [unowned self] result in
         
            switch result {
            case let .failure(error):
                completion(.failure(error))
                
            case let .success(code):
                exchangeKeyService.exchange(code) { result in
                    
                    switch result {
                    case let .failure(error):
                        completion(.failure(error))
                        
                    case let .success(keyExchange):
                        completion(.success(keyExchange))
                    }
                }
            }
        }
    }
    
    typealias ConfirmExchangeCompletion = () -> Void
    
    func confirmExchange(withOTP: OTP, completion: ConfirmExchangeCompletion) {}
}

final class CvvPinServiceTests: XCTestCase {
    
    func test() {
        
        // XCTFail()
    }
}
