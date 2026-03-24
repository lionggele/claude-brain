# Security Review (additive to base checklist)

- [ ] CORS configured restrictively (not wildcard *)
- [ ] Rate limiting on auth endpoints (login, password reset)
- [ ] File uploads validated (type, size, content) and stored outside webroot
- [ ] Session tokens have proper expiry and rotation
