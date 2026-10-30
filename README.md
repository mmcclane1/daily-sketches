# daily sketches

Daily generative / audiovisual sketches by Matthew McClane ([@mmcclane1](https://github.com/mmcclane1)).
Minimal: black, white, one red accent (`#ff2a1f`).

## Format

```
YYYY-MM-DD-short-slug/
  index.html   # the whole sketch: self-contained, runs as a live page
  README.md    # one line: what it is / how to interact
index.html     # root list of every sketch (rebuilt by new-sketch.sh)
new-sketch.sh  # scaffolds today's folder
```

- **One folder per sketch**, named with the date it was made plus a short kebab-case slug.
  Several sketches can share a date.
- **`index.html` is self-contained.** No build step, no local dependencies. Libraries come from
  jsDelivr with pinned versions so old sketches keep working:
  - p5.js `1.11.13`: `<script src="https://cdn.jsdelivr.net/npm/p5@1.11.13/lib/p5.min.js">`
  - three.js `0.186.1`: via an import map to `three@0.186.1/build/three.module.js`
  - or plain canvas / WebGL / Web Audio.
- **`README.md` is a single line.** The root index uses it as the sketch's description.
- Each sketch links back to `../index.html` from a small label in the top-left corner.

## New sketch

```sh
./new-sketch.sh <slug> [p5|three|plain] ["one-line note"]
# e.g.
./new-sketch.sh tide-lines p5 "Stacked sine tides that drift with the cursor."
```

This creates `$(date +%F)-<slug>/` with a starter `index.html` for the chosen library and the
`README.md` note, then rebuilds the list in the root `index.html` (newest first). If you edit a
note or delete a folder by hand, run `./new-sketch.sh --index` to rebuild the list.

## Run locally

Any static server works:

```sh
python3 -m http.server 8000   # then open http://localhost:8000
```

Sketches that use the microphone need a secure context (`localhost` or HTTPS, which includes
GitHub Pages) and a click before audio starts.

## Hosting

Plain static files, served by GitHub Pages from `main` / root. `.nojekyll` makes Pages
serve everything as-is. See `PUSH.md` for the daily publish routine.

## Sketches

See the root [`index.html`](index.html) (or the Pages site) for the full, newest-first list.
