public import Coder_Primitive
public import Either_Primitives
public import HTTP
public import HTTP_Coder
public import Parser_Primitive
public import Serializer_Primitive

extension HTTP {

    /// The one generic helper of the server edge: run a typed-throwing
    /// operation, fold its outcome into the operation's `Either` row, and
    /// serialize through the operation's response coder.
    ///
    /// Mapping route failures to statuses is application policy at the
    /// edge, never part of this algebra.
    public static func respond<Response, Refusal, Output>(
        _ response: Response,
        _ operation: () async throws(Refusal) -> Output
    ) async throws(HTTP.Response.Coder.Error) -> HTTP.Response
    where
        Response: Coder.`Protocol`,
        Response.Input == HTTP.Response?,
        Response.Buffer == HTTP.Response?,
        Response.Output == Either<Refusal, Output>,
        Response.Failure == HTTP.Response.Coder.Error
    {
        let outcome: Either<Refusal, Output>
        do throws(Refusal) {
            outcome = .right(try await operation())
        } catch {
            outcome = .left(error)
        }

        var buffer: HTTP.Response?
        try response.serialize(outcome, into: &buffer)

        guard let buffer else {
            throw .unprintable
        }
        return buffer
    }
}
