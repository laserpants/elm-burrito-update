module App exposing (Flags, Msg(..), State, init, subscriptions, update, view)

import Browser exposing (Document)
import Browser.Navigation as Navigation
import Bulma.Layout exposing (SectionSpacing(..))
import Burrito.Callback exposing (..)
import Burrito.Router as Router
import Burrito.Update exposing (..)
import Data.Session as Session exposing (Session)
import Html exposing (..)
import Json.Decode as Json
import Page.Home as HomePage
import Route exposing (Route(..), fromUrl)
import Ui
import Url exposing (Url)


type PageMsg
    = HomePageMsg HomePage.Msg


type Msg
    = RouterMsg Router.Msg
    | UiMsg Ui.Msg
    | PageMsg PageMsg


type alias Flags =
    { session : String
    , basePath : String
    }


type Page
    = PageNotFound
    | HomePage HomePage.State


type alias State =
    { session : Maybe Session
    , router : Router.State Route
    , ui : Ui.State
    , page : Page
    }


type alias StateUpdate a =
    State -> Update State Msg a


insertAsRouterIn : State -> Router.State Route -> Update State msg a
insertAsRouterIn state router =
    save { state | router = router }


insertAsUiIn : State -> Ui.State -> Update State msg a
insertAsUiIn state ui =
    save { state | ui = ui }


setPage : Page -> StateUpdate a
setPage page state =
    save { state | page = page }


insertAsPageIn : State -> Page -> Update State msg a
insertAsPageIn state page =
    save { state | page = page }


inRouter : Router.StateUpdate Route (StateUpdate a) -> StateUpdate a
inRouter doUpdate state =
    doUpdate state.router
        |> andThen (insertAsRouterIn state)
        |> mapCmd RouterMsg
        |> runCallbacks


inUi : Ui.StateUpdate (StateUpdate a) -> StateUpdate a
inUi doUpdate state =
    doUpdate state.ui
        |> andThen (insertAsUiIn state)
        |> mapCmd UiMsg
        |> runCallbacks


inPage :
    (msg -> PageMsg)
    -> (page -> Page)
    -> Update page msg (StateUpdate a)
    -> StateUpdate a
inPage msg page pageUpdate state =
    pageUpdate
        |> andThen (page >> insertAsPageIn state)
        |> mapCmd (PageMsg << msg)
        |> runCallbacks


redirect : String -> StateUpdate a
redirect =
    inRouter << Router.redirect


init : Flags -> Url -> Navigation.Key -> Update State Msg a
init { basePath, session } url key =
    let
        maybeSession =
            Json.decodeString Session.decoder session
                |> Result.toMaybe
                |> save

        router =
            Router.init fromUrl basePath key

        ui =
            Ui.init
    in
    save State
        |> andMap maybeSession
        |> andMap router
        |> andMap ui
        |> andMap (save PageNotFound)
        |> andThen (notifyUrlChange url)


notifyUrlChange : Url -> StateUpdate a
notifyUrlChange =
    update << RouterMsg << Router.UrlChange


subscriptions : State -> Sub Msg
subscriptions _ =
    Sub.none


handleRouteChange : Url -> Maybe Route -> StateUpdate a
handleRouteChange url maybeRoute =
    case maybeRoute of
        Nothing ->
            setPage PageNotFound

        Just route ->
            case route of
                Login ->
                    save

                Logout ->
                    save

                Register ->
                    save

                About ->
                    save

                NewPost ->
                    save

                Home ->
                    inPage HomePageMsg HomePage HomePage.init

                ShowPost id ->
                    save


update : Msg -> StateUpdate a
update msg =
    case msg of
        RouterMsg routerMsg ->
            inRouter (Router.update routerMsg { onRouteChange = handleRouteChange })

        UiMsg uiMsg ->
            inUi (Ui.update uiMsg)

        PageMsg pageMsg ->
            using
                (\{ page } ->
                    case ( pageMsg, page ) of
                        ( HomePageMsg homePageMsg, HomePage homePageState ) ->
                            inPage HomePageMsg HomePage
                                (HomePage.update homePageMsg homePageState)

                        _ ->
                            save
                )


pageView : Page -> Html PageMsg
pageView page =
    case page of
        HomePage homePageState ->
            Html.map HomePageMsg (HomePage.view homePageState)

        _ ->
            span [] [ text "not found" ]


view : State -> Document Msg
view { page, session, ui } =
    { title = ""
    , body =
        [ Bulma.Layout.section NotSpaced 
              [] 
              [ Html.map UiMsg (Ui.navbar ui session)
              , Html.map PageMsg (pageView page)
              ]
        ]
    }



--import Bulma.Layout exposing (SectionSpacing(..))
--import Bulma.Modifiers exposing (..)
--import Data.Comment exposing (Comment)
--import Data.Post exposing (Post)
--import Helpers exposing (..)
--import Maybe.Extra as Maybe
--import Page exposing (Page, current)
--import Page.Home
--import Page.Login
--import Page.NewPost
--import Page.Register
--import Page.ShowPost
--import Ports
--import Ui exposing (closeBurgerMenu, showInfoToast, showToast)
--type alias Flags =
--    { session : String
--    , basePath : String
--    }
--
--
--type Msg
--    = RouterMsg Router.Msg
--    | PageMsg Page.Msg
--    | UiMsg Ui.Msg
--
--
--type alias State =
--    { session : Maybe Session
--    , router : Router.State Route
--    , ui : Ui.State
--    , restrictedUrl : Maybe String
--    , page : Page
--    }
--
--
--setRestrictedUrl : Url -> State -> Update State Msg a
--setRestrictedUrl url state =
--    save { state | restrictedUrl = Just (String.dropLeft (String.length state.router.basePath) url.path) }
--
--
--resetRestrictedUrl : State -> Update State Msg a
--resetRestrictedUrl state =
--    save { state | restrictedUrl = Nothing }
--
--
--setSession : Maybe Session -> State -> Update State Msg a
--setSession session state =
--    save { state | session = session }
--
--
--inRouter : Wrap State (Router.State Route) Msg Router.Msg t
--inRouter =
--    wrapModel .router (\state router -> { state | router = router }) RouterMsg
--
--
--inUi : Wrap State Ui.State Msg Ui.Msg t
--inUi =
--    wrapModel .ui (\state ui -> { state | ui = ui }) UiMsg
--
--
--inPage : Wrap State Page Msg Page.Msg t
--inPage =
--    wrapModel .page (\state page -> { state | page = page }) PageMsg
--
--
--initsession : flags -> maybe session
--initsession { session } =
--    case json.decodestring session.decoder session of
--        ok result ->
--            just result
--
--        _ ->
--            nothing
--
--
--init : flags -> url -> navigation.key -> update state msg a
--init flags url key =
--    let
--        session =
--            initsession flags
--
--        router =
--            router.init fromurl flags.basepath key routermsg
--    in
--    save state
--        |> andmap (save session)
--        |> andmap router
--        |> andmap ui.init
--        |> andmap (save nothing)
--        |> andmap (save page.notfoundpage)
--        |> andthen (notifyurlchange url)
--
--
--notifyurlchange : url -> state -> update state msg a
--notifyurlchange =
--    update << routermsg << router.urlchange
--
--
--redirect : string -> state -> update state msg a
--redirect =
--    inrouter << router.redirect
--
--
--loadpage : update page page.msg (state -> update state msg a) -> state -> update state msg a
--loadpage setpage state =
--    let
--        isloginroute =
--            just login == state.router.route
--    in
--    state
--        |> inpage (always setpage)
--        |> andthen
--            (if not isloginroute then
--                resetrestrictedurl
--
--             else
--                save
--            )
--        |> andthen (inui closeburgermenu)
--
--
--handleroutechange : url -> maybe route -> state -> update state msg a
--handleroutechange url mayberoute =
--    let
--        ifauthenticated gotopage =
--            with .session
--                (\session ->
--                    if nothing == session then
--                        -- redirect and return to this url after successful login
--                        setrestrictedurl url
--                            >> andthen (redirect "/login")
--                            >> andthen (inui (showtoast { message = "you must be logged in to access that page.", color = warning }))
--
--                    else
--                        gotopage
--                )
--
--        unlessauthenticated gotopage =
--            with .session
--                (\session ->
--                    if maybe.isjust session then
--                        redirect "/"
--
--                    else
--                        gotopage
--                )
--    in
--    case mayberoute of
--        -- no route
--        nothing ->
--            loadpage (save page.notfoundpage)
--
--        -- authenticated only
--        just newpost ->
--            ifauthenticated
--                (page.newpost.init
--                    |> burrito.update.map page.newpostpage
--                    |> mapcmd page.newpostpagemsg
--                    |> loadpage
--                )
--
--        -- redirect if already authenticated
--        just login ->
--            unlessauthenticated
--                (page.login.init
--                    |> burrito.update.map page.loginpage
--                    |> mapcmd page.loginpagemsg
--                    |> loadpage
--                )
--
--        just register ->
--            unlessauthenticated
--                (page.register.init
--                    |> burrito.update.map page.registerpage
--                    |> mapcmd page.registerpagemsg
--                    |> loadpage
--                )
--
--        -- other
--        just (showpost id) ->
--            (page.showpost.init id
--                |> burrito.update.map page.showpostpage
--                |> mapcmd page.showpostpagemsg
--                |> loadpage
--            )
--                >> andthen (update (pagemsg (page.showpostpagemsg page.showpost.fetchpost)))
--
--        just home ->
--            (page.home.init
--                |> burrito.update.map page.homepage
--                |> mapcmd page.homepagemsg
--                |> loadpage
--            )
--                >> andthen (update (pagemsg (page.homepagemsg page.home.fetchposts)))
--
--        just logout ->
--            setsession nothing
--                >> andthen (updatesessionstorage nothing)
--                >> andthen (redirect "/")
--                >> andthen (inui (showinfotoast "you have been logged out"))
--
--        just about ->
--            loadpage (save page.aboutpage)
--
--
--updatesessionstorage : maybe session -> state -> update state msg a
--updatesessionstorage maybesession =
--    case maybesession of
--        nothing ->
--            addcmd (ports.clearsession ())
--
--        just session ->
--            addcmd (ports.setsession session)
--
--
--returntorestrictedurl : state -> update state msg a
--returntorestrictedurl =
--    with .restrictedurl (redirect << maybe.withdefault "/")
--
--
--handleauthresponse : maybe session -> state -> update state msg a
--handleauthresponse maybesession =
--    let
--        authenticated =
--            maybe.isjust maybesession
--    in
--    setsession maybesession
--        >> andthen (updatesessionstorage maybesession)
--        >> andthen
--            (if authenticated then
--                returntorestrictedurl
--
--             else
--                save
--            )
--
--
--handlepostadded : post -> state -> update state msg a
--handlepostadded post =
--    redirect "/" >> andthen (inui (showinfotoast "your post was published"))
--
--
--handlecommentcreated : comment -> state -> update state msg a
--handlecommentcreated comment =
--    inui (showinfotoast "your comment was successfully received")
--
--
--update : msg -> state -> update state msg a
--update msg state =
--    case msg of
--        routermsg routermsg ->
--            inrouter (router.update { onroutechange = handleroutechange } routermsg) state
--
--        pagemsg pagemsg ->
--            inpage
--                (page.update
--                    { onauthresponse = handleauthresponse
--                    , onpostadded = handlepostadded
--                    , oncommentcreated = handlecommentcreated
--                    }
--                    pagemsg
--                )
--                state
--
--        uimsg uimsg ->
--            inui (ui.update uimsg) state
--
--
--subscriptions : state -> sub msg
--subscriptions { page } =
--    page.subscriptions page pagemsg
--
--
--view : state -> document msg
--view ({ page, session, ui } as state) =
--    { title = "welcome to facepalm"
--    , body =
--        [ ui.navbar session (current page) ui uimsg
--        , ui.toastmessage ui uimsg
--        , bulma.layout.section notspaced [] [ page.view page pagemsg ]
--        ]
--    }
