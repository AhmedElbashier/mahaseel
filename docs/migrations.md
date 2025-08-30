# Migration Notes

## API v1 Prefix

- All API routes are now served under `/api/v1`.
- Update client base URLs to include the new prefix, e.g. `https://staging.mahaseel.com/api/v1`.
- System endpoints like `/healthz` remain at the root.
