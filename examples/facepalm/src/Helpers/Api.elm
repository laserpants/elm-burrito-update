module Helpers.Api exposing (errorToString, requestErrorMessage)

import Bulma.Components exposing (..)
import Bulma.Modifiers exposing (..)
import Html exposing (Html, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http


errorToString : Http.Error -> String
errorToString error =
    case error of
        Http.BadStatus 401 ->
            "Authentication failed."

        Http.BadStatus 500 ->
            "Application error (500 Internal Server Error)"

        Http.BadStatus 501 ->
            "This feature is not implemented"

        _ ->
            "Something went wrong!"


requestErrorMessage : Http.Error -> Html msg
requestErrorMessage error =
    message { messageModifiers | color = Danger }
        []
        [ messageBody [] [ text (errorToString error) ] ]
