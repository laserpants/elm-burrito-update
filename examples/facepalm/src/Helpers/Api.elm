module Helpers.Api exposing (httpErrorToString, resourceErrorMessage)

import Bulma.Components exposing (..)
import Bulma.Modifiers exposing (..)
import Burrito.Api as Api
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadStatus 401 ->
            "Authentication failed."

        Http.BadStatus 500 ->
            "Application error (500 Internal Server Error)"

        Http.BadStatus 501 ->
            "This feature is not implemented"

        _ ->
            "Something went wrong!"


resourceErrorMessage : Api.Resource a -> Html msg
resourceErrorMessage resource =
    case resource of
        Api.Error error ->
            message { messageModifiers | color = Danger }
                []
                [ messageBody [] [ text (error |> httpErrorToString) ] ]

        _ ->
            text ""
