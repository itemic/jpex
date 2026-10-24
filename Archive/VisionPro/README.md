# Apple Vision Pro

Native visionOS 27 support, taken out of the app on 23 October 2026 to come back to later.

- `VisionPro.patch` has every change it made to the app's own files: the project's visionOS build settings and its Spatial group, the `#if os(visionOS)` adaptations, and the Globe and Float map buttons. Apply it from the repository's root with `git apply Archive/VisionPro/VisionPro.patch`.
- `Spatial/` goes back in `jpex/Spatial/`: the World as a globe in a volume, and a list's map floating flat in the room.
- `AppIcon.solidimagestack/` goes back in `jpex/Resources/Assets.xcassets/`: the layered icon visionOS needs.
- `make_vision_icon.py` goes back in `Scripts/`: it makes that icon from the original.

Never use a `Window` scene for the globe: on Apple Vision Pro, asking for it again while it's still opening crashes. It's a `WindowGroup` presenting the World instead.
