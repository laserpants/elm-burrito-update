module App exposing (Flags, Msg(..), State, init, subscriptions, update, view)

import Browser exposing (Document)
import Browser.Navigation as Navigation
import Bulma.Layout exposing (SectionSpacing(..))
import Bulma.Modifiers exposing (..)
import Burrito.Callback exposing (..)
import Burrito.Update exposing (..)
import Burrito.Update.Router as Router
import Data.Comment exposing (Comment)
import Data.Post exposing (Post)
import Data.Session as Session exposing (Session)
import Helpers exposing (..)
import Json.Decode as Json
import Maybe.Extra as Maybe
import Page exposing (Page, current)
import Page.Home
import Page.Login
import Page.NewPost
import Page.Register
import Page.ShowPost
import Ports
import Route exposing (Route(..), fromUrl)
import Ui exposing (closeBurgerMenu, showInfoToast, showToast)
import Url exposing (Url)


type alias Flags =
    { session : String
    , basePath : String
    }


type Msg
    = RouterMsg Router.Msg
    | PageMsg Page.Msg
    | UiMsg Ui.Msg


type alias State =
    { session : Maybe Session
    , router : Router.State Route
    , ui : Ui.State
    , restrictedUrl : Maybe String
    , page : Page
    }


setRestrictedUrl : Url -> State -> Update State Msg a
setRestrictedUrl url state =
    save { state | restrictedUrl = Just (String.dropLeft (String.length state.router.basePath) url.path) }


resetRestrictedUrl : State -> Update State Msg a
resetRestrictedUrl state =
    save { state | restrictedUrl = Nothing }


setSession : Maybe Session -> State -> Update State Msg a
setSession session state =
    save { state | session = session }


inRouter : Wrap State (Router.State Route) Msg Router.Msg t
inRouter =
    wrapModel .router (\state router -> { state | router = router }) RouterMsg


inUi : Wrap State Ui.State Msg Ui.Msg t
inUi =
    wrapModel .ui (\state ui -> { state | ui = ui }) UiMsg


inPage : Wrap State Page Msg Page.Msg t
inPage =
    wrapModel .page (\state page -> { state | page = page }) PageMsg


initSession : Flags -> Maybe Session
initSession { session } =
    case Json.decodeString Session.decoder session of
        Ok result ->
            Just result

        _ ->
            Nothing


init : Flags -> Url -> Navigation.Key -> Update State Msg a
init flags url key =
    let
        session =
            initSession flags

        router =
            Router.init fromUrl flags.basePath key RouterMsg
    in
    save State
        |> andMap (save session)
        |> andMap router
        |> andMap Ui.init
        |> andMap (save Nothing)
        |> andMap (save Page.NotFoundPage)
        |> andThen (notifyUrlChange url)


notifyUrlChange : Url -> State -> Update State Msg a
notifyUrlChange =
    update << RouterMsg << Router.UrlChange


redirect : String -> State -> Update State Msg a
redirect =
    inRouter << Router.redirect


loadPage : Update Page Page.Msg (State -> Update State Msg a) -> State -> Update State Msg a
loadPage setPage state =
    let
        isLoginRoute =
            Just Login == state.router.route
    in
    state
        |> inPage (always setPage)
        |> andThen
            (if not isLoginRoute then
                resetRestrictedUrl

             else
                save
            )
        |> andThen (inUi closeBurgerMenu)


handleRouteChange : Url -> Maybe Route -> State -> Update State Msg a
handleRouteChange url maybeRoute =
    let
        ifAuthenticated gotoPage =
            with .session
                (\session ->
                    if Nothing == session then
                        -- Redirect and return to this url after successful login
                        setRestrictedUrl url
                            >> andThen (redirect "/login")
                            >> andThen (inUi (showToast { message = "You must be logged in to access that page.", color = Warning }))

                    else
                        gotoPage
                )

        unlessAuthenticated gotoPage =
            with .session
                (\session ->
                    if Maybe.isJust session then
                        redirect "/"

                    else
                        gotoPage
                )
    in
    case maybeRoute of
        -- No route
        Nothing ->
            loadPage (save Page.NotFoundPage)

        -- Authenticated only
        Just NewPost ->
            ifAuthenticated
                (Page.NewPost.init
                    |> Burrito.Update.map Page.NewPostPage
                    |> mapCmd Page.NewPostPageMsg
                    |> loadPage
                )

        -- Redirect if already authenticated
        Just Login ->
            unlessAuthenticated
                (Page.Login.init
                    |> Burrito.Update.map Page.LoginPage
                    |> mapCmd Page.LoginPageMsg
                    |> loadPage
                )

        Just Register ->
            unlessAuthenticated
                (Page.Register.init
                    |> Burrito.Update.map Page.RegisterPage
                    |> mapCmd Page.RegisterPageMsg
                    |> loadPage
                )

        -- Other
        Just (ShowPost id) ->
            (Page.ShowPost.init id
                |> Burrito.Update.map Page.ShowPostPage
                |> mapCmd Page.ShowPostPageMsg
                |> loadPage
            )
                >> andThen (update (PageMsg (Page.ShowPostPageMsg Page.ShowPost.FetchPost)))

        Just Home ->
            (Page.Home.init
                |> Burrito.Update.map Page.HomePage
                |> mapCmd Page.HomePageMsg
                |> loadPage
            )
                >> andThen (update (PageMsg (Page.HomePageMsg Page.Home.FetchPosts)))

        Just Logout ->
            setSession Nothing
                >> andThen (updateSessionStorage Nothing)
                >> andThen (redirect "/")
                >> andThen (inUi (showInfoToast "You have been logged out"))

        Just About ->
            loadPage (save Page.AboutPage)


updateSessionStorage : Maybe Session -> State -> Update State Msg a
updateSessionStorage maybeSession =
    case maybeSession of
        Nothing ->
            addCmd (Ports.clearSession ())

        Just session ->
            addCmd (Ports.setSession session)


returnToRestrictedUrl : State -> Update State Msg a
returnToRestrictedUrl =
    with .restrictedUrl (redirect << Maybe.withDefault "/")


handleAuthResponse : Maybe Session -> State -> Update State Msg a
handleAuthResponse maybeSession =
    let
        authenticated =
            Maybe.isJust maybeSession
    in
    setSession maybeSession
        >> andThen (updateSessionStorage maybeSession)
        >> andThen
            (if authenticated then
                returnToRestrictedUrl

             else
                save
            )


handlePostAdded : Post -> State -> Update State Msg a
handlePostAdded post =
    redirect "/" >> andThen (inUi (showInfoToast "Your post was published"))


handleCommentCreated : Comment -> State -> Update State Msg a
handleCommentCreated comment =
    inUi (showInfoToast "Your comment was successfully received")


update : Msg -> State -> Update State Msg a
update msg state =
    case msg of
        RouterMsg routerMsg ->
            inRouter (Router.update { onRouteChange = handleRouteChange } routerMsg) state

        PageMsg pageMsg ->
            inPage
                (Page.update
                    { onAuthResponse = handleAuthResponse
                    , onPostAdded = handlePostAdded
                    , onCommentCreated = handleCommentCreated
                    }
                    pageMsg
                )
                state

        UiMsg uiMsg ->
            inUi (Ui.update uiMsg) state


subscriptions : State -> Sub Msg
subscriptions { page } =
    Page.subscriptions page PageMsg


view : State -> Document Msg
view ({ page, session, ui } as state) =
    { title = "Welcome to Facepalm"
    , body =
        [ Ui.navbar session (current page) ui UiMsg
        , Ui.toastMessage ui UiMsg
        , Bulma.Layout.section NotSpaced [] [ Page.view page PageMsg ]
        ]
    }
