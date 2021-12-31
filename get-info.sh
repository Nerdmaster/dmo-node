#!/bin/bash
/bin/dynamo-cli -conf=client.conf -getinfo
tail -20 ~/.dynamo/debug.log
