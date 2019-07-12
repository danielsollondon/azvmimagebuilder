#!/bin/bash
echo "Starting at $(date)" > outputFile.txt
echo "The Target OS is: $Target_OS" >> outputFile.txt
echo "These env vars came from: $Target_Msg_String" >> outputFile.txt

# unset env vars, as not referencing them later
unset Target_OS2
unset Target_Msg_String