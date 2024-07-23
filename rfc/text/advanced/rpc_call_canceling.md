## Call Canceling {#rpc-call-canceling}

A *Caller* might want to actively cancel a call that was issued, but not has yet returned. An example where this is useful could be a user triggering a long running operation and later changing his mind or no longer willing to wait.

**Feature Announcement**

Support for this feature MUST be announced by *Callers* (`role := "caller"`), *Callees* (`role := "callee"`) and *Dealers* (`role := "dealer"`) via

{align="left"}
        HELLO.Details.roles.<role>.features.call_canceling|bool := true

**Message Flow**

The message flow between *Callers*, a *Dealer* and *Callees* for canceling remote procedure calls involves the following messages:

 * `CANCEL`
 * `INTERRUPT`
 * `ERROR`

A call may be canceled at the *Callee* or at the *Dealer* side. Cancellation behaves differently depending on the mode:

* **skip**: The pending call is canceled and `ERROR` is sent immediately back to the caller. No `INTERRUPT` is sent to the callee and the result is discarded when received.
* **kill**: `INTERRUPT` is sent to the callee, but `ERROR` is not returned to the caller until after the callee has responded to the canceled call. In this case the caller may receive `RESULT` or `ERROR` depending whether the callee finishes processing the invocation or the interrupt first.
* **killnowait**: The pending call is canceled and `ERROR` is sent immediately back to the caller. `INTERRUPT` is sent to the callee and any response to the invocation or interrupt from the callee is discarded when received.

If the callee does not support call canceling, then behavior is **skip**.

Message flow during call canceling when *Callee* supports this feature and mode is `kill`

{align="left"}
        ,------.          ,------.          ,------.
        |Caller|          |Dealer|          |Callee|
        `--+---'          `--+---'          `--+---'
           |       CALL      |                 |
           | ---------------->                 |
           |                 |                 |
           |                 |    INVOCATION   |
           |                 | ---------------->
           |                 |                 |
           |      CANCEL     |                 |
           | ---------------->                 |
           |                 |                 |
           |                 |    INTERRUPT    |
           |                 | ---------------->
           |                 |                 |
           |                 |      ERROR      |
           |                 | <----------------
           |                 |                 |
           |      ERROR      |                 |
           | <----------------                 |
        ,--+---.          ,--+---.          ,--+---.
        |Caller|          |Dealer|          |Callee|
        `------'          `------'          `------'


Message flow during call canceling when *Callee* does not support this feature or mode is `skip`

{align="left"}
        ,------.          ,------.            ,------.
        |Caller|          |Dealer|            |Callee|
        `--+---'          `--+---'            `--+---'
           |       CALL      |                   |
           | ---------------->                   |
           |                 |                   |
           |                 |    INVOCATION     |
           |                 | ----------------> |
           |                 |                   |
           |      CANCEL     |                   |
           | ---------------->                   |
           |                 |                   |
           |      ERROR      |                   |
           | <----------------                   |
           |                 |                   |
           |                 |  YIELD (skipped)  |
           |                 | <---------------- |
           |                 |                   |
           |                 | or ERROR (skipped)|
           |                 | <-----------------
        ,--+---.          ,--+---.            ,--+---.
        |Caller|          |Dealer|            |Callee|
        `------'          `------'            `------'


Message flow during call canceling when *Callee* supports this feature and mode is `killnowait`

{align="left"}
        ,------.          ,------.          ,------.
        |Caller|          |Dealer|          |Callee|
        `--+---'          `--+---'          `--+---'
           |       CALL      |                 |
           | ---------------->                 |
           |                 |                 |
           |                 |    INVOCATION   |
           |                 | ---------------->
           |                 |                 |
           |      CANCEL     |                 |
           | ---------------->                 |
           |                 |                 |
           |      ERROR      |                 |
           | <----------------                 |
           |                 |    INTERRUPT    |
           |                 | ---------------->
           |                 |                 |
        ,--+---.          ,--+---.          ,--+---.
        |Caller|          |Dealer|          |Callee|
        `------'          `------'          `------'


A *Caller* cancels a remote procedure call initiated (but not yet finished) by sending a `CANCEL` message to the *Dealer*:

{align="left"}
        [CANCEL, CALL.Request|id, Options|dict]

A *Dealer* cancels an invocation of an endpoint initiated (but not yet finished) by sending a `INTERRUPT` message to the *Callee*:

{align="left"}
        [INTERRUPT, INVOCATION.Request|id, Options|dict]

Options:

{align="left"}
        CANCEL.Options.mode|string == "skip" | "kill" | "killnowait"

**Ignoring Results after Cancel**

After the *Dealer* sends an `INTERRUPT` when mode="killnowait", any responses from the *Callee* are ignored.  This means that it is not necessary for the *Callee* to respond with an `ERROR` message, when mode="killnowait", since the *Dealer* ignores it.
