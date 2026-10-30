#!/usr/bin/env bash
# Scaffold today's sketch folder and rebuild the list in the root index.html.
#
#   ./new-sketch.sh <slug> [p5|three|plain] ["one-line note"]
#   ./new-sketch.sh --index        # only rebuild the list
#
# Creates YYYY-MM-DD-<slug>/index.html (from a template) and README.md.
set -euo pipefail
cd "$(dirname "$0")"

usage() { sed -n '2,7s/^# \{0,1\}//p' "$0"; exit 1; }

html_escape() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'; }

# Rewrite everything between the sketches:start/end markers, newest first.
build_index() {
  local list="" dir name date slug note
  while IFS= read -r dir; do
    [ -f "$dir/index.html" ] || continue
    name=${dir%/}
    date=${name:0:10}
    slug=${name:11}
    note=$(head -n 1 "$dir/README.md" 2>/dev/null | sed 's/^#* *//' | html_escape)
    list+="<li><a href=\"$name/index.html\"><span class=\"date\">$date</span><span class=\"slug\">$slug</span><span class=\"note\">$note</span></a></li>"$'\n'
  done < <(ls -d [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*/ 2>/dev/null | sort -r)

  LIST="$list" awk '
    /<!-- sketches:start -->/ { print; printf "%s", ENVIRON["LIST"]; skip = 1; next }
    /<!-- sketches:end -->/   { skip = 0 }
    !skip { print }
  ' index.html > index.html.tmp
  mv index.html.tmp index.html
  echo "index.html: $(printf '%s' "$list" | grep -c '<li>' || true) sketches listed"
}

[ $# -ge 1 ] || usage
if [ "$1" = "--index" ]; then build_index; exit 0; fi

slug=$1
lib=${2:-p5}
note=${3:-TODO: one-line note.}
date=$(date +%F)
dir="$date-$slug"

[[ $slug =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || { echo "slug must be lowercase-kebab-case: $slug" >&2; exit 1; }
[ -e "$dir" ] && { echo "$dir already exists" >&2; exit 1; }
title=${slug//-/ }

case $lib in
  p5)
    head_extra='<script src="https://cdn.jsdelivr.net/npm/p5@1.11.13/lib/p5.min.js"></script>'
    body='<script>
function setup() {
  createCanvas(windowWidth, windowHeight);
}

function draw() {
  background(0);
  noStroke();
  fill(255);
  circle(width / 2, height / 2, 120 + 20 * sin(frameCount * 0.03));
  fill("#ff2a1f");
  circle(mouseX, mouseY, 8);
}

function windowResized() {
  resizeCanvas(windowWidth, windowHeight);
}
</script>' ;;
  three)
    head_extra='<script type="importmap">
  { "imports": { "three": "https://cdn.jsdelivr.net/npm/three@0.186.1/build/three.module.js" } }
</script>'
    body='<script type="module">
import * as THREE from "three";

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
renderer.setSize(innerWidth, innerHeight);
document.body.appendChild(renderer.domElement);

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(50, innerWidth / innerHeight, 0.1, 100);
camera.position.z = 4;

const mesh = new THREE.LineSegments(
  new THREE.EdgesGeometry(new THREE.IcosahedronGeometry(1, 1)),
  new THREE.LineBasicMaterial({ color: 0xffffff })
);
scene.add(mesh);

addEventListener("resize", () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});

renderer.setAnimationLoop((t) => {
  mesh.rotation.set(t * 0.0002, t * 0.0003, 0);
  renderer.render(scene, camera);
});
</script>' ;;
  plain)
    head_extra=''
    body='<canvas></canvas>
<script>
const canvas = document.querySelector("canvas");
const ctx = canvas.getContext("2d");
let W, H;

function resize() {
  const dpr = Math.min(devicePixelRatio || 1, 2);
  W = innerWidth; H = innerHeight;
  canvas.width = W * dpr; canvas.height = H * dpr;
  canvas.style.width = W + "px"; canvas.style.height = H + "px";
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
}
addEventListener("resize", resize);
resize();

function frame(t) {
  ctx.fillStyle = "#000";
  ctx.fillRect(0, 0, W, H);
  ctx.strokeStyle = "#fff";
  ctx.beginPath();
  for (let x = 0; x <= W; x += 4) ctx.lineTo(x, H / 2 + Math.sin(x * 0.02 + t * 0.002) * 40);
  ctx.stroke();
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
</script>' ;;
  *) echo "unknown lib: $lib (use p5, three or plain)" >&2; exit 1 ;;
esac

mkdir "$dir"
cat > "$dir/index.html" <<EOF
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title — $date</title>
<link rel="icon" href="data:,">
$head_extra
<style>
  html, body { margin: 0; height: 100%; background: #000; overflow: hidden; }
  canvas { display: block; }
  .label {
    position: fixed; left: 16px; top: 14px; color: #666;
    font: 11px/1.4 ui-monospace, "SF Mono", Menlo, Consolas, monospace;
    letter-spacing: .08em; text-transform: lowercase; user-select: none;
  }
  .label a { color: inherit; text-decoration: none; }
  .label a:hover { color: #fff; }
</style>
</head>
<body>
<div class="label"><a href="../index.html">←</a> $date / $title</div>
$body
</body>
</html>
EOF
printf '%s\n' "$note" > "$dir/README.md"

build_index
echo "created $dir/ ($lib)"
