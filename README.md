# Elm Burrito Update

[![Build Status](https://img.shields.io/travis/laserpants/elm-burrito-update/master.svg?style=flat)](https://travis-ci.org/laserpants/elm-burrito-update)
[![Version](https://img.shields.io/badge/elm--version-0.19-blue.svg?colorB=ff69b4)](http://elm-lang.org/)

<p><img src="logo.png" /></p>

> This project brings forward some conventions and idioms that help you write modular and scalable Elm applications; and a convenient programming interface to support those ideas.

## Installation

To use this library in your project you need to install it (just like any other Elm package) using the command:

```
elm install laserpants/elm-burrito-update
```

## Appetizer

To get a flavor of what this library is all about, the following code snippets are from the [Facepalm example](#complete-application-example).

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
                    { onSuccess = handleApiResponse << Just
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

As a starting point, there are four concepts to wrap one’s head around.

1. [The Update type](#the-update-type)
2. [Monadic sequencing](#monadic-sequencing)
3. [Managing nested state](#managing-nested-state)
4. [Callbacks](#callbacks)

> Note that in the following, *state* is sometimes used to refer to (what the Elm architecture calls) a *model*, and that these two terms are used more or less interchangeably.

### The Update type

A typical (vanilla) Elm program has the following structure:

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

The `Update` type is as a type alias wrapper for the usual `( model, cmd )` tuple. As the extra `a` type parameter suggests, however, there is a bit more going on. More about this shortly.

Let’s look at all the changes in the code:

1. Only `Document` is imported from the `Browser` module.
2. Import `document` from `Burrito.Update.Browser` instead.
3. Import (for now) `Update` from `Burrito.Update`.
4. In `init`, Instead of the usual tuple, we return `Update Model Msg a`.
5. `Update Model Msg a` is also returned from `update`.
6. The `main` function looks like in the original program, but note that `document` here refers to `Burrito.Update.Browser.document`.

The functions `application` and `document`, exposed by the `Burrito.Update.Browser` module, serve as drop-in replacements for their counterparts in `Browser`, but instead create a `Program` where `init` and `update` are compatible with the `Update` type.

### Monadic sequencing

The next convention we will adopt is to chain updates using the reverse function application (also known as *pipe*) operator.
If you are using the `update-extra` package, you’ll already be familiar with the idea.
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

The Burrito equivalent of this code looks like this:

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

Some observations: We use `save` to create an `Update` without any commands. For instance,

```elm
update msg model =
    save model
```

&hellip; corresponds to:

```elm
update msg model =
    ( model, Cmd.none )
```

> The `Update` type is actually a 3-tuple, where the third component is used to store a list of *callbacks*. This feature is explained later.

Functions of the form `something -> Model -> Update Model Msg a` are a recurring pattern in this style of code.
They are known as *monadic* functions (subject to some laws), and to compose these we use the pipe operator `|>` together with `andThen`:

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

For brevity, and for reasons which will become apparent later on, the following type alias is also useful in some cases.

```elm
type alias ModelUpdate a =
    Model -> Update Model Msg a

update : Msg -> ModelUpdate a
update = ...
```

### Update API

Many of the functions have semantics similar to corresponding functions in other Elm libraries written in this style: `andThen`, `map`, `map2`, `map3`, &hellip;, `map7`, `andMap`, etc.

#### map

`map` applies a function to the state (model) portion of an `Update`.

```elm
> (save 2) == map ((+) 1) (save 1)
True
```

#### andThen

Binds together update functions to achieve sequential (monadic) composition.
For example, if we have two functions `doSomething : Model -> Update Model Msg a` and `doStuffTimes : Int -> Model -> Update Model Msg a`, we can compose these, like so:

```elm
save model
    |> andThen doSomething
    |> andThen (doStuffTimes 3)
```

#### Applicative interface

The functions `map2`, `map3`, etc. address the need to map over functions of more than one argument.

```elm
> (save 42) == map2 (+) (save 5) (save 37)
True
```

For more detailed info, see the [documentation](https://package.elm-lang.org/packages/laserpants/elm-burrito-update/latest/Burrito-Update).

### Managing nested state

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
            model.posts
                |> Api.update apiMsg
                |> andThen (\posts -> save { model | posts = posts })
                |> mapCmd ApiMsg
```

```elm
insertAsPostsIn : Model -> Api.Model Posts -> Update Model Msg a
insertAsPostsIn model posts =
    save { model | posts = posts }


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

### Callbacks

```
        ┌──────────┐
        │  update  │
        └──┬── ▲ ──┘
           │   │
 TimerMsg  │   │─── onTimeOut
           │   │
      ┌─── ▼ ──┴─────┐
      │ Timer.update │
      └──────────────┘
```

## Complete application example

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

## Etymology

Burritos have appeared in programming tutorials for some time, serving as an analogy for monads.
Whether or not this is a good pedagogical idea, they do seem to [satisfy the monad laws](https://blog.plover.com/prog/burritos.html).
For an in-depth treatment of the subject, see [this excellent paper](http://emorehouse.web.wesleyan.edu/silliness/burrito_monads.pdf) by Ed Morehouse.

## Credits

<div>Icon design by <a href="https://www.flaticon.com/authors/smashicons" title="Smashicons">Smashicons</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a></div>
