Bubble Regatta - Web build

Upload all files from this folder to a static HTTP(S) host, preserving filenames.
Open index.html through the server, not through a file:// URL.
Single-threaded WebGL 2 build; no COOP/COEP configuration is required.
Keep the .gzip files: modern browsers download and decode those smaller payloads.
Original .wasm/.pck files remain as a fallback for browsers without DecompressionStream.

Local preview: python3 -m http.server 8789 --directory build/web --bind 127.0.0.1
Then open http://127.0.0.1:8789/

Controls: arrows/WASD to drive; Shift + steering to drift and release to boost;
Space or the item icon to use gifts; Esc pauses; R restarts; M mutes audio.
The pause menu has resume, restart, captain selection and exit-to-cover icons.
Wait for preparation to finish, then click the cover to enter and allow audio. Desktop keyboard play is supported.
Personal bests use browser storage. Private browsing may not retain them.

Built with Godot 4.7.2. Nunito font is licensed under SIL OFL (FONT-LICENSE.txt).
