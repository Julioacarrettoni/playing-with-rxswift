+++
title = "2. The Single sad path 🐞"
date = 2020-03-15
+++
Now that the endpoint is wrapped in a [Single](https://github.com/ReactiveX/RxSwift/blob/master/Documentation/Traits.md#single) and works nicely on the "happy path", it's time to start working on handling those error scenarios and preventing future bugs (unit tests).

**[Skip intro](#skip_intro)**
<!-- more -->
# Background story
Thomson Brothers Division might be a medium company with some old technological stack but that doesn't mean they do things wrong, the company has some modern process in place to ensure a minimum level of code quality, for example they do Agile software development<sup>[1](#1)</sup> which as many of us know already it probably means someone read a fancy post on LinkedIn from a consultant trying to sell their services as an Agile facilitator and though "_This looks nice, and I don't need to pay any consultant to tell me how to run my team, I'll just follow the first 3 chapters of this book, most of it doesn't apply to us anyway_" <sup>[2](#2)</sup> and thus "_Agile TBD development process_" was born (pun intended). They should have hired the consultant, is would have been cheaper on the long run…  

Anyway as a result to that, one thing let to another and the company ended up adopting and _adapting_ _"git flow"_<sup>[3](#3)</sup>, so now you have to create a "_pull request_"<sup>[3](#3)</sup> into the master branch from your refactor branch.  
By following the company docs you have to complete a checklist in the description of you pull request, some of which are:
- Considers edge cases and non-happy paths
- Handle errors
  - Recover from errors gracefully
  - Logs errors.
- Introduces new unit tests

Without this the pull request will be rejected.

On the previous post I intentionally avoided those for the sake of simplicity as the post was getting a little to long. Now is time to pay the debt.  
Not every pull request has to introduce new unit tests, as I said on the previous post, there was not much to test as it was a refactor, now that we are about to improve the error handling and the user experience that might change.

||
|-|
# Work {#skip_intro}
### Goal
Fix any issues (bugs, bad user experience) the app might have when working under non-ideal conditions by completing each of the items in this list:
- Considers edge cases and non-happy paths
- Handle errors
  - Recover from errors gracefully
  - Log errors.
- Introduces new unit tests
&nbsp;  
&nbsp;  
&nbsp;  
### Code
You will need Xcode 11.4 or newer.

You can download the sample apps from [here](https://github.com/Julioacarrettoni/playing-with-rxswift/tree/master/002), you should start working on the _before_ folder, at the end it should look like the _after_ folder.
&nbsp;  
&nbsp;  
&nbsp;  
#### Considers edge cases and non-happy paths

Open the `RxPlaying.xcodeproj` project. The RxPlaying targets has no changes from the previous post but the FakeService framework has received some small updates for this post, in particular the [Environment](https://github.com/Julioacarrettoni/playing-with-rxswift/blob/master/002/Before/FakeService/FakeServices.swift#L3-L11) struct received a new member:
```Swift
public var failNext: () -> Bool
```
Returning `true` in this closure makes the next request fail. For now there is no granular control on any on any of the closures as we only have a single endpoint.  
We will use this to simulate bad networks when combined with the existing `delay` member.  
In real life advanced network stacks provide with mock functionality else you can always simulate bad network conditions on your iPhone or your simulator without having to turn airplane mode on or turning off the Wi-Fi, [here](https://www.natashatherobot.com/simulate-bad-network-ios-simulator/) is a nice post by [NatashaTheRobot](https://twitter.com/natashatherobot) for reference.

Add this method anywhere on [Service.swift](https://github.com/Julioacarrettoni/playing-with-rxswift/blob/master/002/Before/RxPlaying/Services/Service.swift#L5) inside the `Service` struct.
```Swift
static func overrideNetworkMock() {
    var failures = [false, true]
    FakeService.Current.failNext = {
        let next = failures.removeFirst()
        failures.append(next)
        return next
    }
}
```
Every time the closure gets invoked we return the first value on the `failures` array and push it to the back. It cycles through all the values of the array.

Now we need to call this method once, a good place for now is [here](https://github.com/Julioacarrettoni/playing-with-rxswift/blob/master/002/Before/RxPlaying/SceneDelegate.swift#L12) in the `SceneDelegate.swift` file.

If you run the app half the requests will "fail" and it will look like this:
<div align="center"><img src="../../003_gif_01.gif" alt="GIF animation of the app where icons blink"></div>

Every time the request fails a `nil` is returned and blindly forwarded to the `MapView` View
```Swift
.subscribe(onSuccess: { globalState in
    self.globalState = globalState
    self.refreshData()
})
```

The internal implementation of the `MapView` tries to animates annotation transitions and it fades out annotations that are removed an fading in annotations that are added. As a result we fades out all annotations when the request fails as we are removing all of them bu setting a `globalState` with `nil` value and then it fades in all the annotations when a new value of `globalState` is received.

We can "patch" this issue in several places, starting with the bug on the `MapView` when fading in annotations due to view recycling, but for now we will ignore that as is not our main concern.  
We can be tempted to do something like:
```Swift
.subscribe(onSuccess: { globalState in
	if let globalState = globalState {
        self.globalState = globalState
    }

    self.refreshData()
})
```
And that will certainly fix the issue, but the proper "fix" is to start doing some real error handling and separating concerns.  
We will see soon that this not only fixes the problem but also enables us to do more while keeping everything clean and separated.
&nbsp;  
&nbsp;  
&nbsp;  
#### Handle errors, recover from errors gracefully

Let's take a look back at our current implementation of the "reactive" endpoint:
```Swift
static func getSystemState() -> Single<GlobalState?> {
    Single<GlobalState?>.create { single in
        FakeServices.shared.getSystemState { globalState in
            single(.success(globalState))
        }
        
        return Disposables.create()
    }
}
```

To be honest, `FakeService` doesn't really helps us as it doesn't return any error, is just return a value or `nil`<sup>[2](#2)</sup>, I hope that whatever network stack you have at work in real life is a little more cooperative than this one 😁.

Let's concentrate on the "body" of our Single:
```Swift
FakeServices.shared.getSystemState { globalState in
    single(.success(globalState))
}
```

We want to only return `.success` if we have a value, an error otherwise.
```Swift
FakeServices.shared.getSystemState { globalState in
    if let globalState = globalState {
        single(.success(globalState))
    } else {
        single(.error( ?????????????? ))
    }
}
```

Ok, we need an error first, let's start by creating one inside `Service.swift`, an easy way is to use an `enum` with lots of descriptive cases and some `vars` for stuff like description, analytics etc, but again we don't have much to work with given the current state of `FakeService`, this is as far as we can go (for now).
```Swift
enum GetSystemStateError: Error {
    case unknown
}
```

Now the end result for the body is:

```Swift
FakeServices.shared.getSystemState { globalState in
    if let globalState = globalState {
        single(.success(globalState))
    } else {
        single(.error(GetSystemStateError.unknown))
    }
}
```

Let's look at it, it is still easy to read and descriptive, plus now it is explicit that not getting a value from `FakeServices.shared.getSystemState` is considered an error.  
Furthermore we can now change the whole method and get ride of the optionals:
```Swift
static func getSystemState() -> Single<GlobalState> {
    Single<GlobalState>.create { single in
        // Body
    }
}
```

This will simplify `ContentView` as we no longer have to wonder about what we do and what does it means for the Single to return a `nil`.

If we run the app now, it won't blink anymore, but also it won't do anything else that rendering a single service call.  
The problem is that our current precarious polling system relies on `ContentView.refreshData` to call itself at the end and when it fails it doesn't retry as we are not currently handling the error cases.  
Let's take a look at it:
```Swift
private func refreshData() {
    Service.getSystemState()
        .subscribe(onSuccess: { globalState in
            self.globalState = globalState
            self.refreshData()
        })
        .disposed(by: self.disposeBag)
}
```

The subscribe method has another argument that we are currently ignoring in our naive usage of the reactive API, `onError`, let's use it:
```Swift
Service.systemSingle
    .subscribe(onSuccess: { globalState in
        self.globalState = globalState
        self.refreshData()
    }, onError: { _ in
        self.refreshData()
    })
    .disposed(by: self.disposeBag)
```

Now if you run the application it will look nice as before even if every other request fails, furthermore we have a nice separation between the happy path and the sad path. As a reminder we have other `subscribe` options that were discussed on the previous post [here](@/post_001.md#subscribe_section).

Now it seems we have covered the "handle errors gracefully" section, **spoiler alert**, we haven't, what we won't notice until a little later in the post.
&nbsp;  
&nbsp;  

||
|-|
### Intermission
[Skip intermission](#skip_intermission)
Before continuing talking about logging and testability there is something I would like to show you, on the previous post ([here](@/post_001.md#multiple)) I mentioned that we can re-use the same single multiple times, so why use a method? why are we re-creating the same Instance over an over again? I mean is not like is a huge performance boost, plus "_[…] premature optimization is the root of all evil (or at least most of it) in programming._"<sup>[5](#5)</sup> Donald Knuth.  
Still this is the right thing to do plus 0.001% over time compounds and 🦆 our application's performance.  
What we can do is to use a static variable we only creates once:
```Swift
static var systemSingle: Single<GlobalState> = {
    Single<GlobalState>.create { single in
    	// Body
        return Disposables.create()
    }
}()
```

That we can reuse directly:
```Swift
private func refreshData() {
    Service.systemSingle
        .subscribe(onSuccess: { globalState in
            // Body
        )
        .disposed(by: self.disposeBag)
}
```

If you don't believe me (I don't blame you, and you shouldn't to be honest) you can try it yourself and add a print line here (and also a `return`)
```Swift
static var systemSingle: Single<GlobalState> = {
	print("Creating the single one single time.")
    return Single<GlobalState>.create { single in
```

Now the app works just as before and we just gained little performance boost… maybe?.

Now back to our regular programing...
&nbsp;  
&nbsp;  

||
|-|
#### Handle errors, Log errors. {#skip_intermission}

Let's log some errors on the client, for simplicity our logs (for now) will be just printing to the console AKA "poor man's debugger".  
And straight forward change could be:
```Swift
onError: { error in
    print("[\(#function)] ❌ request error: \(error)")
    self.refreshData()
})
```

Right now this feels like enough as we only use the endpoint in a single place, but it would be good to have the logging at the endpoint level too, then we can see how often and endpoint fails and also if we use it in different parts of our app which one is more affected.

We might be tempted to modify the body of our single and log the error in the same place where we are creating it:
```Swift
FakeServices.shared.getSystemState { globalState in
    if let globalState = globalState {
        single(.success(globalState))
    } else {
    	// Not good enough 
    	let error = GetSystemStateError.unknown
    	print("[\(#function)] ❌ request error: \(error)")
        single(.error(error))
    }
}
```

But there is a better way, an RxWay. All observables have a very useful operator called [do](https://github.com/ReactiveX/RxSwift/blob/70b8a33c5c3f4c3b15ebf10b638d2b15cfafb814/RxSwift/Traits/Single.swift#L157-L170), and this one is a big one:
> Invokes an action for each event in the observable sequence, and propagates all observer messages through the result sequence.  
>
> seealso: [do operator on reactivex.io](http://reactivex.io/documentation/operators/do.html)  
>
> · **onSuccess**: Action to invoke for each element in the observable sequence.  
> · **afterSuccess**: Action to invoke for each element after the observable has passed an onNext event along to its downstream.  
> · **onError**: Action to invoke upon errored termination of the observable sequence.  
> · **afterError**: Action to invoke after errored termination of the observable sequence.  
> · **onSubscribe**: Action to invoke before subscribing to source observable sequence.  
> · **onSubscribed**: Action to invoke after subscribing to source observable sequence.  
> · **onDispose**: Action to invoke after subscription to source observable has been disposed for any reason. It can be either because sequence terminates for some reason or observer subscription being disposed.  
>
> **returns**: The source sequence with the side-effecting behavior applied.  

This operator should not be confused with [map](https://github.com/ReactiveX/RxSwift/blob/70b8a33c5c3f4c3b15ebf10b638d2b15cfafb814/RxSwift/Traits/Single.swift#L203-L208) or any of it's variants as this method does not modifies the stream in any way, that's what "_[…]and propagates all observer messages through the result sequence_" means. Also as you can see it has a lot of options to "hook into", this makes [do](https://github.com/ReactiveX/RxSwift/blob/70b8a33c5c3f4c3b15ebf10b638d2b15cfafb814/RxSwift/Traits/Single.swift#L157-L170) great for logging and also debugging your code, by the way there is a [debug](https://github.com/ReactiveX/RxSwift/blob/6b2a406b928cc7970874dcaed0ab18e7265e41ef/RxSwift/Observables/Debug.swift#L23) operator as well.

Now we can add this at the end of our Single definition and we will be effortlessly "logging" all results from it.

```Swift
.do(onSuccess: { _ in
    print("[\(#function)] ✅ Success")
}, onError: { error in
    print("[\(#function)] ❌ request error: \(error)")
})
```

This is the output of the console now:  
> [Service] ✅ Success  
[Service] ❌ request error: unknown  
[refreshData()] ❌ request error: unknown  
[Service] ✅ Success  
[Service] ❌ request error: unknown  
[refreshData()] ❌ request error: unknown  
[Service] ✅ Success  
[Service] ❌ request error: unknown  
[refreshData()] ❌ request error: unknown  

&nbsp;  
&nbsp;  
&nbsp;  
# Conclusion
&nbsp;  
&nbsp;  
&nbsp;  
##### Footnotes
<a id='1'>1</a>: [Wikipedia.org](https://en.wikipedia.org/wiki/Agile_software_development) Agile software development.  
<a id='2'>2</a>: If this story hits close to home, please accept my condolences.  
<a id='3'>3</a>: [Nvie.com](https://nvie.com/posts/a-successful-git-branching-model/) "_A successful Git branching model_" By Vincent Driessen.  
<a id='4'>4</a>: [Help.github.com](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests) "_About pull requests_".  
<a id='5'>5</a>: [Wikiquote.org](https://en.wikiquote.org/wiki/Donald_Knuth) Donald Knuth.  