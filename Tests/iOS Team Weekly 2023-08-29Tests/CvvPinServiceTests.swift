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
        
        let (sut, getProcessingSessionCodeServiceSpy, exchangeKeyServiceSpy, confirmExchangeServiceSpy) = makeSUT()
        
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> (
        sut: CvvPinService,
        getProcessingSessionCodeServiceSpy: GetProcessingSessionCodeServiceSpy,
        exchangeKeyServiceSpy: ExchangeKeyServiceSpy,
        confirmExchangeServiceSpy: ConfirmExchangeServiceSpy
    ) {
        
        let getProcessingSessionCodeServiceSpy = GetProcessingSessionCodeServiceSpy()
        let exchangeKeyServiceSpy = ExchangeKeyServiceSpy()
        let confirmExchangeServiceSpy = ConfirmExchangeServiceSpy()
        
        let sut = CvvPinService(
            getProcessingSessionCodeService: getProcessingSessionCodeServiceSpy,
            exchangeKeyService: exchangeKeyServiceSpy,
            confirmExchangeService: confirmExchangeServiceSpy
        )
        
        // track memory leaks
        
        return (sut, getProcessingSessionCodeServiceSpy, exchangeKeyServiceSpy, confirmExchangeServiceSpy)
    }
    
    private final class GetProcessingSessionCodeServiceSpy: GetProcessingSessionCodeService {
        
        private var completions = [(Result<ProcessingSessionCode, Error>) -> Void]()
        
        func get(completion: @escaping (Result<ProcessingSessionCode, Error>) -> Void) {
            
            completions.append(completion)
        }
        
        func complete(
            with result: Result<ProcessingSessionCode, Error>,
            at index: Int = 0
        ) {
            completions[index](result)
        }
    }
    
    private final class ExchangeKeyServiceSpy: ExchangeKeyService {
        
        private var messages = [(code: ProcessingSessionCode, completion: (Result<KeyExchange, Error>) -> Void)]()
        
        var codes: [ProcessingSessionCode] { messages.map(\.code) }
        
        func exchange(_ code: ProcessingSessionCode, completion: @escaping (Result<KeyExchange, Error>) -> Void) {
            
            messages.append((code, completion))
        }
        
        func complete(
            with result: Result<KeyExchange, Error>,
            at index: Int = 0
        ) {
            messages[index].completion(result)
        }
    }
    
    private final class ConfirmExchangeServiceSpy: ConfirmExchangeService {
        
//        private let stub: Result<Void, Error>
//
//        init(stub: Result<Void, Error>) {
//
//            self.stub = stub
//        }
//
//        func confirm(completion: @escaping (Result<Void, Error>) -> Void) {
//
//            completion(stub)
//        }
    }
}
