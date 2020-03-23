+++
title = "0. Introduction"
date = 2020-03-14
reading_time = 50
+++

Before diving into the problems and start throwing code at it, let me tell you about the structure of the project, the goals and how things are supposed to work around here.
<!-- more -->
||
|-|
# Goal
Learn a more about [RxSwift](https://github.com/ReactiveX/RxSwift) by building a _different_ kind of sample app based on [Swift](https://developer.apple.com/swift/) and [SwiftUI](https://github.com/ReactiveX/RxSwift) using [Xcode](https://github.com/ReactiveX/RxSwift).

||
|-|
# Motivation
I find myself learning about new things that can be achieved with RxSwift by reading other people's code, never by reading posts about how `map` or `flatMap` works.  
Maybe I lack the imagination necessary to translate all those marble diagrams and fake static number generators nobody use into "_real world_" problems, maybe it just that's not the way I learn, or you know, maybe I haven't tried hard enough.

Anyway I decided to start tinkering with RxSwift a little more, I googled and asked on twitter ([here](https://twitter.com/dev_jac/status/1230657972470075392)), I found the usual books, [RxSwift: Reactive Programming with Swift](https://store.raywenderlich.com/products/rxswift), talks like the ones at [Realm Academy](https://academy.realm.io/posts/learning-path-rxswift-from-start-to-finish/) and tutorials which usually cover individual aspects like operators and always using those damn marbles 🙄  
After some time I decided the best was to create a dummy app and play with it, but what kind of app? Most of the apps one can build for tinkering are passive, meaning you find a free service that returns some fancy data, like [Open Weather Map](https://openweathermap.org/api), you fetch it and render it nicely, and that's it. What kind of "Reactive" stuff can be built around a bunch of GET HTTP calls?

If you are lucky you might find a since open API that also includes some POST and PUT HTTP calls (like [The Movie Database API](https://developers.themoviedb.org/3/account/mark-as-favorite)) but still, is not very reactive and also kinda limiting if you want to explore other concepts like unit testing or if you want to tinker in a reactive but repetitive way that let you try different approaches for the same situation.

As I wrote on my [twitter bio](https://twitter.com/dev_jac) a long time ago, "_If it doesn't exist I'll make it_".

Initially, I started building it just for myself and it was never intended to be shared so let me warn you, it is going to be rough around the edges… and sometimes on the middle, top, bottom, front and rear too 😅.

I decided to share it because in the same way you might [figure out a bug while explaining it to a rubber duck 🦆](https://en.wikipedia.org/wiki/Rubber_duck_debugging) explaining something you think you understand to someone else also helps you understand it better yourself.

Also, I thought this whole blogging thing was going to be easier, but so far is torture! ☠️

Without more preamble let's discuss the technology stack.

||
|-|
# Technology

As I mentioned before, we will be using the bundle versions of [Swift](https://developer.apple.com/swift/) and [SwiftUI](https://github.com/ReactiveX/RxSwift) that comes with [Xcode](https://github.com/ReactiveX/RxSwift) (right now it is 11.4 beta 3 (11N132i))

The project has 2 dependencies:
1. RxSwift [5.1.0](https://github.com/ReactiveX/RxSwift).
2. FakeService, a toy Swift framework built for this project.

We will integrate RxSwift using [Swift Package manager](https://swift.org/package-manager/).  
**FakeService** is be pre-loaded and configured on the sample project.

The objective of this project is to explore the capabilities of RxSwift and try to build complex/funny contractions with it, SwiftUI and Swift Package manager where chosen because those require less explanation and setup than the alternatives, I believe they are a good fit for this project.  
I'm not advocating for those technologies in particular over their alternatives.


**You shouldn't treat the published code as production-ready nor it is written with best practices in mind, instead brevity and simplicity are prioritized to avoid distracting the reader from the main goal, have fun with RxSwift.**

Every episode has a companion folder on the repo that contains the code as at the beginning (the `before` folder) and as at the end on the episode (yes, the `after` folder).

||
|-|
# A _different_ sample app 
As I ranted before, most tutorials or sample apps are too simple or far from the "real" world, what makes this sample app different from others is the **FakeService** framework, nothing more than a simple service mock.  
I'm shipping the source code so you can see it doesn't contain any magic (or good coding practices 😁)

This framework impersonates our fictitious company backend, this way we don't have to work with boring data or install fancy software to deal with the 4096 dependencies from the other fancy software used to run a different fancy software just to have some fun data to play with, plus it comes with some handy Mock functionality to control time for example.

The framework comes with pre-recorded activity, exposes some "endpoints" and responds to it as a server would do, for simplicity first episodes contain a simpler version of it but more functionality is made available as episodes progress (if I ever publish them that is)

# Topics
The main topic of the blog is RxSwift and trying to find ways to leverage it's power while trying not to paint ourselves into a corner. We will also cover some details on SwiftUI required to build the sample app. I also cover some topics in regards to Unit testing usually at the end of the episodes.

Anyway thank you for reading all this impenetrable wall of text and I hope you enjoy the project, feel free to drop me a comment on twitter.

- [@dev_jac](https://twitter.com/dev_jac)