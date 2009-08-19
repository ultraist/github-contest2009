#!/bin/sh
rm download/data.txt
rm download/test.txt
ln -s train_data.txt download/data.txt
ln -s train_test.txt download/test.txt


