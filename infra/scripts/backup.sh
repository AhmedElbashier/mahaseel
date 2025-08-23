#!/bin/bash
DATE=$(date +%F)
pg_dump -U postgres -h localhost mahaseel > backups/mahaseel_$DATE.sql
