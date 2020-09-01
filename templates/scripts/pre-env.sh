#!/bin/sh
set -e

<% if eq (index .Params `sendgridApiKey`) "" %># <% end %>source sendgrid.sh
