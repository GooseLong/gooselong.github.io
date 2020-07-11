module Story exposing (..)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
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



-- VIEW


getParagraphFromId : StoryletID -> Story -> String
getParagraphFromId id story =
    case story of
        Loading ->
            "Loading"

        Error error ->
            errorToString error

        Loaded storylets ->
            let
                mbStorylet =
                    List.filter (\strlt -> strlt.id == id) storylets |> List.head
            in
            case mbStorylet of
                Nothing ->
                    "error - storylet not found"

                Just storylet ->
                    storylet.paragraph


viewStorylet : StoryletID -> Orientation -> String -> Story -> Element Msg
viewStorylet id orientation dialogue story =
    case story of
        Loading ->
            text "Loading"

        Error error ->
            text <| errorToString error

        Loaded storylets ->
            let
                mbStorylet =
                    List.filter (\strlt -> strlt.id == id) storylets |> List.head

                fontSize =
                    case orientation of
                        Landscape ->
                            18

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
                    (case orientation of
                        Portrait ->
                            column []

                        Landscape ->
                            row [ height fill ]
                    )
                        [ el
                            (case orientation of
                                Portrait ->
                                    [ width fill
                                    , height fill
                                    , padding 50
                                    ]

                                Landscape ->
                                    [ width fill
                                    , height shrink
                                    , padding 50
                                    , centerY
                                    ]
                            )
                          <|
                            image
                                [ width fill, height fill, centerX, centerY ]
                            <|
                                case storylet.character of
                                    Chippy ->
                                        { src = "assets/chippy.png"
                                        , description = "Chiptune"
                                        }
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
                                , Background.color <| rgb 0.2 0.3 0.99
                                , Font.size fontSize
                                ]
                                [ text dialogue ]
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

        Http.BadBody _ ->
            "Bad body?"