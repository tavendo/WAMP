## Feature Announcement

Support for advanced features must be announced by the peers which implement them. The following is a complete list of advanced features currently defined or proposed.

**Advanced RPC Features**

{align="left"}
| Feature                                                           | Status | Caller | Dealer | Callee |
|-------------------------------------------------------------------|--------|--------|--------|--------|
| [Call Canceling](#rpc-call-canceling)                             | alpha  | X      | X      | X      |
| [Call Timeout](#rpc-call-timeout)                                 | alpha  | X      | X      | X      |
| [Progressive Call Results](#rpc-progressive-call-results)         | stable | X      | X      | X      |
| [Progressive Call Invocations](#rpc-progressive-call-invocations) | alpha  | X      | X      | X      |
| [Caller Identification](#rpc-call-identification)                 | stable | X      | X      | X      |
| [Call Trustlevels](#rpc-call-trust-levels)                        | alpha  |        | X      | X      |
| [Registration Meta API](#rpc-reg-metapi)                          | beta   |        | X      |        |
| [Pattern-based Registration](#rpc-pattern-reg)                    | stable |        | X      | X      |
| [Shared Registration](#rpc-shared-registration)                   | beta   |        | X      | X      |
| [Sharded Registration](##rpc-sharded-registration)                | alpha  |        | X      | X      |
| [Registration Revocation](#rpc-registration-revocation)           | alpha  |        | X      | X      |
| [(Interface) Procedure Reflection](#interface-reflection)         | sketch |        | X      |        |


**Advanced PubSub Features**

{align="left"}
| Feature                                                   | Status | Publisher | Broker | Subscriber |
|-----------------------------------------------------------|--------|-----------|--------|------------|
| [Subscriber Blackwhite Listing](#pubsub-bw-listing)       | stable | X         | X      |            |
| [Publisher Exclusion](#pubsub-pub-exclusion)              | stable | X         | X      |            |
| [Publisher Identification](#pubsub-pub-identification)    | stable | X         | X      | X          |
| [Publication Trustlevels](#pubsub-pub-trustlevels)        | alpha  |           | X      | X          |
| [Subscription Meta API](#pubsub-sub-metapi)               | beta   |           | X      |            |
| [Pattern-based Subscription](#pattern-based-subscription) | stable |           | X      | X          |
| [Sharded Subscription](#pubsub-sharded-subscription)      | alpha  |           | X      | X          |
| [Event History](#pubsub-event-history)                    | beta   |           | X      |            |
| [(Interface) Topic Reflection](#interface-reflection)     | sketch |           | X      |            |


**Other Advanced Features**

{align="left"}
| Feature                                          | Status |
|--------------------------------------------------|--------|
| [Challenge-response Authentication](#wampcra)    | stable |
| [Ticket authentication](#ticketauth)             | beta   |
| [Cryptosign authentication](#cryptosignauth)     | beta   |
| [RawSocket transport](#rawsocket)                | stable |
| [Batched WebSocket transport](#batchedwebsocket) | sketch |
| [HTTP Longpoll transport](#longpoll)             | beta   |
| [Session Meta API](#session-metapi)              | beta   |
| [Call Rerouting](#rpc-call-rerouting)            | sketch |
| [Payload Passthru Mode](#payload-passthru-mode)  | sketch |


The status of the respective AP feature is marked as follows:

| Status | Description                                                                                                                                                                                              |
|--------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| sketch | There is a rough description of an itch to scratch, but the feature use case isn't clear, and there is no protocol proposal at all.                                                                      |
| alpha  | The feature use case is still fuzzy and/or the feature definition is unclear, but there is at least a protocol level proposal.                                                                           |
| beta   | The feature use case is clearly defined and the feature definition in the spec is sufficient to write a prototype implementation. The feature definition and details may still be incomplete and change. |
| stable | The feature definition in the spec is complete and stable and the feature use case is field proven in real applications. There are multiple, interoperable implementations.                              |
