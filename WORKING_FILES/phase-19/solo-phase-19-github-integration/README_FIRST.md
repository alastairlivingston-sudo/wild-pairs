# Solo Phase 19 — GitHub integration bundle

This is the single hand-back bundle for the approved **Wave A UX work plus the table-background amendment**.

It contains one consolidated patch, one paste-ready Claude Code prompt, the approved offline HTML state lab, the gameplay concept video, proof captures, source anchors, constraints, validation evidence, and the exact verification matrix.

## Use it

From the root of the live Solo repository, place this directory at:

```text
WORKING_FILES/phase-19/solo-phase-19-github-integration/
```

A typical local extraction command is:

```bash
mkdir -p WORKING_FILES/phase-19
unzip solo-phase-19-github-integration.zip -d WORKING_FILES/phase-19
```

Then open `CLAUDE_CODE_INTEGRATION_PROMPT.md` and paste its complete contents into Claude Code while Claude Code is operating in the live repository.

## Important

- Use only `PATCH/solo-phase-19-wave-a-backgrounds.patch` from this bundle.
- Do **not** also apply the earlier Wave A patch or the earlier incremental backgrounds patch.
- The live repository is authoritative. Claude Code must reopen every target file and semantic-merge if the branch has moved.
- The patch baseline is the supplied snapshot commit `5e3d18412502bfef5cc6922759e98f55579b407e`; do not reset a live branch to that commit merely to make the patch apply.
- The gameplay video and HTML are review references, not production art sources. Their neutral card placeholders must not replace or redesign the existing Solo card artwork.
- This bundle implements P19-01, P19-02, P19-05, and the approved background amendment. It does not implement later Phase 19 workstreams such as causal card travel parity, stable open Face-to-face shelves, Team Pass privacy, rematch, or final settlement parity.

ChatGPT performed patch, parse, SwiftPM, and artifact-integrity checks only. It did not run Xcode, an iOS SDK type-check, a simulator, VoiceOver, or `WildPairsUITests`.
