# Keep autosaves out of the user's data directory for the whole test run.
withr::local_options(
  CDALabeller.autosave_dir = withr::local_tempdir(.local_envir = testthat::teardown_env()),
  .local_envir = testthat::teardown_env()
)
