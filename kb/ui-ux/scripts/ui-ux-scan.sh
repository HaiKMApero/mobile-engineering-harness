#!/usr/bin/env bash
# Heuristic static scan for UI/UX behaviour risks in a Jetpack Compose codebase.
# Output: TSV  rule <TAB> file:line <TAB> hint   (one suspect per line, NOT a verdict)
# Every rule id maps to kb/ui-ux/archetypes/*.md. Confirm each suspect by reading the code
# and, for runtime axes, by kb/ui-ux/runbooks/runtime-verification.md.
#
# Usage: ui-ux-scan.sh <src-dir> [--include-previews]
set -u  # no -e/pipefail: grep "no match" (exit 1) is a normal outcome here

SRC="${1:?usage: ui-ux-scan.sh <src-dir> [--include-previews]}"
INCLUDE_PREVIEWS="${2:-}"
[ -d "$SRC" ] || { echo "not a directory: $SRC" >&2; exit 2; }

# Kotlin files, excluding build output and (by default) preview-only files.
list_kt() {
  find "$SRC" -type f -name '*.kt' -not -path '*/build/*' -not -path '*/.*/*' -not -path '*/test/*' -not -path '*/androidTest/*' |
    if [ "$INCLUDE_PREVIEWS" = "--include-previews" ]; then cat; else grep -v -E 'Preview[s]?\.kt$|/preview/'; fi
}
FILES="$(list_kt)"
[ -n "$FILES" ] || { echo "no Kotlin files under $SRC" >&2; exit 0; }

emit() { printf '%s\t%s\t%s\n' "$1" "$2" "$3"; }
has() { grep -q -E -- "$1" "$2"; }
hasi() { grep -q -i -E -- "$1" "$2"; }

# Feature root of a file: the directory right below a "feature(s)" segment, else its own directory.
feature_dir() {
  local d; d="$(dirname "$1")"
  case "$d" in
    */features/*) echo "${d%%/features/*}/features/$(echo "${d#*/features/}" | cut -d/ -f1)" ;;
    */feature/*)  echo "${d%%/feature/*}/feature/$(echo "${d#*/feature/}" | cut -d/ -f1)" ;;
    *) echo "$d" ;;
  esac
}

# True when some non-carousel file of the feature uses a pager state (content pager).
feature_has_content_pager() {
  grep -rlE 'PagerState|HorizontalPager\(' "$1" --include='*.kt' 2>/dev/null |
    grep -viE 'banner|hero|carousel|recommend|ranking|slide|onboard' | grep -q .
}

while IFS= read -r f; do
  base="$(basename "$f")"

  # UX-LST-001: lazy items without a stable key (looks 4 lines ahead for multi-line calls).
  if has 'Lazy(Column|Row|VerticalGrid|HorizontalGrid|VerticalStaggeredGrid)' "$f"; then
    awk -v F="$f" '
      { line[NR]=$0 }
      END {
        for (i=1;i<=NR;i++) {
          if (line[i] ~ /(^|[^A-Za-z_.])items(Indexed)?\(/ && line[i] !~ /items *= /) {
            ctx=line[i] line[i+1] line[i+2] line[i+3] line[i+4]
            if (ctx !~ /key *=/) printf "UX-LST-001\t%s:%d\tlazy items() without key = { id }\n", F, i
          }
        }
      }' "$f"
  fi

  # UX-LST-010: forEach rendering inside a vertically scrolling Column.
  # Only collections that look data-driven; small fixed sets (tags, tracks) are fine.
  if has 'verticalScroll\(' "$f" && has '\.forEach *\{' "$f"; then
    grep -n -i -E '(items|list|dramas|episodes|results|posters|series|movies|videos|feed)[A-Za-z]*\.forEach *\{' "$f" | head -3 | while IFS=: read -r n _; do
      emit UX-LST-010 "$f:$n" "forEach inside verticalScroll Column: use LazyColumn for unbounded lists"; done
  fi

  # UX-CAR-001/003: carousel-like pager without a virtual looping page count.
  if has 'HorizontalPager\(' "$f" && { echo "$base" | grep -qiE 'banner|hero|carousel|recommend|slide' || hasi 'banner|hero|carousel'  "$f"; } && ! echo "$base" | grep -qiE 'ranking|podium|top3|onboard'; then
    if ! has 'Int\.MAX_VALUE|[0-9]_?000_?000|[0-9]{2,3}_000|[Ll]oop' "$f"; then
      n="$(grep -n -m1 'HorizontalPager(' "$f" | cut -d: -f1)"
      emit UX-CAR-001 "$f:$n" "carousel pager is finite: no virtual page count / page % size (endless swipe + indicator)"
    fi
  fi

  # UX-TAB-001: tab/chip selector in a feature where no pager drives content
  # (carousel/banner pagers do not count: they are not bound to the selector).
  if echo "$base" | grep -qiE 'tabrow|tabstrip|tabs\.kt|chip|filter|segment' || has 'TabRow\(' "$f"; then
    if has 'selected' "$f" && ! feature_has_content_pager "$(feature_dir "$f")"; then
      n="$(grep -n -m1 -E 'TabRow\(|LazyRow\(|Row\(' "$f" | cut -d: -f1)"
      emit UX-TAB-001 "$f:${n:-1}" "selector ($base) with no content pager in its feature: if it switches content, use TabRow + HorizontalPager sharing one PagerState"
    fi
  fi

  # UX-SRCH-001: imePadding applied to a whole screen container.
  grep -n -E 'imePadding\(\)' "$f" | while IFS=: read -r n _; do
    ctx="$(sed -n "$((n>3?n-3:1)),${n}p" "$f")"
    if echo "$ctx" | grep -qE 'Scaffold\(|fillMaxSize\(\)'; then
      emit UX-SRCH-001 "$f:$n" "imePadding on a full-screen container: everything (ads, bottom bar) moves with the keyboard"
    fi
  done

  # UX-VID-001: cover/thumbnail visibility tied to playing/prepared instead of first rendered frame.
  if hasi 'player' "$f" && hasi 'thumbnail|cover|poster' "$f"; then
    grep -n -i -E '(thumbnail|cover|poster).*(isPlaying|isPrepared|STATE_READY|isReady|onPrepared)|(isPlaying|isPrepared|STATE_READY|isReady|onPrepared).*(thumbnail|cover|poster)' "$f" |
      while IFS=: read -r n _; do emit UX-VID-001 "$f:$n" "cover hidden on playing/prepared state: hide only after first frame rendered for this media id"; done
    # UX-VID-002: first-frame flag not keyed by media.
    # skipped when the flag is combined with a media/episode id at its use site
    grep -q -i -E '(firstFrame|rendered)[A-Za-z]* *&&[^&]*(Id|id) *==|(Id|id) *==.*(firstFrame|rendered)|takeIf *\{ *(firstFrame|rendered)' "$f" ||
    grep -n -i -E 'firstFrame|rendered' "$f" | grep -E 'remember\((player|engine)?\)|remember *\{ *mutableStateOf\((false|true)\)' |
      while IFS=: read -r n _; do emit UX-VID-002 "$f:$n" "first-frame flag keyed by player, not by media id: reset on every source change"; done
  fi
  # UX-VID-003: video surface created per pager/list item.
  if has 'AndroidView' "$f" && has 'SurfaceView|TextureView|PlayerView' "$f" && has 'HorizontalPager\(|VerticalPager\(|items\(' "$f"; then
    n="$(grep -n -m1 'AndroidView' "$f" | cut -d: -f1)"
    emit UX-VID-003 "$f:$n" "video surface inside pager/list item: surface recreated per page causes black flashes"
  fi

  # UX-LF-002: lifecycle-unaware collection in UI.
  grep -n -E '\.collectAsState\(' "$f" | while IFS=: read -r n _; do
    emit UX-LF-002 "$f:$n" "collectAsState(): prefer collectAsStateWithLifecycle()"; done

  # UX-CAR-005 / UX-TMR-007: endless loops in composables not gated by lifecycle/drag.
  if has '@Composable' "$f" && has 'while *\( *true *\)' "$f" && has 'delay\(' "$f" && ! has 'Lifecycle|RESUMED|isDragged|collectIsDraggedAsState' "$f"; then
    n="$(grep -n -m1 -E 'while *\( *true *\)' "$f" | cut -d: -f1)"
    emit UX-TMR-007 "$f:$n" "while(true)+delay in UI not gated by lifecycle/drag: keeps running in background, drifts"
  fi

  # UX-OVL-009: popup auto-shown on every entry.
  grep -n -E 'LaunchedEffect\((Unit|true)\)' "$f" | while IFS=: read -r n _; do
    if sed -n "${n},$((n+4))p" "$f" | grep -qiE '(show|visible|open)[A-Za-z]*(dialog|popup|sheet)?[A-Za-z]* *= *true'; then
      emit UX-OVL-009 "$f:$n" "overlay shown from LaunchedEffect(Unit): persist a 'shown' flag or it reappears on every return"
    fi
  done

  # UX-CTA-009 / UX-NAV-003: business work or raw navigation directly in onClick.
  grep -n -E 'onClick *= *\{[^}]*scope\.launch' "$f" | while IFS=: read -r n _; do
    emit UX-CTA-009 "$f:$n" "coroutine launched in onClick: move to ViewModel intent with in-progress guard"; done
  grep -n -E 'onClick *= *\{[^}]*\.navigate\(' "$f" | while IFS=: read -r n _; do
    emit UX-NAV-003 "$f:$n" "navigate() straight from onClick: guard double tap (lifecycle RESUMED / debounce)"; done

  # UX-NAV-001: bottom navigation without state save/restore.
  if has 'NavigationBarItem|BottomNavigationItem|NavigationBar\(' "$f" && has '\.navigate\(' "$f" && ! has 'restoreState' "$f"; then
    n="$(grep -n -m1 -E '\.navigate\(' "$f" | cut -d: -f1)"
    emit UX-NAV-001 "$f:$n" "bottom-nav navigate without saveState/restoreState: tabs lose scroll/state"
  fi

  # UX-IMG-001: network image whose modifier sets no size/ratio (skips pass-through modifier params).
  grep -n -E '(Async|SubcomposeAsync)Image\(' "$f" | while IFS=: read -r n _; do
    ctx="$(sed -n "${n},$((n+14))p" "$f")"  # long arg lists put modifier after imageLoader/contentScale
    if echo "$ctx" | grep -q 'modifier' && ! echo "$ctx" | grep -qE 'size\(|aspectRatio|height\(|width\(|fillMax|matchParentSize|modifier *= *modifier'; then
      emit UX-IMG-001 "$f:$n" "AsyncImage without fixed size/aspectRatio: layout shifts when the image arrives"
    fi
  done
done <<< "$FILES"

# Feature-level: text input + banner ad in the same feature (UX-SRCH-002 / UX-AD-003).
echo "$FILES" | while IFS= read -r f; do feature_dir "$f"; done | sort -u | while IFS= read -r fd; do
  if grep -rqE 'TextField\(|BasicTextField\(' "$fd" --include='*.kt' 2>/dev/null &&
     grep -rqiE 'BannerAd|AdView|bannerAd|NativeAd|AdSlot|Banner(Ad)?Container' "$fd" --include='*.kt' 2>/dev/null; then
    loc="$(grep -rnE -m1 'imePadding\(\)' "$fd" --include='*.kt' 2>/dev/null | head -1 | cut -d: -f1,2)"
    [ -n "$loc" ] || loc="$(grep -rniE -m1 'BannerAd|AdView|bannerAd|NativeAd|AdSlot' "$fd" --include='*.kt' 2>/dev/null | head -1 | cut -d: -f1,2)"
    emit UX-AD-003 "${loc:-$fd}" "text input and ad slot in the same feature: verify on device that the keyboard does not move the ad"
  fi
done
