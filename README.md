> This project has been archived and is superseded by two separate libraries: [https://github.com/laserpants/elm-update-pipeline](aserpants/elm-update-pipeline) and [https://github.com/laserpants/elm-recipes](laserpants/elm-recipes)
     

# Elm Burrito Update

[![Build Status](https://img.shields.io/travis/laserpants/elm-burrito-update/master.svg?style=flat)](https://travis-ci.org/laserpants/elm-burrito-update)
[![Version](https://img.shields.io/badge/elm--version-0.19-blue.svg?colorB=ff69b4)](http://elm-lang.org/)

![Logo](https://raw.githubusercontent.com/laserpants/elm-burrito-update/master/logo.png)

> This project brings together some conventions and idioms that help you write modular and scalable Elm applications; and provides a convenient programming interface to support those ideas.

## Installation

To use this library in your project you need to install it (just like any other Elm package) using the command:

```
elm install laserpants/elm-burrito-update
```

## Appetizer

To get a flavor of what this library is all about, the following code snippets are from the [example single-page application](#a-complete-application-example).
At this point, it may not be so clear, but keep reading&hellip;

```elm
-- Page/Login.elm

{- line 26 -}
type alias State =
    { api : Api.Model Session
    , form : LoginForm.Model
    }

{- line 89 -}
update : Msg -> { onAuthResponse : Maybe Session -> a } -> StateUpdate a
update msg { onAuthResponse } =
    let
        handleApiResponse maybeSession =
            inLoginForm Form.reset
                >> andApply (onAuthResponse maybeSession)

        handleError _ =
            handleApiResponse Nothing
    in
    case msg of
        ApiMsg apiMsg ->
            inAuthApi
                (Api.update apiMsg
                    { onSuccess = \session -> handleApiResponse (Just session)
                    , onError = handleError
                    }
                )

        FormMsg formMsg ->
            inLoginForm (Form.update formMsg { onSubmit = handleSubmit })

-- App.elm

{- line 262 -}
handleAuthResponse : Maybe Session -> StateUpdate a
handleAuthResponse maybeSession =
    let
        authenticated =
            Maybe.isJust maybeSession
    in
    setSession maybeSession
        >> andThen (updateSessionStorage maybeSession)
        >> andIf authenticated returnToRestrictedUrl

{- line 319 -}
    inPage LoginPageMsg LoginPage
        (LoginPage.update loginPageMsg
            { onAuthResponse = handleAuthResponse }
            loginPageState
        )
```

## Getting started

For a start, there are four concepts to wrap one’s head (or tortilla) around.

1. [The Update type](#the-update-type)
2. [Monadic sequencing](#monadic-sequencing)
3. [Managing nested state](#managing-nested-state)
4. [Callbacks](#callbacks)

> Note that in the following, *state* is sometimes used to refer to (what the Elm architecture calls) a *model*, and that these two terms are used, more or less, interchangeably.

### The Update type

A standard Elm program has the following structure:

```elm
import Browser exposing (Document, document)
import Html exposing (..)
import Html.Events exposing (..)

type Msg
    = Bork
    | ...

type alias Model =
    { ...
    }

init : Flags -> ( Model, Cmd Msg )
init = ...

update : Msg -> Model -> ( Model, Cmd Msg )
update = ...

view : Model -> Document Msg
view = ...

main =
    document
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }
```

The Burrito equivalent of this code looks like this:

```elm
import Browser exposing (Document)                 -- [1]
import Burrito.Update.Browser exposing (document)  -- [2]
import Burrito.Update exposing (Update)            -- [3]
import Html exposing (..)
import Html.Events exposing (..)

type Msg
    = Bork
    | ...

type alias Model =
    { ...
    }

init : Flags -> Update Model Msg a                 -- [4]
init = ...

update : Msg -> Model -> Update Model Msg a        -- [5]
update = ...

view : Model -> Document Msg
view = ...

main =                                             -- [6]
    document
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }
```

The main takeaway here is that `Update` is as a type alias for the usual `( Model, Cmd Msg )` tuple. However, as the extra `a` type parameter suggests, there is a bit more going on. More about this in due time.

Let’s go through the changes from the original code:

1. Only `Document` is imported from the `Browser` module.
2. Import `document` from `Burrito.Update.Browser` instead.
3. Import (for now) `Update` from `Burrito.Update`.
4. In `init`, instead of the usual tuple, we return `Update Model Msg a`.
5. The return type of `update` is also `Update Model Msg a`.
6. Finally, the `main` function looks like in the original program, but note that `document` here refers to `Burrito.Update.Browser.document`.

#### Program setup

The functions `application` and `document`, exposed by the `Burrito.Update.Browser` module, serve as drop-in replacements for their counterparts in Elm core, but instead create a `Program` where `init` and `update` are compatible with this library.
See the [documentation](https://package.elm-lang.org/packages/laserpants/elm-burrito-update/latest/Burrito-Update-Browser) for more details.

### Monadic sequencing

The next convention we will adopt is to chain together updates using the reverse function application (also known as *pipe*) operator `|>`.
If you are using the `update-extra` package, you’re probably already familiar with this idea.
Consider the following example, in plain Elm:

```elm
showToast : Toast -> Model -> ( Model, Cmd Msg )
showToast toast model =
    let
        dismissToastTask =
            always (DismissToast model.counter)
    in
    ( { model
          | toast = toast
          , counter = model.counter + 1
      }
    , Task.perform dismissToastTask (Process.sleep 4000)
    )
```

The Burrito equivalent of the above looks like this:

```elm
setToast : Toast -> Model -> Update Model Msg a
setToast toast model =
    save { model | toast = toast }

incrementCounter : Model -> Update Model Msg a
incrementCounter model =
    save { model | counter = model.counter + 1 }

showToast : Toast -> Model -> Update Model Msg a
showToast toast model =
    let
        dismissToastTask =
            always (DismissToast model.counter)
    in
    model
        |> setToast toast
        |> andAddCmd (Task.perform dismissToastTask (Process.sleep 4000))
        |> andThen incrementCounter
```

We use `save` to create an `Update` without any commands. For instance,

```elm
update msg model =
    save model
```

&hellip; corresponds to:

```elm
update msg model =
    ( model, Cmd.none )
```

> The `Update` type is actually a 3-tuple, where the third component is used to store a list of *callbacks*. This feature is explained later in this document.

Functions of the form `something -> Model -> Update Model Msg a` are a recurring pattern in this style of code.
They are known as *monadic* functions (subject to some laws), and to compose these we use the pipe operator together with `andThen`:

```elm
update msg model =
    case msg of
        SomeMsg someMsg ->
            model
                |> doSomethingWith someMsg
                |> andThen doSomethingElse
                |> andThen (addCmd someCmd)  -- or andAddCmd someCmd
                |> andThen (setAllDone True)
```

#### Aside

For brevity, and for reasons which will become apparent later on, the following type alias is also useful in some cases:

```elm
type alias ModelUpdate a =
    Model -> Update Model Msg a

update : Msg -> ModelUpdate a
update = ...
```

### Update API

Many of the functions in `Burrito.Update`; like `andThen`, `map`, `map2`, `map3`, &hellip;, `map7`, and `andMap`; have semantics that resemble those of functions with identical names available in other Elm libraries written in the same style.

#### map

As usual, `map` applies a function to the state (model) portion of an `Update`.

```elm
> (save 2) == map ((+) 1) (save 1)
True
```

#### andThen

This function binds together updates.
For example, if we have two functions `doSomething : Model -> Update Model Msg a` and `doStuffTimes : Int -> Model -> Update Model Msg a`, we can compose these, like so:

```elm
save model
    |> andThen doSomething
    |> andThen (doStuffTimes 3)
```

#### Applicative interface

The functions `map2`, `map3`, etc. address the need to map over functions having more than one argument.

```elm
> (save 42) == map2 (+) (save 5) (save 37)
True
```

If you want to map over functions with more than 7 arguments, you need `andMap`.

For more detailed information, see the [documentation](https://package.elm-lang.org/packages/laserpants/elm-burrito-update/latest/Burrito-Update).

### Managing nested state

In larger applications, we often end up with a hierarchy of models.
The next topic on our list is how to update this kind of nested state.
In the following example, the `Api` module is responsible for fetching posts from a remote API.

```elm
type alias Posts =
    List Post

type Msg
    = ApiMsg (Api.Msg Posts)

type alias Model =
    { posts : Api.Model Posts
    }

update : Msg -> Model -> Update Model Msg a
update msg model =
    case msg of
        ApiMsg apiMsg ->
            Api.update apiMsg model.posts  -- Fail!
```

The idea here is simply that `update` calls `Api.update` to update the `Api` model. But this doesn’t quite work. `Api.update` has this type:

```elm
update : Api.Msg Posts -> Api.Model Posts -> Update (Api.Model Posts) (Api.Msg Posts) a
```

We need to do three things here:

1. Update the `Api.Model`.
2. Insert it back into the parent `Model`.
3. Lift the `Api.Msg Posts` to a `Msg`.

Using the tools we have assembled, this can be devised as an update pipeline:

```elm
update : Msg -> Model -> Update Model Msg a
update msg model =
    case msg of
        ApiMsg apiMsg ->
            model.posts
                |> Api.update apiMsg
                |> andThen (\posts -> save { model | posts = posts })
                |> mapCmd ApiMsg
```

The last line (`mapCmd`) is analogous to:

```elm
\( model, cmd ) -> ( model, Cmd.map ApiMsg cmd )
```

Since this is mostly boilerplate, it makes sense to factor out some of it and invent two new functions in the process:

```elm
insertAsPostsIn : Model -> Api.Model Posts -> Update Model Msg a
insertAsPostsIn model posts =
    save { model | posts = posts }

inPostsApi : Api.ModelUpdate Posts a -> Model -> Update Model Msg a
inPostsApi doUpdate model =
    model.posts
        |> doUpdate
        |> andThen (insertAsPostsIn model)
        |> mapCmd ApiMsg

update : Msg -> Model -> Update Model Msg a
update msg model =
    case msg of
        ApiMsg apiMsg ->
            model
                |> inPostsApi (Api.update apiMsg)
```

The `inPostsApi` function now takes care of the wrapping, unwrapping, and mapping.
Note that it can be used from any function in our code that returns an `Update Model Msg a`.

Without the `ModelUpdate` helper (explained earlier), the type signature for `inPostsApi` would have been a lot more complicated:

```elm
inPostsApi : (Api.Model Posts -> Update (Api.Model Posts) (Api.Msg Posts) a) -> Model -> Update Model Msg a
```

### Callbacks

We will continue building on the previous example.
At some point, the `Api` module sends a request to fetch a collection of posts from the API.
When the request is complete, a `Result` is returned with either a list of posts, or an error message.
A natural next step is for this information to be passed *up* in the state hierarchy, to give the parent model a chance to update itself (and its other children) based on the response.
We can visualize this through the following diagram:

```
        ┌──────────┐
        │  update  │
        └───┬─ ▲ ──┘
            │  │
    ApiMsg ─│  │── onSuccess
            │  │──── onError
            │  │
       ┌─── ▼ ─┴────┐
       │ Api.update │
       └────────────┘
```

The main idea here is to add an extra argument to the `Api.update` call, with a record of *callbacks* that are invoked when something interesting happens.
As you can see, these callbacks have the type `something -> Model -> Update Model Msg a`, which means that we can do anything we want with the parent model in these functions.
After a successful authentication attempt, for example, you may want to take the user to a different URL.

```elm
handleSuccess : List Post -> Model -> Update Model Msg a
handleSuccess = ...

handleError : Http.Error -> Model -> Update Model Msg a
handleError = ...

update : Msg -> Model -> Update Model Msg a
update msg model =
    case msg of
        ApiMsg apiMsg ->
            model
                |> inPostsApi
                      (Api.update apiMsg
                          { onSuccess = handleSuccess
                          , onError = handleError
                          }
                      )
```

The callbacks are then “invoked” from within `Api.update` using the `apply` function from `Burrito.Update`.
The code looks something like this:

```elm
update msg { onSuccess, onError } model =
    case msg of
        Response (Ok resource) ->
            model
                |> setResource (Available resource)
                |> andThen (apply (onSuccess resource))

        Response (Err error) ->
            model
                |> setResource (Error error)
                |> andThen (apply (onError error))
```

> <b>Tip:</b> As a shortcut, you can also write `andApply (onEvent foo)` instead of `andThen (apply (onEvent foo))`.

There is one more step.
When `apply` is called, it just adds a partially applied function to a list of handlers. This list is the mysterious third component of the `Update` tuple.
Here is how `Update` is defined:

```elm
type alias Update a msg t =
    ( a, List (Cmd msg), List t )
```

So the `t` parameter gets instantianted as `Model -> Update Model Msg a`.
To then actually apply these handlers to the returned model, we need to call `runCallbacks`, which takes this list, composes everything together and runs it in a left-to-right, sequential manner.
To do this, we append `runCallbacks` to the `inPostsApi` pipeline:

```elm
inPostsApi : Api.ModelUpdate Posts (StateUpdate a) -> StateUpdate a
inPostsApi doUpdate model =
    model.posts
        |> doUpdate
        |> andThen (insertAsPostsIn model)
        |> mapCmd ApiMsg
        |> runCallbacks
```

### A note about pointfree style

Thanks to currying, in Elm we can often omit function arguments in the following way:

```elm
f1 x = g x      <==>  f1 = g
f2 x = g (h x)  <==>  f2 = g << h
```

This is known as *pointfree* style, and it is used in some of the examples included with this library to make the `model` (or `state`) argument implicit.
The conversion described above is formally described by the notion of an [eta-reduction](https://en.wikipedia.org/wiki/Lambda_calculus#%CE%B7-reduction) in the Lambda calculus.

> Pointfree style of programming favors function composition in such a way that one avoids presenting the actual arguments to which a function is applied. It allows the programmer to think about the program more abstractly and can (sometimes) lead to more readable program code.

*Pointfree:*

```elm
setMessage : String -> Model -> Update Model msg a
setMessage message model =
    save { model | message = message }

update : Msg -> Model -> Update Model Msg a
update msg =
    case msg of
        ButtonClicked ->
            setMessage "The button was clicked!"
                >> andThen haveCoffee
```

*Pointful:*

```elm
update msg model =
    case msg of
        ButtonClicked ->
            model
                |> setMessage "The button was clicked!"
                |> andThen haveCoffee
```

The pointfree approach makes sense, in particular in presence of the `ModelUpdate` alias,
which makes it natural to think of the function as being in a partially applied state.
In other words, it takes a `Msg` and returns a function `Model -> Update Model Msg a`.

```elm
type alias ModelUpdate a =
    Model -> Update Model Msg a

update : Msg -> ModelUpdate a
update msg =
    case msg of
        ...
```

That’s it! Enjoy with your favorite choice of taco sauce.

## A complete application example

See [code](https://github.com/laserpants/elm-burrito-update/blob/master/examples/facepalm/) and the [online demo](https://laserpants.github.io/elm-burrito-update/examples/facepalm/dist/).

This is a single-page (SPA) application that shows how to use this library to:
  * Fetch remote resources from a JSON API;
  * Do URL routing;
  * Implement user authentication and sessions using `localStorage` and `sessionStorage` (via ports);
  * Display “toast” notifications; and
  * Work with
    * forms, form validation and
    * WebSockets (see the [`Register`](https://github.com/laserpants/elm-burrito-update/blob/master/examples/facepalm/src/Page/Register.elm) page).

## Recipes

**Work in progress:**
See [github.com/laserpants/elm-burrito-recipes](https://github.com/laserpants/elm-burrito-recipes).

Recipes are reusable pieces of functionality that can be integrated with your Burrito application. They rely on the the same coding style and conventions.

## Etymology

Burritos have appeared in programming tutorials for some time, serving as an analogy for monads.
Whether or not this is a good pedagogical idea, they do seem to [satisfy the monad laws](https://blog.plover.com/prog/burritos.html).
For an in-depth treatment of the subject, see [this excellent paper](http://emorehouse.web.wesleyan.edu/silliness/burrito_monads.pdf) by Ed Morehouse.

## Credits

Icon design by [Smashicons](https://www.flaticon.com/authors/smashicons) from [www.flaticon.com](https://www.flaticon.com)
