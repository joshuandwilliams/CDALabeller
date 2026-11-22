# CDALabeller 0.1.0

## Breaking changes

* The exported CSV has a fixed set of columns: `img`, `x1`, `y1`, `x2`, `y2`,
  `treatment`, `score`, `annotator`, `created_at`, `img_md5` and
  `labeller_version`. `score` is numeric, and is `NA` unless it is a number
  from 0 to 6. The columns AutoCDAScorer requires (`img`, `x1`, `x2`, `y1`,
  `y2`) are unchanged.
* `run_app()` no longer has a `launch.browser` argument. It was never used.
* Requires R 4.0.0 or later.

## Bug fixes

* Boxes were recorded one display pixel up and left of where they were drawn,
  because the drawing canvas had a 1 px border. For a 5568 px wide image
  shown 1200 px wide, that is about 4.6 image pixels. Annotations exported
  by earlier versions carry this offset.
* A click without a drag no longer records a 0 x 0 box.
* With no boxes, Download writes a CSV with the header row instead of an
  empty file.

## New features

* Lesion score key (0 to 6) below the image, scaled to the image width.
* Annotations are autosaved after every change; see `run_app(autosave_dir =)`.
* Annotator field, and per-box provenance columns (see above).
* Uploads with duplicate file names are rejected.
* Scores outside 0 to 6 are flagged in the app.
