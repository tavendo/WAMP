## Call Timeouts {#rpc-call-timeout}

The Call Timeouts feature allows for **automatic** cancellation of a remote procedure call by the *Dealer* or *Callee* after a specified time duration.

A *Caller* specifies a timeout by providing

{align="left"}
        CALL.Options.timeout|integer

in milliseconds. Automatic call timeouts are deactivated if there is no `timeout` option, or if its value is `0`.

**Dealer-Initiated Timeouts**

If the *Callee* does not support Call Timeouts, a *Dealer* supporting this feature MUST start a timeout timer upon receiving a `CALL` message with a `timeout` option. The message flow for call timeouts is identical to Call Canceling, except that there is no `CANCEL` message that originates from the *Caller*. The cancellation mode is implicitly `killnowait` if the *Callee* supports call cancellation, otherwise the cancellation mode is `skip`.

The error message that is returned to the *Caller* MUST use `wamp.error.timeout` as the reason URI.

**Callee-Initiated Timeouts**

If the *Callee* supports Call Timeouts, the *Dealer* MAY propagate the `CALL.Options.timeout|integer` option via the `INVOCATION` message and allow the *Callee* to handle the timeout logic. If the operation times out, the *Callee* MUST return an `ERROR` message with `wamp.error.timeout` as the reason URI.

*Callees* wanting to handle the timeout logic MAY specify this intention via the `REGISTER.Options.forward_timeout|boolean` option. The *Dealer*, upon receiving a CALL with the `timeout` option set, checks if the matching RPC registration had the `forward_timeout` option set, then accordingly either forwards the timeout value or handles the timeout logic locally without forwarding the timeout value.

*Dealers* MAY choose to override the `REGISTER.Options.forward_timeout|boolean` option based on router configuration. For example, if a *Dealer* is resource-constrained and does not wish to maintain a queue of pending call timeouts, it may decide to always forward the CALL timeout option to *Callees*.

**Caller-Initiated Timeouts**

*Callers* may run their own timeout timer and send a `CANCEL` message upon timeout. This is permitted if the *Dealer* supports Call Canceling and is not considered to be a usage of the Call Timeouts feature.

**Feature Announcement**

Support for this feature MUST be announced by *Dealers* (`role := "dealer"`) and MAY be announced by *Callees* (`role := "callee"`) via

{align="left"}
        HELLO.Details.roles.<role>.features.call_timeout|bool := true

If a *Callee* does not support Call Timeouts, it may optionally announce support for Call Cancellation via

{align="left"}
        HELLO.Details.roles.<role>.features.call_canceling|bool := true
