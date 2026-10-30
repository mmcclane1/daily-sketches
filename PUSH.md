# Publishing: one-time setup + the daily push

This repo has no remote yet. Nothing has been pushed.

## 1. One-time: create the GitHub repo and push `main`

With the GitHub CLI (`gh auth login` first):

```sh
gh repo create mmcclane1/daily-sketches --public --source . --remote origin --push
```

Or by hand: create an empty public repo named `daily-sketches` on github.com (no README or
license, so histories don't conflict), then:

```sh
git remote add origin git@github.com:mmcclane1/daily-sketches.git
git push -u origin main
```

## 2. One-time: enable GitHub Pages from `main` / root

Repo → **Settings → Pages → Build and deployment**:

- **Source:** Deploy from a branch
- **Branch:** `main`, folder **`/ (root)`** → Save

Or from the CLI:

```sh
gh api -X POST repos/mmcclane1/daily-sketches/pages \
  -f "source[branch]=main" -f "source[path]=/"
```

After a minute or so the site is live at **https://mmcclane1.github.io/daily-sketches/**. The
root `index.html` is the list page, and each sketch is at `/YYYY-MM-DD-slug/`. Pages serves
over HTTPS, which `getUserMedia` needs, so the mic sketch works there. `.nojekyll` makes
Pages skip Jekyll and serve the files as they are. Every push to `main` redeploys
automatically, with no Actions workflow needed.

## 3. The daily routine

```sh
cd daily-sketches
./new-sketch.sh <slug> [p5|three|plain] "One-line note."   # makes $(date +%F)-<slug>/ and relists index.html
# ...write the sketch in $(date +%F)-<slug>/index.html...
python3 -m http.server 8000                                # check it at http://localhost:8000
git add -A
git commit -m "Sketch $(date +%F): <slug>"
git push
```

Commits are dated by git at the moment you commit. Don't set `GIT_AUTHOR_DATE` or
`GIT_COMMITTER_DATE` and don't backdate folders: the folder date, the commit date and the
real day should match.

### Optional: a one-command push

To make the last step a single command, a small `publish.sh` could commit and push only when
today's folder exists and its note isn't still the scaffold placeholder:

```sh
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
today=$(date +%F)
dirs=( "$today"-*/ )
[ -d "${dirs[0]}" ] || { echo "no sketch folder for $today"; exit 1; }
if grep -l '^TODO' "$today"-*/README.md >/dev/null 2>&1; then
  echo "a $today README still has the TODO note"; exit 1
fi
./new-sketch.sh --index
git add -A
git commit -m "Sketch $today: $(printf '%s ' "${dirs[@]%/}" | sed "s/$today-//g; s/ $//")"
git push
```

### Scheduling it?

A cron or launchd job can run `publish.sh` every evening. For example, `crontab -e`:

```
30 23 * * * cd ~/daily-sketches && ./publish.sh >> ~/daily-sketches-publish.log 2>&1
```

Keep in mind that a scheduler can only publish work that already exists. `new-sketch.sh` makes a
placeholder, not a sketch, so the guard above refuses to push a day that hasn't been made.
Also, cron's environment needs push credentials: an SSH key with no passphrase prompt (or an
agent), or `gh auth setup-git` for HTTPS.
