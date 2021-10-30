#!/usr/bin/env python3

"""
Export a file or directory from a CI job to be imported by a later CI job.

This script is intended to be used on the sender-side and cooperate with
import.py on the receiver-side. The sender job needs the artifacts path
configured:

  my_job:
    artifacts:
      paths:
        - artifacts/*

This abstracts what would otherwise be an awkward and error prone process of
configuring precise artifact paths in YAML.
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
  log = logging.getLogger("export.py")
  log.addHandler(ch)

  # parse command line arguments
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--dry-run", action="store_true", help="Log actions that "
                      "would be done but do not perform actual export.")
  parser.add_argument("--force", action="store_true", help="Skip checks that "
                      "this is running in a CI environment. This flag is "
                      "useful when you want to test things locally.")
  parser.add_argument("--job-name", help="Set the CI job name used as the "
                      "origin of this file. If not given, this will default to "
                      "the value of the $CI_JOB_NAME environment variable.")
  parser.add_argument("--verbose", action="store_true", help="Log more "
                      "detailed information about actions.")
  parser.add_argument("path", help="File or directory to export.")
  options = parser.parse_args(args[1:])

  if options.verbose:
    log.setLevel(logging.INFO)

  if not options.force and "CI" not in os.environ:
    log.error("CI environment variable unset; refusing to run")
    return -1

  if options.job_name is None:
    log.info("setting job name to %s", os.environ["CI_JOB_NAME"])
    job = os.environ["CI_JOB_NAME"]
  else:
    job = options.job_name

  # namespace the path we will copy to by our job name
  destination = ARTIFACTS / job
  if not options.dry_run:
    destination.mkdir(parents=True, exist_ok=True)

  # export the given file/directory
  if options.dry_run:
    log.info("if --dry-run were not set, would copy %s to %s", options.path,
             destination)
  else:
    log.info("copying %s to %s", options.path, destination)
    shutil.copy(options.path, destination)

  return 0

if __name__ == "__main__":
  sys.exit(main(sys.argv))
