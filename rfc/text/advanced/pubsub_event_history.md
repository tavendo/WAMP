### Event History {#pubsub-event-history}

Instead of complex QoS for message delivery, a *Broker* may provide *Event History*. With event history, a *Subscriber* 
is responsible for handling overlaps (duplicates) when it wants "exactly-once" message processing across restarts.

The event history may be transient, or it may be persistent where it survives *Broker* restarts.

The *Broker* implementation may allow for configuration of event history on a per-topic or per-topic-pattern
basis. Such configuration could enable/disable the feature, set the event history storage location,
set parameters for sub-features such as compression, or set the event history data retention policy.

Event History saves events published to discrete subscriptions, in the chronological order received by the broker.
Let us examine an example.

Subscriptions:

1. Subscription to exact match 'com.mycompany.log.auth' topic
2. Subscription to exact match 'com.mycompany.log.basket' topic
3. Subscription to prefix-based 'com.mycompany.log' topic

Publication messages:

1. Publication to topic 'com.mycompany.log.auth'. Forwarded as events to subscriptions 1 and 3.
2. Publication to topic 'com.mycompany.log.basket'. Delivered as event to subscriptions 2 and 3.
3. Publication to topic 'com.mycompany.log.basket'. Delivered as events to subscriptions 2 and 3.
4. Publication to topic 'com.mycompany.log.basket'. Delivered as events subscriptions 2 and 3.
5. Publication to topic 'com.mycompany.log.checkout'. Delivered as an event to subscription 3 only.

Event History:

* Event history for subscription 1 contains publication 1 only.
* Event history for subscription 2 contains publications 2, 3, and 4.
* Event history for subscription 3 contains all publications.

**Feature Announcement**

A *Broker* that implements *event history* must indicate 
`HELLO.roles.broker.features.event_history = true`, must announce the role `HELLO.roles.callee`, 
and must provide the meta procedures described below.

**Receiving Event History**

A *Caller* can request message history by calling the *Broker* meta procedure

{align="left"}
        wamp.subscription.get_events

With payload:

* `Arguments` = `[subscription|id]`. The subscription id for which to retrieve event history
* `ArgumentsKw`:
  * `reverse`. Boolean. Optional. Traverses events in reverse order of occurrence. 
    The default is to traverse events in order of occurrence.
  * `limit`. Positive integer. Optional. Indicates the maximum number of events to retrieve. Can be used for pagination.
  * `from_time`. RFC3339-formatted timestamp string. Optional. Only include publications occurring at the 
    given timestamp or after (using `>=` comparison).
  * `after_time`. RFC3339-formatted timestamp string. Optional. Only include publications occurring after the 
    given timestamp (using `>` comparison).
  * `before_time`. RFC3339-formatted timestamp string. Optional. Only include publications occurring before the 
    given timestamp (using `<` comparison).
  * `until_time`. RFC3339-formatted timestamp string. Optional. Only include publications occurring before the 
    given timestamp including date itself (using `<=` comparison).
  * `topic`. WAMP URI. Optional. For pattern-based subscriptions, only include publications to 
    the specified topic.
  * `from_publication`. Positive integer. Optional. Events in the results must have occurred at or following the event with the given `publication|id` (includes the event with the given `publication|id` in the results).
  * `after_publication`. Positive integer. Optional. Events in the results must have occurred following the event with the given `publication_id` (excludes the event with the given `publication|id` in the results).
    Useful for pagination: pass the `publication|id` 
    attribute of the last event returned in the previous page of results when navigating in order of occurrence (`reverse` argument absent or false).
  * `before_publication`. Positive integer. Optional. Events in the results must have occurred previously to the event with the given `publication|id` (excludes the event with the given `publication|id` in the results).
    Useful for pagination: pass the `publication|id` 
    attribute of the last event returned in the previous page of results when navigating in reverse order of occurrence (`reverse=true`).
  * `until_publication`. Positive integer. Optional. Events in the results must have occurred at or previously to the event with the given `publication|id` (includes the event with the given `publication|id` in the results).

It is possible to pass multiple options at the same time. In this case they will be treated as conditions with 
logical `AND`. Note that the `publication|id` event attribute is not ordered as it belongs to the Global scope. But since events are
stored in the order they are received by the broker, it is possible to find an event with the specified `publication|id` and then
return events including or excluding the matched one depending on the `*_publication` filter attributes.

The `arguments` payload field returned by the above RPC uses the same schema: an array of `Event` objects containing 
an additional `timestamp` string attribute in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt) format. It can also be an empty array in the case where there were no publications to the 
specified subscription, or all events were filtered out by the specified criteria. Additional general information 
about the query may be returned via the `argumentsKw` payload field.

{align="left"}
```javascript
  [
    {
        "timestamp": "yyyy-MM-ddThh:mm:ss.SSSZ", // string with event date/time in RFC3339 format
        "subscription": 2342423, // The subscription ID of the event
        "publication": 32445235, // The original publication ID of the event
        "details": {},           // The original details of the event
        "args": [],              // The original list arguments payload of the event. May be ommited
        "kwargs": {}             // The original key-value arguments payload of the event. May be ommited
    }
  ]
```

Clients should not rely on timestamps being unique and monotonic. When events occur in quick succession, it's possible for some of them to have the same timestamp. When a router in an IoT system is deployed off-grid and is not synchronized to an NTP server, it's possible for the timestamps to jump backwards when the router's wall clock time or time zone is manually adjusted.

In cases where the events list is too large to send as a single RPC result, router implementations
may provide additional options, such as pagination or returning progressive results.

As the Event History feature operates on `subscription|id`, there can be situations when there are not yet any 
subscribers to a topic of interest, but publications to the topic occur. In this situation, the *Broker* cannot 
predict that events under that topic should be stored. If the *Broker* implementation allows configuration on 
a per-topic basis, it may overcome this situations by preinitializing history-enabled topics with "dummy" 
subscriptions even if there are not yet any real subscribers to those topics.

Sometimes, a client may not be willing to subscribe to a topic just for the purpose of obtaining a subscription id. 
In that case a client may use other [Subscriptions Meta API RPC](#name-procedures-3) for retrieving subscription 
IDs by topic URIs if the router supports it.

**Security Aspects**

TODO/FIXME: This part of Event History needs more discussion and clarification.
But at least provides some basic information to take into account.

In order to request event history, a peer must be allowed to subscribe to a desired subscription first. Thus, if a peer
cannot subscribe to a topic resulting in a subscription, it means that it cannot receive events history for that 
topic either. To sidestep this problem, a peer must be allowed to call related meta procedures for obtaining the 
event history as described above. Prohibited Event History meta procedure calls must fail with the 
`wamp.error.not_authorized` error URI.

Original publications may include additional options, such as `black-white-listing` that triggers special event 
processing. These same rules must also apply to event history requests. For example, if the original publication contains 
`eligible_authrole = 'admin'`, but the request for history came from a peer with `authrole = 'user'`, then even if 
`user` is authorized to subscribe to the topic (and thus is authorized to ask for event history), this publication 
must be filtered out from the results of this specific request, by the router side.

The `black-white-listing` feature also allows the filtering of event delivery on a `session ID` basis. In the context of
event history, this can result in unexpected behaviour: session ids are generated randomly at runtime for every
session establishment, so newly connected sessions asking for event history may receive events that were originally 
excluded, or, vice versa, may not receive expected events due to session ID mismatch. To prevent this unexpected 
behaviour, all events published with `Options.exclude|list[int]` or `Options.eligible|list[int]` should be ignored by 
the Event History mechanism and not be saved at all.

Finally, Event History should only filter according to attributes that do not change during the run time of the router, 
which are currently `authrole` and `authid`. Filtering based on ephemeral attributes like `session ID` – and perhaps 
other future custom attributes – should result in the event not being stored in the history at all, to avoid 
unintentional leaking of event information.
