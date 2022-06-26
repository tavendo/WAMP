## Subscriptions Meta API {#pubsub-sub-metapi}

Within an application, it may be desirable for a publisher to know whether a publication to a specific topic currently makes sense, i.e. whether there are any subscribers who would receive an event based on the publication. It may also be desirable to keep a current count of subscribers to a topic to then be able to filter out any subscribers who are not supposed to receive an event.

Subscription _meta-events_ are fired when topics are first created, when clients subscribe/unsubscribe to them, and when topics are deleted. WAMP allows retrieving information about subscriptions via subscription _meta-procedures_.

Support for this feature MUST be announced by Brokers via

{align="left"}
        HELLO.Details.roles.broker.features.subscription_meta_api|
            bool := true

Meta-events are created by the router itself. This means that the events as well as the data received when calling a meta-procedure can be accorded the same trust level as the router.

The following sections contain an informal, easy to digest description of the WAMP procedures and topics
available in (this part of) the WAMP Meta API.
A formal definition of the WAMP Meta API in terms of available WAMP procedures and topics including
precise and complete type definitions of the application payloads, that is procedure arguments and
results or event payloads is contained in

* Compiled Binary Schema: `<WAMP API Catalog>/schema/wamp-meta.bfbs`
* FlatBuffers Schema Source: `<WAMP API Catalog>/src/wamp-meta.fbs`

which uses FlatBuffers IDL to describe the API. The method of using FlatBuffers IDL and type definitions to formally define WAMP procedures and topics is detailed in section [WAMP IDL](#wamp-idl).

**Feature Announcement**

Support for this feature MUST be announced by a *Brokers* (`role := "nroker"`) via:

{align="left"}
        HELLO.Details.roles.<role>.features.
            subscription_meta_api|bool := true

Here is a `WELCOME` message from a *Router* with support for both the *Broker* and *Dealer* role, and with support for **Subscription Meta API**:

{align="left"}
```json
    [
        2,
        4580268554656113,
        {
            "authid":"OL3AeppwDLXiAAPbqm9IVhnw",
            "authrole": "anonymous",
            "authmethod": "anonymous",
            "roles": {
                "broker": {
                    "features": {
                        "subscription_meta_api": true
                    }
                },
                "dealer": {
                    "features": {
                    }
                }
            }
        }
    ]
```


### Events

A client can subscribe to the following session meta-events, which cover the lifecycle of a subscription:

* `wamp.subscription.on_create`: Fired when a subscription is created through a subscription request for a topic which was previously without subscribers.
* `wamp.subscription.on_subscribe`: Fired when a session is added to a subscription.
* `wamp.subscription.on_unsubscribe`: Fired when a session is removed from a subscription.
* `wamp.subscription.on_delete`: Fired when a subscription is deleted after the last session attached to it has been removed.

A `wamp.subscription.on_subscribe` event MUST always be fired subsequent to a `wamp.subscription.on_create` event, since the first subscribe results in both the creation of the subscription and the addition of a session. Similarly, the `wamp.subscription.on_delete` event MUST always be preceded by a `wamp.subscription.on_unsubscribe` event.

The WAMP subscription meta events shall be dispatched by the router to the same realm as the WAMP session which triggered the event.


#### wamp.subscription.on_create

Fired when a subscription is created through a subscription request for a topic which was previously without subscribers. The event payload consists of positional arguments:

* `session|id`: ID of the session performing the subscription request.
* `SubscriptionDetails|dict`: Information on the created subscription.

**Object Schemas**

{align="left"}
```javascript
      SubscriptionDetails :=
      {
          "id": subscription|id,
          "created": time_created|iso_8601_string,
          "uri": topic|uri,
          "match": match_policy|string
      }
```

See [Pattern-based Subscriptions](#pattern-based-subscriptions) for a description of `match_policy`.


#### wamp.subscription.on_subscribe

Fired when a session is added to a subscription.  The event payload consists of positional arguments:

* `session|id`: ID of the session being added to a subscription.
* `subscription|id`: ID of the subscription to which the session is being added.


#### wamp.subscription.on_unsubscribe

Fired when a session is removed from a subscription. The event payload consists of positional arguments:

* `session|id`: ID of the session being removed from a subscription.
* `subscription|id`: ID of the subscription from which the session is being removed.


#### wamp.subscription.on_delete

Fired when a subscription is deleted after the last session attached to it has been removed. The event payload consists of positional arguments:

* `session|id`: ID of the last session being removed from a subscription.
* `subscription|id`: ID of the subscription being deleted.



### Procedures


A client can actively retrieve information about subscriptions via the following meta-procedures:

- `wamp.subscription.list`: Retrieves subscription IDs listed according to match policies.
- `wamp.subscription.lookup`: Obtains the subscription (if any) managing a topic, according to some match policy.
- `wamp.subscription.match`: Retrieves a list of IDs of subscriptions matching a topic URI, irrespective of match policy.
- `wamp.subscription.get`: Retrieves information on a particular subscription.
- `wamp.subscription.list_subscribers`: Retrieves a list of session IDs for sessions currently attached to the subscription.
- `wamp.subscription.count_subscribers`: Obtains the number of sessions currently attached to the subscription.


#### wamp.subscription.list

Retrieves subscription IDs listed according to match policies.


**Arguments**
- None

**Results**

The result consists of one positional argument:

- `SubscriptionLists|dict`: A dictionary with a list of subscription IDs for each match policy.

**Object Schemas**

{align="left"}
```javascript
      SubscriptionLists :=
      {
          "exact": subscription_ids|list,
          "prefix": subscription_ids|list,
          "wildcard": subscription_ids|list
      }
```

See [Pattern-based Subscriptions](#pattern-based-subscriptions) for information on match policies.


#### wamp.subscription.lookup

Obtains the subscription (if any) managing a topic, according to some match policy.

**Arguments**

- `topic|uri`: The URI of the topic.
- (Optional) `options|dict`: Same options as when subscribing to a topic.

**Results**

The result consists of one positional argument:

- (Nullable) `subscription|id`: The ID of the subscription managing the topic, if found, or null.


#### wamp.subscription.match

Retrieves a list of IDs of subscriptions matching a topic URI, irrespective of match policy.

**Arguments**

- `topic|uri`: The topic to match.

**Results**

The result consists of positional arguments:

- (Nullable) `subscription_ids|list`: A list of all matching subscription IDs, or null.


#### wamp.subscription.get

Retrieves information on a particular subscription.

**Arguments**

- `subscription|id`: The ID of the subscription to retrieve.

**Results**

The result consists of one positional argument:

- `SubscriptionDetails|dict`: Details on the subscription.

**Error URIs**

- `wamp.error.no_such_subscription`: No subscription with the given ID exists on the router.

**Object Schemas**

{align="left"}
```javascript
      SubscriptionDetails :=
      {
          "id": subscription|id,
          "created": time_created|iso_8601_string,
          "uri": topic|uri,
          "match": match_policy|string
      }
```

See [Pattern-based Subscriptions](#pattern-based-subscriptions) for information on match policies.


#### wamp.subscription.list_subscribers

Retrieves a list of session IDs for sessions currently attached to the subscription.

**Arguments**
- `subscription|id`: The ID of the subscription to get subscribers for.

**Results**

The result consists of positional arguments:

- `subscribers_ids|list`: A list of WAMP session IDs of subscribers currently attached to the subscription.

**Error URIs**

- `wamp.error.no_such_subscription`: No subscription with the given ID exists on the router.


#### wamp.subscription.count_subscribers

Obtains the number of sessions currently attached to a subscription.

**Arguments**

- `subscription|id`: The ID of the subscription to get the number of subscribers for.

**Results**

The result consists of one positional argument:

- `count|int`: The number of sessions currently attached to a subscription.

**Error URIs**

- `wamp.error.no_such_subscription`: No subscription with the given ID exists on the router.
