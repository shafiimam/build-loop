# build-loop — project guidance

## Browser policy

For ALL web browsing and browser tasks — launching a browser, opening URLs,
navigating, screenshots, DevTools/inspection, and QA — use gstack's `browse`
skill (and `qa` / `qa-only` for test flows). Never use the default Chrome
integration or `mcp__claude-in-chrome__*` / `chrome-devtools` tools.

## Working in this repo

build-loop is a router skill. The only real logic is `scripts/detect-state.sh`;
everything else is markdown that orchestrates installed tools (gstack, GSD,
superpowers, gbrain). Keep changes thin — route to existing skills, do not
reimplement engines. Run `bash tests/detect-state.test.sh` after touching the
detector.
