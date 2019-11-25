module Ui.Page exposing (container, layout)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


layout : List (Html msg) -> Html msg
layout html =
    div
        [ class "columns is-centered"
        , style "margin" "1.5em"
        ]
        [ div [ class "column is-two-thirds" ] html ]


container : String -> List (Html msg) -> Html msg
container title html =
    layout
        [ h3 [ class "title is-3" ] [ text title ]
        , div [] html
        ]
