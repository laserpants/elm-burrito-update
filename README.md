# Elm Burrito Update

[![Build Status](https://img.shields.io/travis/laserpants/elm-burrito-update/master.svg?style=flat)](https://travis-ci.org/laserpants/elm-burrito-update)
[![Version](https://img.shields.io/badge/elm--version-0.19-blue.svg?colorB=ff69b4)](http://elm-lang.org/)

In a nutshell, this library let's you do the following:

1) Chain updates conveniently using the pipes operator:

```elm
 model
     |> setResource Requested
     |> andAddCmd (model.request url maybeBody)
     |> mapCmd toMsg
```

2) Allow for information to be passed *up* in the update tree:

```elm
 model
     |> setResource (Available resource)
     |> andApply (onSuccess resource) -- pass the message
```

## Getting started

See `examples/hello-world`.

```elm
module Main exposing (main)

import Browser exposing (Document)
import Burrito.Update.Browser exposing (document)
import Burrito.Update.Simple exposing (..)
import Html exposing (..)
import Html.Events exposing (..)


type alias Flags =
    ()


type Msg
    = ButtonClicked


type alias Model =
    { message : String
    , count : Int
    }


setMessage : String -> Model -> Update Model msg
setMessage message model =
    save { model | message = message }


incrementCounter : Model -> Update Model msg
incrementCounter model =
    save { model | count = model.count + 1 }


init : Flags -> Update Model Msg
init () =
    save Model
        |> andMap (save "Nothing much going on here.")
        |> andMap (save 0)


update : Msg -> Model -> Update Model Msg
update msg model =
    case msg of
        ButtonClicked ->
            let
                clickMsg count =
                    "The button has been clicked " ++ String.fromInt count ++ " times."
            in
            model
                |> incrementCounter
                |> andThen (with .count (setMessage << clickMsg))


view : Model -> Document Msg
view { message } =
    { title = ""
    , body =
        [ div []
            [ text message
            ]
        , div []
            [ button [ onClick ButtonClicked ] [ text "Click me" ]
            ]
        ]
    }


main : Program Flags Model Msg
main =
    document
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }
```

## Complete application example

See `examples/facepalm`.

### [Facepalm](https://laserpants.github.io/elm-burrito-update/examples/facepalm/dist/)

This simple single-page blog-like application shows how to use this library to:
  * Fetch remote resources from a RESTful JSON API;
  * Implement URL routing;
  * Authenticate users and manage sessions using localStorage/sessionStorage (via ports);
  * Display “toast” notifications; and
  * Work with
    * forms (wrapping [elm-form](https://package.elm-lang.org/packages/etaque/elm-form/latest)) and
    * WebSockets (see [`Register`](https://github.com/laserpants/elm-burrito-update/blob/master/examples/facepalm/src/Page/Register.elm) page).

## Etymology

Burritos have appeared in some programming tutorials, serving as an analogy for monads.
Whether or not this is a good pedagogical idea, they do seem to [satisfy the monad laws](https://blog.plover.com/prog/burritos.html).
For an in-depth treatment of the subject, see [this excellent paper](http://emorehouse.web.wesleyan.edu/silliness/burrito_monads.pdf) by Ed Morehouse.
