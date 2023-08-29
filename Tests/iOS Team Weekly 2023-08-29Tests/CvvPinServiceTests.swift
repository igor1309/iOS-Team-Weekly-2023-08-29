//
//  CvvPinServiceTests.swift
//  
//
//  Created by Igor Malyarov on 29.08.2023.
//

import XCTest

enum GetProcessingSessionCodeDomain {}

extension GetProcessingSessionCodeDomain {
    
    typealias Result = Swift.Result<ProcessingSessionCode, Error>
    typealias Completion = (Result) -> Void
    typealias Get = (@escaping Completion) -> Void
    
    struct ProcessingSessionCode {}
}

// ----

enum ExchangeKeyDomain {}

extension ExchangeKeyDomain {
    
    typealias Result = Swift.Result<ProcessingSessionCode, Error>
    typealias Completion = (Result) -> Void

    struct ProcessingSessionCode {}
    
    struct KeyExchange {}
}

protocol ExchangeKeyService {
    
    typealias ProcessingSessionCode = ExchangeKeyDomain.ProcessingSessionCode
    typealias Completion = ExchangeKeyDomain.Completion

    func exchange(_ code: ProcessingSessionCode, completion: @escaping Completion)
}


protocol ConfirmExchangeService {
    
    func confirm(keyExchange: ConfirmKeyExchange, completion: @escaping (Result<Void, Error>) -> Void)
}

struct ConfirmKeyExchange {}

struct OTP {}

final class CvvPinService {
    
    private let getProcessingSessionCode: GetProcessingSessionCodeDomain.Get
    private let exchangeKeyService: ExchangeKeyService
    private let confirmExchangeService: ConfirmExchangeService
    
    init(
        getProcessingSessionCode: @escaping GetProcessingSessionCodeDomain.Get,
        exchangeKeyService: ExchangeKeyService,
        confirmExchangeService: ConfirmExchangeService
    ) {
        self.getProcessingSessionCode = getProcessingSessionCode
        self.exchangeKeyService = exchangeKeyService
        self.confirmExchangeService = confirmExchangeService
    }
    
    typealias ExchangeKeyCompletion = (Result<ExchangeKeyDomain.KeyExchange, Error>) -> Void
    
    func exchangeKey(completion: @escaping ExchangeKeyCompletion) {
        
        getProcessingSessionCode { [unowned self] result in
            
            switch result {
            case let .failure(error):
                completion(.failure(error))
                
            case let .success(code):
                exchangeKeyService.exchange(.init(code)) { result in
                    
                    switch result {
                    case let .failure(error):
                        completion(.failure(error))
                        
                    case let .success(keyExchange):
//                        completion(.success(.init(keyExchange)))
                    }
                }
            }
        }
    }
    
    typealias ConfirmExchangeCompletion = () -> Void
    
    func confirmExchange(withOTP: OTP, completion: ConfirmExchangeCompletion) {}
}

// adapter
extension ExchangeKeyDomain.ProcessingSessionCode {
    
    init(_ processingSessionCode: GetProcessingSessionCodeDomain.ProcessingSessionCode) {}
}

extension ConfirmKeyExchange {
    
    init(_ keyExchange: ExchangeKeyDomain.KeyExchange) {}
}

final class CvvPinServiceTests: XCTestCase {
    
    func test() {
        
        let (sut, getProcessingSessionCodeServiceSpy, exchangeKeyServiceSpy, confirmExchangeServiceSpy) = makeSUT(confirmStub: .failure(AnyError()))
        var results = [Result<ExchangeKeyDomain.KeyExchange, Error>]()
        let exp = expectation(description: "wait for completion")
        
        sut.exchangeKey {
            results.append($0)
            exp.fulfill()
        }
        getProcessingSessionCodeServiceSpy.complete(with: .success(.init()))
        exchangeKeyServiceSpy.complete(with: .failure(AnyError()))
        wait(for: [exp], timeout: 1.0)
        // assert
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        confirmStub: Result<Void, Error>,
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
        let confirmExchangeServiceSpy = ConfirmExchangeServiceSpy(stub: confirmStub)
        
        let sut = CvvPinService(
            getProcessingSessionCode: getProcessingSessionCodeServiceSpy.get(completion:),
            exchangeKeyService: exchangeKeyServiceSpy,
            confirmExchangeService: confirmExchangeServiceSpy
        )
        
        // track memory leaks
        
        return (sut, getProcessingSessionCodeServiceSpy, exchangeKeyServiceSpy, confirmExchangeServiceSpy)
    }
    
    private final class GetProcessingSessionCodeServiceSpy: GetProcessingSessionCodeService {
        
        typealias Result = GetProcessingSessionCodeDomain.Result
        
        private var completions = [(Result) -> Void]()
        
        func get(completion: @escaping (Result) -> Void) {
            
            completions.append(completion)
        }
        
        func complete(
            with result: Result,
            at index: Int = 0
        ) {
            completions[index](result)
        }
    }
    
    private final class ExchangeKeyServiceSpy: ExchangeKeyService {
        
        typealias Result = ExchangeKeyDomain.Result
        
        private var messages = [(code: ExchangeKeyDomain.ProcessingSessionCode, completion: (Result) -> Void)]()
        
        var codes: [ExchangeKeyDomain.ProcessingSessionCode] { messages.map(\.code) }
        
        func exchange(_ code: ExchangeKeyDomain.ProcessingSessionCode, completion: @escaping (Result) -> Void) {
            
            messages.append((code, completion))
        }
        
        func complete(
            with result: Result,
            at index: Int = 0
        ) {
            messages[index].completion(result)
        }
    }
    
    private final class ConfirmExchangeServiceSpy: ConfirmExchangeService {
        
        private let stub: Result<Void, Error>

        init(stub: Result<Void, Error>) {

            self.stub = stub
        }

        func confirm(keyExchange: ConfirmKeyExchange, completion: @escaping (Result<Void, Error>) -> Void) {

            completion(stub)
        }
    }
}

private struct AnyError: Error {}
