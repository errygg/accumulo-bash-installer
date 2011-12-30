#!/bin/bash

# test script for the installer

describe "install_accumulo"

it_should_display_usage() {
  usage=$(./install-accumulo.sh -h)
  test "$usage" = "Mike"
}

