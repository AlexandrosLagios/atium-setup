# Third-party notices

Skills in `skills/` that started as someone else's work, with the licence they
carry. Skills installed rather than authored here are declared in
`third-party-skills.tsv` and keep their own licence in `~/.agents/skills/`.

A skill in the first group is a fork. Every entry below says why the copy exists
and what a maintainer must re-check when the upstream version moves.

## konvoulgaris/soong

`skills/write-notion-content` and `skills/write-technical-content` are adapted
from the `write-notion-content` and `write-technical-content` skills in
[konvoulgaris/soong](https://github.com/konvoulgaris/soong) by Konstantinos
Voulgaris. `skills/write-technical-content/reference/approved-words.md` is taken
unchanged.

```
MIT License

Copyright (c) 2026 Konstantinos Voulgaris

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Graphify-Labs/graphify

`skills/graphify` is vendored from the `/graphify` skill in
[Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify) by Safi
Shamsi, dual licensed Apache-2.0 and MIT. This repository takes the MIT terms.
`skills/graphify/.graphify_version` records the upstream version.

Upstream installs the skill through its own CLI (`uv tool install graphifyy`,
then `graphify install`), which writes into generated deployment state. That is
why `third-party-skills.tsv` cannot carry it: `scripts/install-third-party`
passes a repository and a skill name to `npx skills add`, and this skill is not
published that way.

Re-check two local narrowings when the upstream version moves: the description
must stay gated on an existing graph, and the body must stay under 500 lines.

```
MIT License

Copyright (c) 2026 Safi Shamsi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
