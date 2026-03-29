# Google Play Publishing Checklist

## Done
- [x] App name: **Fridgenda**
- [x] Adaptive icon + all mipmap densities generated (`assets/icon/fridgenda.png`)

## Pending
- [ ] Release signing keystore — generate keystore, configure `app/build.gradle.kts` (currently using debug keys)
- [ ] Application ID — consider renaming `com.personal.meal_planner` before first publish (cannot change after)
- [ ] Verify target SDK ≥ 34 in `app/build.gradle.kts`
- [ ] Privacy policy — publish a page (GitHub Pages is fine) and add URL to Play Console
- [ ] Build release AAB — `flutter build appbundle --release`
- [ ] Play Console store listing — 512×512 icon, screenshots, short/full description, category
- [ ] Data safety form — fill in Play Console (app stores data locally only, no sharing)
- [ ] Content rating questionnaire — fill in Play Console

!!! Important, fix git history to change committer to your public email, also configure to commit future items with the appropriate email address