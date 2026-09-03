import Call_Algebra
import Client
import HTTP
import HTTP_Coder
import HTTP_Responder
import Optic
import RFC_9110
import Testing

private enum Fixture {}

extension Fixture {
    enum Domain {}

    enum Refusal: Swift.Error, Equatable {
        case refused
    }
}

extension Fixture.Domain {
    enum Call {
        case respond(Int)
    }
}

extension Fixture.Domain.Call {
    enum Branch {
        enum Respond {}
    }

    struct Branches {
        var respond: Call_Algebra.Call.Branch<
            Fixture.Domain.Call,
            Int,
            Branch.Respond
        > {
            .init(
                .init(
                    embed: Fixture.Domain.Call.respond,
                    extract: { call in
                        switch call {
                        case .respond(let input): input
                        }
                    }
                )
            )
        }
    }
}

extension Fixture.Domain.Call.Branch.Respond: Call_Algebra.Call.Operation {
    typealias Input = Int
    typealias Output = String
    typealias Failure = Fixture.Refusal
}

extension Fixture.Domain.Call: Call_Algebra.Call.Singleton {
    typealias Operation = Branch.Respond
    typealias Coverage = Branch.Respond

    static var branches: Branches { .init() }

    static var value: Optic<Self, Self, Operation.Input, Operation.Input>.Prism {
        branches.respond.prism
    }
}

extension Fixture.Domain: Call_Algebra.Call.Domain {}

private struct Response: HTTP.Coding {
    typealias Domain = Fixture.Domain
    typealias Operation = Fixture.Domain.Call.Branch.Respond
    typealias Content = String
    typealias Coverage = Operation
    typealias Input = HTTP.Message.Response<String>?
    typealias Output = Swift.Result<String, Fixture.Refusal>
    typealias Buffer = HTTP.Message.Response<String>?
    typealias Failure = HTTP.Coder.Error
    typealias Body = Never

    func parse(_ input: inout Input) throws(Failure) -> Output {
        guard let response = input else {
            throw .malformed
        }
        input = nil
        if response.status == .ok {
            return .success(response.content)
        }
        return .failure(.refused)
    }

    func serialize(
        _ output: Output,
        into buffer: inout Buffer
    ) throws(Failure) {
        guard case nil = buffer else {
            throw .unprintable
        }
        switch output {
        case .success(let value):
            buffer = .init(status: .ok, content: value)
        case .failure:
            buffer = .init(status: .badRequest, content: "refused")
        }
    }
}

@Test
func `response interpretation preserves the operation index`() async throws {
    let client = Client::Client<Int, String, Fixture.Refusal>(
        run: { value throws(Fixture.Refusal) in String(value) }
    )
    let response = try await HTTP.response(
        \Fixture.Domain.Call.Branches.respond,
        to: 42,
        using: client,
        coding: Response()
    )

    #expect(response.status == .ok)
    #expect(response.content == "42")
}

@Test
func `a domain refusal is encoded as a response`() async throws {
    let client = Client::Client<Int, String, Fixture.Refusal>(
        run: { _ throws(Fixture.Refusal) in throw .refused }
    )
    let response = try await HTTP.response(
        \Fixture.Domain.Call.Branches.respond,
        to: 42,
        using: client,
        coding: Response()
    )

    #expect(response.status == .badRequest)
    #expect(response.content == "refused")
}
