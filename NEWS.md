# CDALabeller (development version)

## Breaking changes

* The CSV file now always has the same columns, in this order: `img`, `x1`,
  `y1`, `x2`, `y2`, `treatment`, `score`, `annotator`, `created_at`, `img_md5`
  and `labeller_version`. The columns that AutoCDAScorer needs (`img`, `x1`,
  `x2`, `y1` and `y2`) have not changed.
* `score` is now a number. It is `NA` unless it is between 0 and 6.
* `run_app()` no longer has a `launch.browser` argument. It never had any
  effect.
* CDALabeller now needs R 4.0.0 or later.

## Bug fixes

* Boxes were saved one screen pixel up and to the left of where they were
  drawn. The cause was a 1-pixel border around the drawing area. For a 5568
  pixel wide image shown 1200 pixels wide, the error was about 4.6 image
  pixels. Files saved by earlier versions contain this error.
* Sometimes the drawing area did not appear after an image loaded. Nothing
  could then be drawn until the window was resized. This no longer happens.
* A click without a drag no longer saves a box with no width or height.
* With no boxes drawn, Download now saves a CSV file with column names only.
  Before, the download failed with a "not found" error.

## New features

* A score key below the image shows example cell death areas for each score
  from 0 to 6. It is resized to match the image.
* An Annotator field. The annotator is saved with every box. So are the time
  the box was drawn, the image's MD5 checksum and the CDALabeller version.
* Uploads are rejected if two files have the same name.
* A score outside 0 to 6 is outlined in red.

## Other changes

* The 200 MB upload limit now applies only while the app is running. Before,
  loading the package changed this limit for the whole R session.
