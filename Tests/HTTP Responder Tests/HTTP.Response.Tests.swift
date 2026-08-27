import Coder_Primitive
import HTTP
import HTTP_Responder
import Testing

private struct Response: Coder.`Protocol` {
    typealias Input = HTTP.Message.Response<String>?
    typealias Output = String
    typealias Buffer = HTTP.Message.Response<String>?
    typealias Failure = Never
    typealias Body = Never

    func parse(_ input: inout Input) -> String {
        let content = input?.content ?? ""
        input = nil
        return content
    }

    func serialize(_ output: String, into buffer: inout Buffer) {
        buffer = .init(status: .ok, content: output)
    }
}

@Test
func responseCodingIsIndependentFromRouting() throws {
    let response: HTTP.Message.Response<String> = try HTTP.response(
        "hello",
        using: Response()
    )
    #expect(response.content == "hello")
}
