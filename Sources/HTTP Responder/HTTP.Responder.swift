public import Client
public import HTTP

extension HTTP {
    public typealias Responder<Content, Failure: Swift.Error> =
        Client::Client<
            HTTP.Message.Request<Content>,
            HTTP.Message.Response<Content>,
            Failure
        >
}
