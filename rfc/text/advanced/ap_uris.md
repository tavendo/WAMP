## Advanced Profile

A *Dealer* or *Callee* canceled a call previously issued

{align="left"}
        wamp.error.canceled

A *Peer* requested an interaction with an option that was disallowed by the *Router*

{align="left"}
        wamp.error.option_not_allowed

A *Dealer* could not perform a call, since a procedure with the given URI is registered, but *Callee Black- and Whitelisting* and/or *Caller Exclusion* lead to the exclusion of (any) *Callee* providing the procedure.

{align="left"}
        wamp.error.no_eligible_callee

A *Router* rejected client request to disclose its identity

{align="left"}
        wamp.error.option_disallowed.disclose_me

A *Router* encountered a network failure

{align="left"}
        wamp.error.network_failure

A *Callee* is not able to handle an invocation for a *call* and intends for the *Router* to re-route the *call* to another fitting *Callee*. For details, refer to [RPC Call Rerouting](ap_rpc_call_rerouting.md)

{align="left"}
        wamp.error.unavailable

A *Dealer* could not perform a call, since a procedure with the given URI is registered, but all available registrations have responded with `wamp.error.unavailable`

{align="left"}
        wamp.error.no_available_callee
