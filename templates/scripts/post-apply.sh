#!/bin/sh

<% if ne (index .Params `loggingType`) "kibana" %># <% end %>source elasticsearch-logging.sh
