# Verification — 2026-09-24

- Blender 5.2.2 background build saved `Source/Ember.blend` and exported the GLB successfully: 1,318 mesh vertices, 56 armature bones, 5 materials.
- Godot 4.7.2 imported the skinned GLB successfully.
- `Tools/validate.gd`: **VALIDATION_OK**. All 56 bone names resolve through the assignment BoneMap (unmapped profile bones retain their standard names). Maximum rest-rotation discrepancy is 0.000691 radians. All 12 clips have over 40 valid skeletal tracks. Animated clips change bone transforms between samples. Pause, resume and replay checks pass.
- Web release export completes with no errors. Threads are disabled for GitHub Pages compatibility. PCK contains the 12-clip demo subset, not the complete source library.
- Actual Chromium browser at localhost loads and renders the character. Selecting Sprint produces the running pose; selecting Fall ends in the lying pose. No warning/error console entries in these checks.
- Verification is a coursework demo check, not exhaustive compatibility testing. Desktop pointer controls are the primary target.

## Public deployment

- GitHub Pages [build 36021592233](https://github.com/Avocadough/ember-motion-atelier/actions/runs/36021592233): completed, success.
- Public URL: https://avocadough.github.io/ember-motion-atelier/
- Public URL loads and visibly renders Ember in the browser, with no warning/error console entries. Sprint selection and Pause were also exercised on the public build.
- Local Web UI checks additionally exercised 0.5× speed selection, timeline scrubbing while paused, and camera orbit. The changed pose and side view were visually verified.
- Local and public `index.pck` SHA-256: `44D9EE2915B3BA0B48C358C38136F71F79417F96B60AD7583C859C22E0053C53`.
- Screenshots: `ember-idle.png`, `ember-sprint.png`, `ember-public.png`.
