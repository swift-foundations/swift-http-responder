import Byte_Primitive
import Coder_Primitive
import Either_Primitives
import HTTP
import HTTP_Coder
import HTTP_Responder
import Parser_Primitive
import Serializer_Primitive
import Testing

private enum Refusal: Swift.Error, Equatable {
    case tooMuch
}

/// A choice-shaped response coder: `.ok` carries the text, `.badRequest`
/// carries the refusal. A stand-in for an operation's response coder,
/// exercised through `HTTP.respond`'s generic slot.
private struct Choice: Coder.`Protocol` {

    typealias Input = HTTP.Response?
    typealias Output = Either<Refusal, String>
    typealias Buffer = HTTP.Response?
    typealias Failure = HTTP.Response.Coder.Error
    typealias Body = Never

    func parse(
        _ input: inout HTTP.Response?
    ) throws(HTTP.Response.Coder.Error) -> Either<Refusal, String> {
        guard let response = input else {
            throw .noMatch
        }
        switch response.status {
        case .badRequest:
            input = nil
            return .left(.tooMuch)
        case .ok:
            guard
                let bytes = response.body,
                let text = String(
                    validating: bytes.lazy.map(\.underlying),
                    as: UTF8.self
                )
            else {
                throw .malformed
            }
            input = nil
            return .right(text)
        default:
            throw .noMatch
        }
    }

    func serialize(
        _ output: Either<Refusal, String>,
        into buffer: inout HTTP.Response?
    ) {
        switch output {
        case .left:
            buffer = .init(status: .badRequest)
        case .right(let text):
            buffer = .init(status: .ok, body: text.utf8.map(Byte.init))
        }
    }
}

@Test
func `respond serializes a success outcome through the coder`() async throws {
    let response = try await HTTP.respond(Choice()) { () throws(Refusal) -> String in
        "seven"
    }
    #expect(response == .init(status: .ok, body: "seven".utf8.map(Byte.init)))
}

@Test
func `respond folds a typed refusal into the refusal branch`() async throws {
    let response = try await HTTP.respond(Choice()) { () throws(Refusal) -> String in
        throw .tooMuch
    }
    #expect(response == .init(status: .badRequest))
}
