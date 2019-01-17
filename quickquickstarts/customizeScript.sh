#!/bin/bash -e

# Add preview banner to MOTD
cat >> /etc/motd << EOF
*******************************************************
**            This VM was built from the:            **
**      !! AZURE VM IMAGE BUILDER Custom Image !!    **
**         You have just been Customized :-)         **
*******************************************************
EOF