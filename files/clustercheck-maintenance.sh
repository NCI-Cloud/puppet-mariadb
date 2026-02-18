#!/bin/bash

# Return 503 when in maintenance

/bin/echo -e "HTTP/1.1 503 Service Unavailable\r\n"
/bin/echo -e "Content-Type: text/plain\r\n"
/bin/echo -e "Content-Length: 18\r\n"
/bin/echo -e "\r\n"
/bin/echo -e "Node is *down*.\r\n"
/bin/echo -e "\r\n"

sleep 1
