public import Client
public import Coder_Primitive
public import Either_Primitives
public import HTTP
public import HTTP_Coder
public import HTTP_Router

extension HTTP {
    public static func route<Domain: HTTP.Routable>(
        _ domain: Domain.Type,
        _ request: HTTP.Message.Request<Domain.Route.Content>
    ) throws(HTTP.Router.Error) -> Domain.Call {
        var request = Optional(request)
        return try Domain.router.parse(&request)
    }

    public static func response<Response, Content>(
        _ result: Response.Output,
        using response: Response
    ) throws(
        Either<Response.Failure, HTTP.Message.Error>
    ) -> HTTP.Message.Response<Content>
    where
        Response: Coder.`Protocol`,
        Response.Input == HTTP.Message.Response<Content>?,
        Response.Buffer == HTTP.Message.Response<Content>?
    {
        var buffer: HTTP.Message.Response<Content>?
        do throws(Response.Failure) {
            try response.serialize(result, into: &buffer)
        } catch {
            throw .left(error)
        }
        guard let buffer else {
            throw .right(.unprintable)
        }
        return buffer
    }

    public static func responder<Domain, Response, Content>(
        _ domain: Domain.Type,
        response: Response,
        operation: @escaping (Domain.Call) async -> Domain.Call.Result
    ) -> HTTP.Responder<
        Content,
        Either<HTTP.Router.Error, Either<Response.Failure, HTTP.Message.Error>>
    >
    where
        Domain: HTTP.Routable,
        Domain.Route.Content == Content,
        Response: Coder.`Protocol`,
        Response.Input == HTTP.Message.Response<Content>?,
        Response.Buffer == HTTP.Message.Response<Content>?,
        Response.Output == Domain.Call.Result
    {
        .init(
            run: { request throws(
                Either<HTTP.Router.Error, Either<Response.Failure, HTTP.Message.Error>>
            ) in
                let call: Domain.Call
                do throws(HTTP.Router.Error) {
                    call = try HTTP.route(domain, request)
                } catch {
                    throw .left(error)
                }
                let result = await operation(call)
                do throws(Either<Response.Failure, HTTP.Message.Error>) {
                    return try HTTP.response(result, using: response)
                } catch {
                    throw .right(error)
                }
            }
        )
    }
}
