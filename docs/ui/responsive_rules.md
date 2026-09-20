# LTR/RTL Responsive Rules - LaundryPro UAE
> **Version:** 1.0.0

## Layout Rules
1. Use `start` and `end` instead of `left` and `right`.
2. Use `Directionality` widget for text direction.
3. Use `TextDirection.ltr` for English, `TextDirection.rtl` for Arabic.
4. All padding/margin use start/end, not left/right.
5. Icons that indicate direction (arrows, chevrons) must flip in RTL.

## Typography Rules
1. LTR font: Inter (Latin glyphs).
2. RTL font: Noto Sans Arabic (Arabic glyphs).
3. Numbers always displayed LTR even in RTL context.
4. Dates follow locale format (DD/MM/YYYY for both EN and AR).

## Component Rules
1. Tables: Column order does NOT reverse in RTL.
2. Forms: Labels align to start (right in RTL).
3. Navigation: Sidebar on start side (right in RTL).
4. Buttons: Icon position flips in RTL.
5. Dialogs: Close button on end side (left in RTL).