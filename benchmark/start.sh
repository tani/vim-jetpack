#!/bin/bash
for i in {1..10}; do
  for name in dein jetpack plug paq packer minpac; do
    sh $name/start.sh
  done
done
