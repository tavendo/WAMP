### Authentication {#authorization}

Authentication is a complex area. Some applications might want to leverage authentication information coming from the transport underlying WAMP, e.g. HTTP cookies or TLS certificates.

Some transports might imply trust or implicit authentication by their very nature, e.g. Unix domain sockets with appropriate file system permissions in place.

Other application might want to perform their own authentication using external mechanisms (completely outside and independent of WAMP).

Some applications might want to perform their own authentication schemes by using basic WAMP mechanisms, e.g. by using application-defined remote procedure calls.

And some applications might want to use a transport independent scheme, nevertheless predefined by WAMP.

#### WAMP-level Authentication

The message flow between Clients and Routers for establishing and tearing down sessions MAY involve the following messages which authenticate a session:

1. `CHALLENGE`
2. `AUTHENTICATE`

{align="left"}
         ,------.          ,------.
         |Client|          |Router|
         `--+---'          `--+---'
            |      HELLO      |
            | ---------------->
            |                 |
            |    CHALLENGE    |
            | <----------------
            |                 |
            |   AUTHENTICATE  |
            | ---------------->
            |                 |
            | WELCOME or ABORT|
            | <----------------
         ,--+---.          ,--+---.
         |Client|          |Router|
         `------'          `------'

Concrete use of `CHALLENGE` and `AUTHENTICATE` messages depends on the specific authentication method.

See [WAMP Challenge-Response Authentication](#wampcra) or [ticket authentication](#ticketauth) for the use in these authentication methods.

If two-factor authentication is desired, then two subsequent rounds of `CHALLENGE` and `RESPONSE` may be employed.

*CHALLENGE*

An authentication MAY be required for the establishment of a session. Such requirement MAY be based on the `Realm` the connection is requested for.

To request authentication, the Router MUST send a `CHALLENGE` message to the *Endpoint*.

{align="left"}
        [CHALLENGE, AuthMethod|string, Extra|dict]


*AUTHENTICATE*

In response to a `CHALLENGE` message, the Client MUST send an `AUTHENTICATE` message.

{align="left"}
        [AUTHENTICATE, Signature|string, Extra|dict]

If the authentication succeeds, the Router MUST send a `WELCOME` message, else it MUST send an `ABORT` message.


#### Transport-level Authentication

##### Cookie-based Authentication

When running WAMP over WebSocket, the transport provides HTTP client cookies during the WebSocket opening handshake. The cookies can be used to authenticate one peer (the client) against the other (the server). The other authentication direction cannot be supported by cookies.

This transport-level authentication information may be forwarded to the WAMP level within `HELLO.Details.transport.auth|any` in the client-to-server direction.


##### TLS Certificate Authentication

When running WAMP over a TLS (either secure WebSocket or raw TCP) transport, a peer may authenticate to the other via the TLS certificate mechanism. A server might authenticate to the client, and a client may authenticate to the server (TLS client-certificate based authentication).

This transport-level authentication information may be forwarded to the WAMP level within `HELLO.Details.transport.auth|any` in both directions (if available).
