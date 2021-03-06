module Story exposing (..)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Keyed as Keyed
import Html.Attributes
import Http
import Json.Decode exposing (Decoder, field, int, list, string)



-- MODEL


type Story
    = Loading
    | Loaded (List Storylet)
    | Error Http.Error


type alias Storylet =
    { id : StoryletID
    , character : Character
    , paragraph : String
    , options : List ( String, StoryletID )
    }


type StoryletID
    = StoryletID Int


type Character
    = Chippy
    | Athol
    | Clawdious
    | Rowan
    | End



-- UPDATE


type Msg
    = LoadedStory (List Storylet)
    | ErrorLoadingStory Http.Error
    | OptionClicked StoryletID


characterFromString : String -> Decoder Character
characterFromString string =
    case string of
        "chippy" ->
            Json.Decode.succeed Chippy

        "athol" ->
            Json.Decode.succeed Athol

        "clawdious" ->
            Json.Decode.succeed Clawdious

        "rowan" ->
            Json.Decode.succeed Rowan

        "end" ->
            Json.Decode.succeed End

        _ ->
            Json.Decode.fail ("Invalid character: " ++ string)


characterDecoder : Decoder Character
characterDecoder =
    string |> Json.Decode.andThen characterFromString


optionsDecoder : Decoder (List ( String, StoryletID ))
optionsDecoder =
    Json.Decode.keyValuePairs (Json.Decode.map StoryletID int)


storyletDecoder : Decoder Storylet
storyletDecoder =
    Json.Decode.map4 Storylet
        (field "id" <| Json.Decode.map StoryletID int)
        (field "character" characterDecoder)
        (field "paragraph" string)
        (field "options" optionsDecoder)


storyDecoder : Decoder (List Storylet)
storyDecoder =
    field "story" <| list storyletDecoder


gotStory : Result Http.Error (List Storylet) -> Msg
gotStory result =
    case result of
        Ok storylets ->
            LoadedStory storylets

        Err error ->
            ErrorLoadingStory error


newCharacter : StoryletID -> StoryletID -> Story -> Maybe String
newCharacter oldId newId story =
    case story of
        Loading ->
            Nothing

        Error _ ->
            Nothing

        Loaded storylets ->
            let
                mbStorylets =
                    Maybe.map2 Tuple.pair
                        (List.filter (\strlt -> strlt.id == oldId) storylets |> List.head)
                        (List.filter (\strlt -> strlt.id == newId) storylets |> List.head)
            in
            case mbStorylets of
                Just ( oldStorylet, newStorylet ) ->
                    if oldStorylet.character /= newStorylet.character then
                        Just <| characterToString newStorylet.character

                    else
                        Nothing

                Nothing ->
                    Nothing


characterToString : Character -> String
characterToString character =
    case character of
        Chippy ->
            "chippy"

        Athol ->
            "athol"

        Clawdious ->
            "clawdious"

        Rowan ->
            "rowan"

        End ->
            "rowan"


getStoryletFromId : StoryletID -> List Storylet -> Maybe Storylet
getStoryletFromId id storylets =
    List.filter (\strlt -> strlt.id == id) storylets |> List.head



-- VIEW


viewStorylet : StoryletID -> Orientation -> Story -> Element Msg
viewStorylet id orientation story =
    case story of
        Loading ->
            el [ centerX, centerY ] <| text "Loading"

        Error error ->
            text <| errorToString error

        Loaded storylets ->
            let
                mbStorylet =
                    List.filter (\strlt -> strlt.id == id) storylets |> List.head

                fontSize =
                    case orientation of
                        Landscape ->
                            32

                        Portrait ->
                            62

                buttonSpacing =
                    case orientation of
                        Landscape ->
                            10

                        Portrait ->
                            15
            in
            case mbStorylet of
                Nothing ->
                    text "error - storylet not found"

                Just storylet ->
                    case storylet.character of
                        End ->
                            el
                                [ centerX
                                , centerY
                                , Font.family
                                    [ Font.typeface "Lucida Console"
                                    , Font.monospace
                                    ]
                                , Font.size 80
                                ]
                            <|
                                text "THE END"

                        _ ->
                            (case orientation of
                                Portrait ->
                                    column [ width fill ]

                                Landscape ->
                                    row [ width fill, height fill ]
                            )
                                [ el
                                    (case orientation of
                                        Portrait ->
                                            [ width fill
                                            , height fill
                                            , paddingEach { top = 0, right = 40, bottom = 0, left = 10 }
                                            ]

                                        Landscape ->
                                            [ width fill
                                            , height shrink
                                            , paddingEach { top = 0, right = 40, bottom = 0, left = 10 }
                                            , centerY
                                            ]
                                    )
                                  <|
                                    case storylet.character of
                                        Chippy ->
                                            Keyed.el [ width fill, height fill, centerX, centerY ]
                                                ( characterToString storylet.character
                                                , image [ width fill, height fill, centerX, centerY ]
                                                    { src = "assets/chippy_min.png"
                                                    , description = "Chiptune"
                                                    }
                                                )

                                        Athol ->
                                            Keyed.el [ width fill, height fill, centerX, centerY ]
                                                ( characterToString storylet.character
                                                , image [ width fill, height fill, centerX, centerY ]
                                                    { src = "assets/athol_min.jfif"
                                                    , description = "Athol"
                                                    }
                                                )

                                        Clawdious ->
                                            Keyed.el [ width fill, height fill, centerX, centerY ]
                                                ( characterToString storylet.character
                                                , image [ width fill, height fill, centerX, centerY ]
                                                    { src = "assets/clawdious_min.jfif"
                                                    , description = "Clawdious"
                                                    }
                                                )

                                        Rowan ->
                                            Keyed.el [ width fill, height fill, centerX, centerY ]
                                                ( characterToString storylet.character
                                                , image [ width fill, height fill, centerX, centerY ]
                                                    { src = "assets/rowan_min.png"
                                                    , description = "Rowan"
                                                    }
                                                )

                                        End ->
                                            Keyed.el [ width fill, height fill, centerX, centerY ]
                                                ( characterToString storylet.character
                                                , image [ width fill, height fill, centerX, centerY ]
                                                    { src = "assets/error.png"
                                                    , description = "End_error"
                                                    }
                                                )
                                , column
                                    [ width fill
                                    , height shrink
                                    , case orientation of
                                        Portrait ->
                                            alignBottom

                                        Landscape ->
                                            centerY
                                    ]
                                    [ paragraph
                                        [ padding 20
                                        , Background.color <| rgb 0.5 0.6 0.8
                                        , Font.size fontSize
                                        , Element.htmlAttribute (Html.Attributes.style "white-space" "normal")
                                        ]
                                        [ text storylet.paragraph ]
                                    , column [ width fill, spacing buttonSpacing, padding buttonSpacing ] <|
                                        List.map
                                            (\optn ->
                                                Input.button
                                                    [ width fill
                                                    , padding 3
                                                    , Background.color <| rgb 0.8 0.8 0.8
                                                    , Border.rounded 3
                                                    ]
                                                    { onPress = Just (OptionClicked <| Tuple.second optn)
                                                    , label =
                                                        paragraph
                                                            [ padding 5
                                                            , Font.size fontSize
                                                            ]
                                                            [ Tuple.first optn
                                                                |> text
                                                            ]
                                                    }
                                            )
                                            storylet.options
                                    ]
                                ]


errorToString : Http.Error -> String
errorToString err =
    case err of
        Http.Timeout ->
            "Timeout exceeded"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus _ ->
            "Bad Status"

        Http.BadUrl url ->
            "Malformed url: " ++ url

        Http.BadBody body ->
            "Bad body?" ++ body
