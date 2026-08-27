public import Call_Algebra
public import Client
public import HTTP
public import HTTP_Coder
public import RFC_9110
import Serializer_Primitive

extension HTTP {
    public static func response<Domain, Operation, Response, Content>(
        _: KeyPath<
            Domain.Call.Branches,
            Call_Algebra.Call.Branch<
                Domain.Call,
                Operation.Input,
                Operation
            >
        >,
        to input: Operation.Input,
        using client: Client::Client<
            Operation.Input,
            Operation.Output,
            Operation.Failure
        >,
        coding coder: Response
    ) async throws(HTTP.Coder.Error) -> HTTP.Message.Response<Content>
    where
        Domain: Call_Algebra.Call.Domain,
        Operation: Call_Algebra.Call.Operation,
        Response: HTTP.Coding,
        Response.Domain == Domain,
        Response.Operation == Operation,
        Response.Content == Content
    {
        try await response(
            to: input,
            using: client,
            coding: coder
        )
    }

    public static func response<Domain, Content>(
        _: Domain.Type,
        to input: Domain.Call.Operation.Input,
        using client: Client::Client<
            Domain.Call.Operation.Input,
            Domain.Call.Operation.Output,
            Domain.Call.Operation.Failure
        >
    ) async throws(HTTP.Coder.Error) -> HTTP.Message.Response<Content>
    where
        Domain: HTTP.Respondable,
        Domain.Call: Call_Algebra.Call.Singleton,
        Domain.Response: HTTP.Coding,
        Domain.Response.Operation == Domain.Call.Operation,
        Domain.Response.Content == Content
    {
        try await response(
            to: input,
            using: client,
            coding: Domain.response
        )
    }

    private static func response<Response, Content>(
        to input: Response.Operation.Input,
        using client: Client::Client<
            Response.Operation.Input,
            Response.Operation.Output,
            Response.Operation.Failure
        >,
        coding response: Response
    ) async throws(HTTP.Coder.Error) -> HTTP.Message.Response<Content>
    where
        Response: HTTP.Coding,
        Response.Content == Content
    {
        let result: Swift.Result<
            Response.Operation.Output,
            Response.Operation.Failure
        >
        do throws(Response.Operation.Failure) {
            result = .success(try await client(input))
        } catch {
            result = .failure(error)
        }
        var buffer: HTTP.Message.Response<Content>?
        try response.serialize(result, into: &buffer)
        guard let buffer else {
            throw .unprintable
        }
        return buffer
    }
}
