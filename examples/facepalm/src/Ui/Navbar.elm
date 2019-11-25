module Ui.Navbar exposing (navbar)

import Bulma.Components exposing (..)
import Bulma.Elements exposing (..)
import Bulma.Modifiers exposing (..)
import Data.Session exposing (Session)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Maybe.Extra as Maybe
import Page exposing (Page(..))
import Ui exposing (Msg(..), State)


navbar : State -> Page -> Maybe Session -> Html Msg
navbar { menuIsOpen } page maybeSession =
    let
        currentPage =
            let
                defaults =
                    { isHomePage = False, isAboutPage = False, isNewPostPage = False }
            in
            case page of
                HomePage _ ->
                    { defaults | isHomePage = True }

                AboutPage ->
                    { defaults | isAboutPage = True }

                NewPostPage _ ->
                    { defaults | isNewPostPage = True }

                _ ->
                    defaults

        authenticated =
            Maybe.isJust maybeSession

        burger =
            navbarBurger menuIsOpen
                [ class "has-text-white", onClick ToggleMenu ]
                [ span [] [], span [] [], span [] [] ]

        buttons =
            if not authenticated then
                [ p [ class "control" ]
                    [ a [ class "button is-primary", href "/register" ] [ text "Register" ] ]
                , p [ class "control" ]
                    [ a [ class "button is-light", href "/login" ] [ text "Log in" ] ]
                ]

            else
                [ p [ class "control" ]
                    [ a [ class "button is-primary", href "/logout" ] [ text "Log out" ] ]
                ]
    in
    fixedNavbar Top
        { navbarModifiers | color = Info }
        []
        [ navbarBrand []
            burger
            [ navbarItem False
                []
                [ h5 [ class "title is-5" ]
                    [ a
                        [ class "has-text-white", href "/" ]
                        [ text "Facepalm" ]
                    ]
                ]
            ]
        , navbarMenu menuIsOpen
            []
            [ navbarStart [ class "is-unselectable" ]
                [ navbarItemLink currentPage.isHomePage
                    [ href "/" ]
                    [ text "Home" ]
                , navbarItemLink currentPage.isAboutPage
                    [ href "/about" ]
                    [ text "About" ]
                , navbarItemLink currentPage.isNewPostPage
                    [ href "/posts/new" ]
                    [ text "New post" ]
                ]
            , navbarEnd []
                [ navbarItem False [] [ div [ class "field is-grouped" ] buttons ] ]
            ]
        ]
