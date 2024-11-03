## Progressive Call Invocations {#rpc-progressive-call-invocations}

A *Caller* may issue a call having progressive invocations. This can be useful in a few cases:

* Payload is too big to send it whole in one request, e.g., uploading a file.
* Long-term data transfer that needs to be consumed early, such as a media stream.
* RPC is called too often and overall processing can be optimized: avoid the need to generate a new id for requests,
  initiate data structures for a new call, etc.

In such cases, a procedure implemented by a *Callee* and registered at a *Dealer* may be made to receive progressive call invocations,
where the *Callee* may start processing the incoming data without awaiting the entire set of payload chunks.


**Feature Announcement**

Support for this advanced feature MUST be announced by *Callers* (`role := "caller"`), *Callees* (`role := "callee"`)
and *Dealers* (`role := "dealer"`) via

{align="left"}
        HELLO.Details.roles.<role>.features.progressive_call_invocations|bool := true

Progressive call invocations can work only if all three peers support and announce this feature.
In addition, *Callees* MUST announce support of the _Call Canceling_ feature via

{align="left"}
        HELLO.Details.roles.callee.features.call_canceling|bool := true


As a consequence, *Dealers* MUST also announce support of the _Call Canceling_ feature via

{align="left"}
        WELCOME.Details.roles.dealer.features.call_canceling|bool := true

The following cases, where a *Caller* sends a `CALL` message with `progress := true`, MUST be treated as *protocol errors*
with the underlying WAMP sessions being aborted:

- The *Caller* did not announce the progressive call invocations feature during the `HELLO` handshake.
- The *Dealer* did not announce the progressive call invocations feature during the `HELLO` handshake.

Otherwise, in cases where the *Caller* sends a `CALL` message with `progress := true` but the *Callee* does not support
progressive call invocations or call canceling, the call MUST be treated as an *application error* with the *Dealer* responding
to the *Caller* with the `wamp.error.feature_not_supported` error message.

**Message Flow**

The message flow for a progressive call when a *Callee* waits for all chunks before processing and sending a single result:

{align="left"}
     ,------.                  ,------.                 ,------.
     |Caller|                  |Dealer|                 |Callee|
     `--+---'                  `--+---'                 `--+---'
        |     CALL (progress)     |                        |
        | ----------------------> |                        |
        |                         | INVOCATION (progress)  |
        |                         | ---------------------->|
        |     CALL (progress)     |                        |
        | ----------------------->|                        |
        |                         | INVOCATION (progress)  |
        |                         | ---------------------->|
        |                         |                        |
        |           ...           |          ...           |
        |                         |                        |
        |     CALL (final)        |                        |
        | ----------------------->|                        |
        |                         |   INVOCATION (final)   |
        |                         | ---------------------->|
        |                         |                        |
        |                         | YIELD (final) or ERROR |
        |                         | <----------------------|
        |                         |                        |
        | RESULT (final) or ERROR |                        |
        | <-----------------------|                        |
     ,--+---.                  ,--+---.                 ,--+---.
     |Caller|                  |Dealer|                 |Callee|
     `------'                  `------'                 `------'

As a `progressive` call chunks are part of the same overall call, the *Caller* must send the same `Request|id`
for every `CALL` and the *Dealer* must also use the same `Request|id` with every `INVOCATION` to the *Callee*.

A *Caller* indicates its willingness to issue a progressive call by setting

{align="left"}
        CALL.Options.progress|bool := true

*Example.* Caller-to-Dealer `CALL`

{align="left"}
```json
    [
        48,
        77245,
        {
            "progress": true
        },
        "com.myapp.get_country_by_coords",
        [50.450001, 30.523333]
    ]
```

If the *Callee* supports progressive call invocations, the *Dealer* shall forward the *Caller's* willingness to send progressive call invocations by setting

{align="left"}
        INVOCATION.Details.progress|bool := true


*Example.* Dealer-to-Callee `INVOCATION`

{align="left"}
```json
    [
        68,
        35224,
        379,
        {
            "progress": true
        },
        [50.450001, 30.523333]
    ]
```

A call invocation MUST *always* end in a *normal* `CALL` without the `"progress": true` option, or explicitly
set `"progress": false` which is the default.


**Progressive Call Invocations and Shared Registration**

RPCs can have a multiple registrations (see `Shared Registration` feature) with different `<invocation_policies>`.
However, allowing progressive `CALL` messages to be routed to different *Callees* would lead to unexpected results.
To prevent this the *Dealer* MUST make a first `INVOCATION` based on `<invocation_policy>` and then route all
subsequent `progressive` calls to the same *Callee*.


**Caller Leaving**

The *Dealer*'s behavior for when a *Caller* leaves or disconnects during a call with progressive invocations shall be the same as in a basic, non-progressive call. That is, the *Dealer* sends an INTERRUPT to the *Callee* with `mode="killnowait"`. See [Caller Leaving During RPC Invocation] (#rpc-caller-leaving) under the Basic Profile.

{align="left"}
     ,------.            ,------.                 ,------.
     |Caller|            |Dealer|                 |Callee|
     `--+---'            `--+---'                 `--+---'
        |  CALL (progress)  |                        |
        | ----------------->|                        |
        |                   | INVOCATION (progress)  |
        |                   | ---------------------->|
        |  CALL (progress)  |                        |
        | ----------------->|                        |
        |                   | INVOCATION (progress)  |
        |                   | ---------------------->|
     ,--+---.               |                        |
     |Caller|               |                        |
     `------'               |                        |
      (gone)                |                        |
                            |       INTERRUPT        |
                            | ---------------------->|
                            |                        |
                         ,--+---.                 ,--+---.
                         |Dealer|                 |Callee|
                         `------'                 `------'

As in progressive call results, such cancellation when the caller leaves addresses a potential security vulnerability:
In cases where progressive call invocations are used to stream data from a *Caller*, and network connectivity is unreliable,
the *Caller* may often get disconnected in the middle of sending progressive data. This can lead to unneeded memory
consumption for the *Dealer* and *Callee*, due to the need to store temporary metadata about ongoing calls.


**Callee Leaving**

The *Dealer*'s behavior for when a *Callee* leaves or disconnects during a call with progressive invocations shall be the same as in a basic, non-progressive call. That is, the *Dealer* sends an ERROR message to the *Caller* with the `wamp.error.canceled` URI. See [Callee Leaving During an RPC Invocation] (#rpc-callee-leaving) under the Basic Profile.

{align="left"}
     ,------.           ,------.                ,------.
     |Caller|           |Dealer|                |Callee|
     `--+---'           `--+---'                `--+---'
        |  CALL (progress) |                       |
        | ----------------->                       |
        |                  | INVOCATION (progress) |
        |                  | ---------------------->
        |                  |                       |
        |                  |                       |
        |                  |                    ,--+---.
        |                  |                    |Callee|
        |      ERROR       |                    `------'
        | <--------------- |                     (gone)
        |                  |
     ,--+---.           ,--+---.
     |Caller|           |Dealer|
     `------'           `------'


**Continuations on Completed Calls**

A call with progressive invocations is considered completed by the *Dealer* when the latter receives a correlated final YIELD or ERROR message from the *Callee*, or when the *Callee* leaves the realm.

Due to network delays, the *Caller* may be unaware that the call is completed by time it sends another progressive CALL continuation.

When a *Dealer* receives a CALL under the following conditions:

- the *Dealer* supports Progressive Call Invocations,
- the CALL request ID does not correspond to a new call request, and,
- the CALL request ID does not match any RPC invocation in progress,

then it MUST ignore and discard that CALL message without any further correlated response to the *Caller*. The rationale for this is that the *Caller* will eventually receive a correlated RESULT or ERROR message from the previous call completion and will be able to handle the call completion accordingly.

The sequence diagram below illustrates this sitation, where the Network actor models network delay.

{align="left"}
     ,------.     ,-------.      ,------.      ,------.
     |Caller|     |Network|      |Dealer|      |Callee|
     `--+---'     `---+---'      `--+---'      `--+---'
        |  CALL #123  |             |             |
        | (progress)  |             |             |
        | ------------>  CALL #123  |             |
        |             | (progress)  |             |
        |             | ------------>  INVOCATION |
        |             |             |  (progress) |
        |             |             | ------------>
        |  CALL #123  |             |             |
        | (progress)  |             |    ERROR    |
        | ------------>             | <-----------|
        |             |    ERROR    |             |
        |             | <-----------|             |
        |             | ,---------. |             |
        |             | |  Call   | |             |
        |             | |Completed| |             |
        |             | `---------' |             |
        |             |             |             |
        |             |  CALL #123  |             |
        |             | (progress)  |             |
        |             | ------------>             |
        |             | ,---------. |             |
        |             | | Ignored | |             |
        |             | `---------' |             |
        |    ERROR    |             |             |
        | <-----------|             |             |
        |             |             |             |
     ,--+---.     ,---+---.      ,--+---.    ,--+---.
     |Caller|     |Network|      |Dealer|    |Callee|
     `------'     `-------'      `------'    `------'

From the *Callee*'s perspective, a call with progressive invocations is considered completed when the *Callee* sends a correlated final YIELD or ERROR message.

Due to network delays, the *Dealer* may be unaware that the call is completed by time it sends another progressive INVOCATION.

When a *Callee* receives an INVOCATION under the following conditions:

- the *Callee* supports Progressive Call Invocations,
- the INVOCATION request ID does not correspond to a new call request, and,
- the INVOCATION request ID does not match any RPC invocation in progress,

then it MUST ignore and discard that INVOCATION message without any further correlated response to the *Dealer*. The rationale for this is that the *Dealer* will eventually receive a correlated YIELD or ERROR message from the *Callee* and then send a correlated RESULT or ERROR message to the *Caller*, thus the *Caller* and the *Dealer* will both be able to handle the call completion accordingly.

The sequence diagram below illustrates this sitation, where the Network actor models network delay.

{align="left"}
     ,------.     ,------.        ,-------.         ,------.
     |Caller|     |Dealer|        |Network|         |Callee|
     `--+---'     `--+---'        `---+---'         `--+---'
        | CALL #123  |                |                |
        | (progres)  |                |                |
        | ----------->                |                |
        |            | INVOCATION #42 |                |
        |            | (progress)     |                |
        |            | --------------->                |
        |            |                | INVOCATION #42 |
        |            |                | (progress)     |
        |            |                | --------------->
        | CALL #123  |                |                |
        | (progress) |                |     ERROR      |
        | ----------->                | <--------------|
        |            | INVOCATION #42 |                |
        |            | (progress)     |                |
        |            | --------------->                |
        |            |                | INVOCATION #42 |
        |            |                | (progress)     |
        |            |     ERROR      | --------------->
        |            | <--------------|   ,-------.    |
        |    ERROR   |                |   |Ignored|    |
        | <----------|                |   `---+---'    |
        |            |                |                |
     ,--+---.     ,--+---.        ,---+---.       ,--+---.
     |Caller|     |Dealer|        |Network|       |Callee|
     `------'     `------'        `-------'       `------'


**Verification of CALL Request IDs**

When sending a CALL that continues a progressive call, its request ID is the same as the CALL that initiated the progressive call invocation. Therefore, when progressive call invocations are enabled, request IDs from CALL messages may not appear sequential. For example:

1. `[CALL, 1, {"progress":true}, "foo"]`
2. `[CALL, 2, {}, "bar"]`
3. `[CALL, 1, {}, "foo"]` (OK, continues CALL request #1)

The requirement for CALL request IDs to be sequential session scope (see [Protocol Violations](#protocol_errors)) must therefore only apply to **new** RPC transactions:

1. `[CALL, 1, {"progress":true}, "foo"]`
2. `[CALL, 2, {}, "bar"]`
3. `[CALL, 4, {}, "baz"]` (protocol violation, request ID 3 expected)

Let us define *watermark* as the maximum valid request ID of all received CALL messages during a *Dealer*'s run time.

Let us also define *continuation candiate* as a CALL with a request ID that is equal to or less than the *watermark*.

When a *Dealer* receives a CALL with a request ID that is exactly one above the watermark, then it shall be considered a new RPC transaction, and the requirement for sequential session scope IDs is verified.

When a *Dealer* receives a CALL with a request ID that is greater than one above the watermark, then this corresponds to a gap in the session scope ID sequence and MUST always be treated as a protocol violation.

When a *Dealer* receives a CALL with a request ID that is equal to or less than the watermark, then it is considered as a _continuation candidate_ for a progressive invocation transfer.

As discussed in the previous section, a *Caller* may be unaware that a progressive invocation transfer is completed while sending a CALL continuation for that progressive invocation. Therefore, the *Dealer* cannot simply just check against progressive transfers in progress when verifying the validity of continuation candidates. It must also consider past progressive transfers that have been completed.

In order to validate the request ID of continuation candidates, it is suggested that a *Dealer* maintain a table of request IDs of completed progressive invocation transfers, where each entry is kept for a limited *grace period*. When a *Dealer* receives a continuation candidate with a request ID that is not in that table, nor in the list of active progressive invocations, then it is considered a protocol violation. Care must be taken in choosing the grace period: too short and data races can occur with slow networks, too long and memory usage of the table may become excessive when frequent progressive calls are made.

Due to resource constraints, it may not be desireable to implement such a grace period table, so *Dealers* MAY instead discard continuation candidates with request IDs that cannot be found in the list of active progressive invocation transfers.

The following pseudocode summarizes the algorithm for verifying CALL request IDs when progressive call invocations are enabled:

```
if (request_id == watermark + 1)
    watermark = watermak + 1
    initiate_new_call()
else if (request_id > watermark + 1)
    // Gap in request IDs
    abort_session("wamp.error.protocol_violation")
else
    // Continuation candidate
    if (active_call_records.contains(request_id, procedure_uri))
        record = active_call_records.at(request_id)
        if (record.is_progressive_invocation_call())
            continue_call()
        else
            abort_session("wamp.error.protocol_violation")
        endif
    else if (strict_request_id_verification_enabled)
        if (grace_period_table.contains(request_id, procedure_uri))
            discard_call()
        else
            abort_session("wamp.error.protocol_violation")
        endif
    else
        discard_call()
    endif
endif
```

**Ignoring Progressive Call Invocations**

Unlike some other advanced features, a *Callee* cannot be unaware of progressive call invocations.
Therefore, if a *Callee* doesn't support this feature, the *Dealer* MUST respond to the *Caller* with an
`wamp.error.feature_not_supported` error message.

A *Callee* that supports progressive call invocations, but does not support call canceling, shall be considered by the *Dealer*
as not supporting progressive call invocations.


**Progressive Call Invocations with Progressive Call Results**

*Progressive Call Invocations* may be used in conjunction with *Progressive Call Results* if the *Caller*, *Dealer*, and *Callee* all support both features. This allows the *Callee* to start sending partial results back to the *Caller* after receiving one or more initial payload chunks. Efficient two-way streams between a *Caller* and *Callee* can be implemented this way.

The following message flow illustrates a call using progressive call invocations when a *Callee* starts sending progressive call
results immediately. Note that `YIELD` messages don't need to be matched with `CALL`/`INVOCATION` messages.
For example, the *caller* can send a few `CALL` messages before starting to receive `RESULT` messages; they do not need
to be matched pairs.

{align="left"}
     ,------.                  ,------.                 ,------.
     |Caller|                  |Dealer|                 |Callee|
     `--+---'                  `--+---'                 `--+---'
        |     CALL (progress)     |                        |
        |------------------------>|                        |
        |                         | INVOCATION (progress)  |
        |                         |----------------------->|
        |                         |                        |
        |                         |   YIELD (progress)     |
        |                         |<-----------------------|
        |                         |                        |
        |   RESULT (progress)     |                        |
        |<------------------------|                        |
        |                         |                        |
        |    CALL (progress)      |                        |
        |------------------------>|                        |
        |                         | INVOCATION (progress)  |
        |                         |----------------------->|
        |                         |                        |
        |    CALL (progress)      |                        |
        |------------------------>|                        |
        |                         | INVOCATION (progress)  |
        |                         |----------------------->|
        |                         |    YIELD (progress)    |
        |                         |<-----------------------|
        |                         |                        |
        |   RESULT (progress)     |                        |
        |<------------------------|                        |
        |                         |                        |
        |                         |    YIELD (progress)    |
        |                         |<-----------------------|
        |                         |                        |
        |   RESULT (progress)     |                        |
        |<------------------------|                        |
        |                         |                        |
        |          ...            |          ...           |
        |                         |                        |
        |      CALL (final)       |                        |
        |------------------------>|                        |
        |                         |   INVOCATION (final)   |
        |                         |----------------------->|
        |                         |                        |
        |                         | YIELD (final) or ERROR |
        |                         |<-----------------------|
        |                         |                        |
        | RESULT (final) or ERROR |                        |
        |<------------------------|                        |
     ,--+---.                  ,--+---.                 ,--+---.
     |Caller|                  |Dealer|                 |Callee|
     `------'                  `------'                 `------'

Because they are part of the same call operation, the request ID is the same in all `CALL`,
`INVOCATION`, `YIELD`, and `ERROR` messages in the above exchange.


**Freezing of Options in Progressive Call Invocations**

Except for `progress`, items in the `Options` dictionary of the **initiating** progressive `CALL` shall be effective for
the entirety of the progressive call request. Only the `progress` option shall be considered by the *Dealer* in subsequent progressive call invocations
(within the same overall request). Except for `progress`, items in the `Details`
dictionary of corresponding `INVOCATION` messages shall be based on the initiating progressive `CALL` only.

For example, if `disclose_me=true` was specified in the initiating progressive call, all subsequent progressive call invocations
(within the same call) shall be considered by the *Dealer* to implictly have `disclose_me=true` as well. That is, all
`INVOCATION` messages associated with the overall request shall contain caller identify information.

Any option besides `progress` SHOULD be omitted altogether by the *Caller* in subsequent progressive call invocations. Not having to repeat (and not being able to change) options is more in tune with the concept of a media stream where options are set up initially, and the source (*Caller*) only needs to keep uploading more data thereafter.

In subsequent call invocations:

- *Dealers* and *Callees* MUST ignore any option except for `progress`
- *Dealers* SHOULD NOT propagate any option passed by the *Caller*, except for `progress`

*Dealers* and *Callees* are responsible for remembering the options of the initiating progressive `CALL`.

For reference, here is a list of options that are frozen upon the initial progressive call invocations:

- `CALL.Options.disclose_me|bool`
- `CALL.Options.ppt_cipher|string`
- `CALL.Options.ppt_keyid|string`
- `CALL.Options.ppt_scheme|string`
- `CALL.Options.ppt_serializer|string`
- `CALL.Options.receive_progress|bool`
- `CALL.Options.rkey`
- `CALL.Options.runmode|string`
- `CALL.Options.timeout|integer`

These rules concerning progressive call invocation options also apply to custom options that are not part of this specification.
