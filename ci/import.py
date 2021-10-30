#!/usr/bin/env python3

"""
Import a file or directory that has been exported from a prior CI job.

This script is intended to be used on the receiver-side and cooperate with
export.py on the sender-side. See export.py for further explanation.
"""

import argparse
import logging
import os
from pathlib import Path
import shutil
import sys
from typing import List

# inbox/outbox for artifacts
ARTIFACTS = (Path(__file__).parent / "../artifacts").resolve()

def main(args: List[str]) -> int:
  """Entry point"""

  # setup logging to print to stderr
  ch = logging.StreamHandler()
  log = logging.getLogger("import.py")
  log.addHandler(ch)

  # parse command line arguments
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--dry-run", action="store_true", help="Log actions that "
                      "would be done but do not perform actual import.")
  parser.add_argument("--force", action="store_true", help="Skip checks that "
                      "this is running in a CI environment. This flag is "
                      "useful when you want to test things locally.")
  parser.add_argument("--from-job-name", required=True, help="Set the name of "
                      "the CI job that exported the file or directory now "
                      "being imported.")
  parser.add_argument("--verbose", action="store_true", help="Log more "
                      "detailed information about actions.")
  parser.add_argument("path", help="File or directory name to import.")
  options = parser.parse_args(args[1:])

  if options.verbose:
    log.setLevel(logging.INFO)

  if not options.force and "CI" not in os.environ:
    log.error("CI environment variable unset; refusing to run")
    return -1

  # locate the file or directory being imported
  source = ARTIFACTS / options.from_job_name / options.path
  if not source.exists():
    log.error("source %s not found", source)
    return -1

  destination = options.path

  # import the given file/directory
  if options.dry_run:
    log.info("if --dry-run were not set, would move %s to %s", source,
             destination)
  else:
    log.info("moving %s to %s", source, destination)
    shutil.move(source, destination)

  return 0

if __name__ == "__main__":
  sys.exit(main(sys.argv))
