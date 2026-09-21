# Flora Live banner (Flutter)

The PlantSnap "Video identification" home banner, built in Flutter. The right-hand tile is a
looping live-camera prototype: it pans the room, zooms out onto a plant, runs autofocus, fires a
capture burst, and Flora returns the name. It is drawn on screen, there is no video file.

## Run the demo

    flutter pub get
    flutter run

## Use it in the app

Copy two files across and add one dependency:

1. `lib/flora_live_banner.dart` into your widgets folder.
2. `assets/flora_expert.png` into your assets folder.
3. In `pubspec.yaml`:

       dependencies:
         flutter_svg: ^2.0.10
       flutter:
         assets:
           - assets/flora_expert.png

Then drop it in:

    FloraLiveBanner(onStart: () => openFloraLive())

Optional parameters: `avatarAsset`, `title`, `ctaLabel`, `speciesName`, `fontFamily`.

## Notes

- One image asset (the Flora avatar) and one dependency (flutter_svg). Montserrat is used if the app has it.
- The banner is 361 x 186; the video tile is 108 x 134 with Flora overhanging the corner.
- Kit tokens: Flora `#7321D7`, green `#1F8505`, live `#FF2D55`, ink `#0C3B2E`.
- The loop is one 8 second `AnimationController`. All motion is deterministic.

Built by ViReal.
