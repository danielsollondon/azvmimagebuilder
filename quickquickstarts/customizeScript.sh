#!/bin/bash -e

# Add preview banner to MOTD
cat >> /etc/motd << EOF
*******************************************************
**            This VM was built by Kainos            **
**          !! Any issues please contact !!          **
**                Mark.Jack@Kainos.com               **
*******************************************************
EOF