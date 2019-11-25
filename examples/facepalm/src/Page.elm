module Page exposing (..)

import Html exposing (..)
import Page.Home as HomePage
import Page.Login as LoginPage
import Page.NewPost as NewPostPage
import Page.Register as RegisterPage
import Page.ShowPost as ShowPostPage
import Ui.Page


type Msg
    = HomePageMsg HomePage.Msg
    | NewPostPageMsg NewPostPage.Msg
    | ShowPostPageMsg ShowPostPage.Msg
    | LoginPageMsg LoginPage.Msg
    | RegisterPageMsg RegisterPage.Msg


type Page
    = PageNotFound
    | HomePage HomePage.State
    | NewPostPage NewPostPage.State
    | ShowPostPage ShowPostPage.State
    | LoginPage LoginPage.State
    | RegisterPage RegisterPage.State
    | AboutPage


subscriptions : Page -> Sub Msg
subscriptions page =
    case page of
        PageNotFound ->
            Sub.none

        HomePage homePageState ->
            Sub.map HomePageMsg (HomePage.subscriptions homePageState)

        NewPostPage newPostPageState ->
            Sub.map NewPostPageMsg (NewPostPage.subscriptions newPostPageState)

        ShowPostPage showPostPageState ->
            Sub.map ShowPostPageMsg (ShowPostPage.subscriptions showPostPageState)

        LoginPage loginPageState ->
            Sub.map LoginPageMsg (LoginPage.subscriptions loginPageState)

        RegisterPage registerPageState ->
            Sub.map RegisterPageMsg (RegisterPage.subscriptions registerPageState)

        AboutPage ->
            Sub.none


view : Page -> Html Msg
view page =
    case page of
        PageNotFound ->
            Ui.Page.container "Error 404" [ text "That means we couldn’t find this page." ]

        HomePage homePageState ->
            Html.map HomePageMsg (HomePage.view homePageState)

        NewPostPage newPostPageState ->
            Html.map NewPostPageMsg (NewPostPage.view newPostPageState)

        ShowPostPage showPostPageState ->
            Html.map ShowPostPageMsg (ShowPostPage.view showPostPageState)

        LoginPage loginPageState ->
            Html.map LoginPageMsg (LoginPage.view loginPageState)

        RegisterPage registerPageState ->
            Html.map RegisterPageMsg (RegisterPage.view registerPageState)

        AboutPage ->
            Ui.Page.container "About" [ text "Welcome to Facepalm. A place to meet weird people while keeping all your personal data safe." ]
